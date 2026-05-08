/*
 * powkiddy_daemon.c
 * Unified daemon for Powkiddy X39 Pro:
 *   - ADB hotplug (USB PC+Charger detection)
 *   - Earphone detection (via /sys/kernel/debug/gpio)
 *   - Power button long press shutdown (5s)
 *
 * Build:
 *   arm-buildroot-linux-uclibcgnueabi-gcc -O2 -o powkiddy_daemon powkiddy_daemon.c
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>
#include <time.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <sys/select.h>
#include <sys/reboot.h>
#include <linux/input.h>

/* ─── Configuration ─────────────────────────────────────────────────────── */

#define POLL_INTERVAL_MS        500

/* USB monitor sysfs paths */
#define USB_PC_CONNECTED        "/sys/monitor/usb_port/status/pc_connected"
#define USB_CHARGER_CONNECTED   "/sys/monitor/usb_port/status/charger_connected"
#define USB_PORT_TYPE           "/sys/monitor/usb_port/config/port_type"
#define USB_RUN                 "/sys/monitor/usb_port/config/run"

/* GPIO debug for earphone */
#define GPIO_DEBUG              "/sys/kernel/debug/gpio"
#define GPIO_EARPHONE_NAME      "earphone_detect_gpio"

/* USB gadget control via native usb.sh */
#define USB_SH                  "/usr/bin/usb.sh"

/* Tinymix PA controls */
#define TINYMIX_PATH            "tinymix"
#define PA_SWITCH_CTL           "35"    /* speaker on off switch */

/* Power button */
#define INPUT_EVENT0            "/dev/input/event0"
#define INPUT_EVENT1            "/dev/input/event1"
#define EVDEV_BTN_POWER         116
#define POWER_HOLD_MS           3000

/* Log */
#define LOG_PATH                "/tmp/powkiddy_daemon.log"

/* ─── Globals ────────────────────────────────────────────────────────────── */

static FILE        *log_fp       = NULL;
static volatile int running      = 1;
static int          adb_active   = 0;

/* Power button state */
static int          power_pressed     = 0;
static long long    power_press_time  = 0;
static int          power_triggered   = 0;

/* ─── Time ───────────────────────────────────────────────────────────────── */

static long long get_time_ms(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (long long)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
}

static void sleep_ms(int ms)
{
    struct timespec ts;
    ts.tv_sec  = ms / 1000;
    ts.tv_nsec = (ms % 1000) * 1000000L;
    nanosleep(&ts, NULL);
}

/* ─── Logging ────────────────────────────────────────────────────────────── */

static void log_msg(const char *fmt, ...)
{
    time_t t = time(NULL);
    struct tm *tm = localtime(&t);
    char timebuf[32];
    strftime(timebuf, sizeof(timebuf), "%Y-%m-%d %H:%M:%S", tm);

    va_list ap;
    va_start(ap, fmt);
    fprintf(log_fp, "[%s] ", timebuf);
    vfprintf(log_fp, fmt, ap);
    fprintf(log_fp, "\n");
    fflush(log_fp);
    va_end(ap);
}

/* ─── File helpers ───────────────────────────────────────────────────────── */

static int read_file_str(const char *path, char *buf, size_t len)
{
    int fd = open(path, O_RDONLY);
    if (fd < 0) return -1;
    ssize_t n = read(fd, buf, len - 1);
    close(fd);
    if (n <= 0) return -1;
    buf[n] = '\0';
    char *nl = strchr(buf, '\n');
    if (nl) *nl = '\0';
    return 0;
}

static int write_file_str(const char *path, const char *val)
{
    int fd = open(path, O_WRONLY);
    if (fd < 0) return -1;
    write(fd, val, strlen(val));
    close(fd);
    return 0;
}

static int read_file_int(const char *path)
{
    char buf[16];
    if (read_file_str(path, buf, sizeof(buf)) < 0) return -1;
    return atoi(buf);
}

static int run_cmd(const char *cmd)
{
    log_msg("CMD: %s", cmd);
    int ret = system(cmd);
    if (ret != 0) log_msg("CMD failed: %d", ret);
    return ret;
}

/* ─── Earphone detection ─────────────────────────────────────────────────── */

/*
 * Parse /sys/kernel/debug/gpio for earphone_detect_gpio
 * Returns 1 if plugged (lo), 0 if unplugged (hi), -1 on error
 */
static int read_earphone_state(void)
{
    FILE *f = fopen(GPIO_DEBUG, "r");
    if (!f) return -1;

    char line[128];
    int result = -1;

    while (fgets(line, sizeof(line), f)) {
        if (strstr(line, GPIO_EARPHONE_NAME)) {
            if (strstr(line, " lo"))
                result = 1;  /* lo = plugged */
            else if (strstr(line, " hi"))
                result = 0;  /* hi = unplugged */
            break;
        }
    }

    fclose(f);
    return result;
}

static void set_pa(int on)
{
    if (on) {
        log_msg("Earphone unplugged -> PA on");
        run_cmd(TINYMIX_PATH " " PA_SWITCH_CTL " 1");
    } else {
        log_msg("Earphone plugged -> PA off");
        run_cmd(TINYMIX_PATH " " PA_SWITCH_CTL " 0");
    }
}

/* ─── ADB management ─────────────────────────────────────────────────────── */
/*
static void adb_cleanup(void)
{
    log_msg("ADB cleanup...");
    run_cmd(USB_SH " DISABLE 2>/dev/null");
    sleep_ms(1000);
    run_cmd(USB_SH " ENABLE_HOST 2>/dev/null");
    sleep_ms(1000);
}

static int adb_load(void)
{
    log_msg("ADB loading...");

    run_cmd(USB_SH " DISABLE_HOST 2>/dev/null");
    sleep_ms(1000);

    if (run_cmd(USB_SH " ADD_FUNCTIONS mass_adb 2>/dev/null") != 0) {
        log_msg("usb.sh ADD_FUNCTIONS failed");
        return -1;
    }
*/
    /* Wait for gadget + adbd to fully initialize.
     * USB status fluctuates during this period - main loop must ignore it. */
/*    sleep_ms(4000);

    char state[32] = "";
    read_file_str("/sys/class/android_usb/android0/state", state, sizeof(state));
    log_msg("ADB gadget state: %s", state);

    adb_active = 1;
    return 0;
}
*/
/* ─── Power button ───────────────────────────────────────────────────────── */

static void trigger_poweroff(void)
{
    log_msg("Power button held %dms -> shutdown", POWER_HOLD_MS);
    system("killall retroarch 2>/dev/null");
    system("killall simplermenu_plus 2>/dev/null");
	sync();
    sleep(1);
    system("poweroff");
    running = 0;
}

static void handle_key_event(struct input_event *ev)
{
    if (ev->type != EV_KEY) return;

    if (ev->code == EVDEV_BTN_POWER) {
        if (ev->value == 1) {
            power_pressed    = 1;
            power_press_time = get_time_ms();
            power_triggered  = 0;
            log_msg("Power button pressed");
        } else if (ev->value == 0) {
            power_pressed   = 0;
            power_triggered = 0;
            log_msg("Power button released");
        }
    }
}

static int open_input(const char *dev)
{
    int fd = open(dev, O_RDONLY | O_NONBLOCK);
    if (fd >= 0)
        log_msg("Opened input: %s", dev);
    else
        log_msg("Failed to open input: %s (%s)", dev, strerror(errno));
    return fd;
}

/* ─── Signal handler ─────────────────────────────────────────────────────── */

static void sig_handler(int sig)
{
    (void)sig;
    running = 0;
}

/* ─── Main ───────────────────────────────────────────────────────────────── */

int main(void)
{
    log_fp = fopen(LOG_PATH, "w");
    if (!log_fp) log_fp = stderr;

    log_msg("powkiddy_daemon started");

    signal(SIGTERM, sig_handler);
    signal(SIGINT,  sig_handler);
    signal(SIGCHLD, SIG_DFL);  /* Avoid zombie children from system() */

    /* Init USB monitor in device mode */
//    write_file_str(USB_PORT_TYPE, "0");
//    write_file_str(USB_RUN,       "1");

    /* Open input devices for power button */
    int event0_fd = open_input(INPUT_EVENT0);
    int event1_fd = open_input(INPUT_EVENT1);

    int prev_pc       = -1;
    int prev_earphone = -1;

    while (running) {

        /* ── Input event polling (non-blocking) ── */
        if (event0_fd >= 0 || event1_fd >= 0) {
            fd_set readfds;
            struct timeval tv;
            FD_ZERO(&readfds);
            int max_fd = -1;

            if (event0_fd >= 0) { FD_SET(event0_fd, &readfds); if (event0_fd > max_fd) max_fd = event0_fd; }
            if (event1_fd >= 0) { FD_SET(event1_fd, &readfds); if (event1_fd > max_fd) max_fd = event1_fd; }

            tv.tv_sec  = 0;
            tv.tv_usec = 50000;  /* 50ms */

            if (select(max_fd + 1, &readfds, NULL, NULL, &tv) > 0) {
                struct input_event ev;
                if (event0_fd >= 0 && FD_ISSET(event0_fd, &readfds))
                    while (read(event0_fd, &ev, sizeof(ev)) == sizeof(ev))
                        handle_key_event(&ev);
                if (event1_fd >= 0 && FD_ISSET(event1_fd, &readfds))
                    while (read(event1_fd, &ev, sizeof(ev)) == sizeof(ev))
                        handle_key_event(&ev);
            }
        }

        long long now = get_time_ms();

        /* ── Power button hold check ── */
        if (power_pressed && !power_triggered) {
            if ((now - power_press_time) >= POWER_HOLD_MS) {
                power_triggered = 1;
                trigger_poweroff();
            }
        }

        /* ── Earphone detection ── */
        int earphone = read_earphone_state();
        if (earphone >= 0 && earphone != prev_earphone) {
            set_pa(!earphone);  /* plugged=1 -> PA off, unplugged=0 -> PA on */
            prev_earphone = earphone;
        }

        /* ── ADB hotplug ── */
/*        int pc      = read_file_int(USB_PC_CONNECTED);
        int charger = read_file_int(USB_CHARGER_CONNECTED);

        if (pc == 1 && charger != 0 && prev_pc != 1) {
            log_msg("USB PC+Charger detected"); */
            /* Record connect time for debounce */
/*            long long connect_time = get_time_ms();
            if (adb_load() < 0) {
                log_msg("ADB init failed, will retry on next plug");
                prev_pc = 0;
            } else {
                prev_pc = 1;
                (void)connect_time;
            }
        } else if (pc == 0 && charger == 0 && prev_pc == 1) {
	*/
            /* Only disconnect if BOTH pc and charger are 0
             * and we wait for a stable low reading */
  /*          sleep_ms(1000);
            int pc2      = read_file_int(USB_PC_CONNECTED);
            int charger2 = read_file_int(USB_CHARGER_CONNECTED);
            if (pc2 == 0 && charger2 == 0) {
                log_msg("USB disconnected (confirmed)");
                adb_cleanup();
                adb_active = 0;
                prev_pc = 0;
            } else {
                log_msg("USB disconnect was transient, ignoring");
            }
        } else if (pc >= 0 && prev_pc == -1) {
	*/
            /* First read - init state without triggering */
   //         prev_pc = (pc == 1 && charger != 0) ? 1 : 0;
     //   }

        sleep_ms(POLL_INTERVAL_MS);
    }

    /* Cleanup on exit */
    log_msg("Daemon exiting...");
//    if (adb_active) adb_cleanup();
    if (event0_fd >= 0) close(event0_fd);
    if (event1_fd >= 0) close(event1_fd);
    if (log_fp != stderr) fclose(log_fp);

    return 0;
}
