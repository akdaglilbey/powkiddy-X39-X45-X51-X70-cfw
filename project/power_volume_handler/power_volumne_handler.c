/* Power/Volume Control Daemon for Powkiddy X39 Pro
 *
 * - Monitors volume up/down buttons and adjusts ALSA mixer
 * - Long press POWER (5s) triggers safe shutdown
 *
 * Compile:
 * arm-linux-gcc -o volume_daemon volume_daemon.c -static -Os  */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <sys/select.h>
#include <linux/input.h>
#include <time.h>
#include <sys/reboot.h>

/* Button definitions */
#define EVDEV_BTN_VOLUP    115
#define EVDEV_BTN_VOLDOWN  114
#define EVDEV_BTN_ON       116

/* Power hold duration */
#define POWER_HOLD_MS      5000

/* Volume settings */
#define VOLUME_MIN         0
#define VOLUME_MAX         40
#define VOLUME_STEP        1
#define TINYMIX_CONTROL    15

/* Repeat settings */
#define REPEAT_INITIAL_DELAY_MS  500
#define REPEAT_RATE_MS           100

static int running = 1;
static int current_volume = -1;

/* Button state tracking */
static int volup_pressed = 0;
static int voldown_pressed = 0;
static long long volup_press_time = 0;
static long long voldown_press_time = 0; static long long last_repeat_time = 0;

static int power_pressed = 0;
static long long power_press_time = 0;
static int power_triggered = 0;

void signal_handler(int sig)
{
    printf("Received signal %d, exiting...\n", sig);
    running = 0;
}

long long get_time_ms(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (long long)ts.tv_sec * 1000 + ts.tv_nsec / 1000000; }

int get_volume(void)
{
    FILE *fp;
    char cmd[128];
    char output[256];
    int volume = -1;

    snprintf(cmd, sizeof(cmd),
             "/bin/tinymix %d 2>/dev/null", TINYMIX_CONTROL);

    fp = popen(cmd, "r");
    if (!fp)
        return -1;

    if (fgets(output, sizeof(output), fp))
    {
        char *value = strchr(output, ':');
        if (value)
            volume = atoi(value + 1);
        else
            volume = atoi(output);
    }

    pclose(fp);
    return volume;
}

int set_volume(int volume)
{
    char cmd[128];

    if (volume < VOLUME_MIN)
        volume = VOLUME_MIN;
    if (volume > VOLUME_MAX)
        volume = VOLUME_MAX;

    snprintf(cmd, sizeof(cmd),
             "/bin/tinymix %d %d >/dev/null 2>&1",
             TINYMIX_CONTROL, volume);

    if (system(cmd) == 0)
    {
        current_volume = volume;
        printf("Volume set to: %d/%d\n", volume, VOLUME_MAX);
        return 0;
    }

    return -1;
}

void adjust_volume(int delta)
{
    if (current_volume < 0)
    {
        current_volume = get_volume();
        if (current_volume < 0)
            current_volume = 20;
    }

    set_volume(current_volume + delta);
}

void trigger_poweroff(void)
{
    printf("Power button held for 5 seconds. Shutting down...\n");

    sync();
    system("killall retroarch >/dev/null 2>&1");
    sleep(1);

    /* You can replace with reboot(RB_POWER_OFF); if preferred */
    system("poweroff");

    running = 0;
}

void handle_key_event(struct input_event *ev) {
    long long now = get_time_ms();

    if (ev->type != EV_KEY)
        return;

    switch (ev->code)
    {
        case EVDEV_BTN_VOLUP:
            if (ev->value == 1)
            {
                adjust_volume(VOLUME_STEP);
                volup_pressed = 1;
                volup_press_time = now;
                last_repeat_time = now;
            }
            else if (ev->value == 0)
            {
                volup_pressed = 0;
            }
            break;

        case EVDEV_BTN_VOLDOWN:
            if (ev->value == 1)
            {
                adjust_volume(-VOLUME_STEP);
                voldown_pressed = 1;
                voldown_press_time = now;
                last_repeat_time = now;
            }
            else if (ev->value == 0)
            {
                voldown_pressed = 0;
            }
            break;

        case EVDEV_BTN_ON:
            if (ev->value == 1)
            {
                power_pressed = 1;
                power_press_time = now;
                power_triggered = 0;
                printf("POWER pressed\n");
            }
            else if (ev->value == 0)
            {
                power_pressed = 0;
                power_triggered = 0;
                printf("POWER released\n");
            }
            break;
    }
}

int open_input(const char *dev)
{
    int fd = open(dev, O_RDONLY | O_NONBLOCK);
    if (fd >= 0)
        printf("Opened %s\n", dev);
    return fd;
}

int main(void)
{
    int event0_fd, event1_fd;
    struct input_event ev;
    fd_set readfds;
    struct timeval tv;

    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);

    printf("Volume Control Daemon starting...\n");

    event0_fd = open_input("/dev/input/event0");
    event1_fd = open_input("/dev/input/event1");

    if (event0_fd < 0 && event1_fd < 0)
    {
        fprintf(stderr, "No input devices found\n");
        return 1;
    }

    current_volume = get_volume();
    printf("Initial volume: %d\n", current_volume);

    while (running)
    {
        FD_ZERO(&readfds);
        int max_fd = -1;

        if (event0_fd >= 0)
        {
            FD_SET(event0_fd, &readfds);
            if (event0_fd > max_fd) max_fd = event0_fd;
        }

        if (event1_fd >= 0)
        {
            FD_SET(event1_fd, &readfds);
            if (event1_fd > max_fd) max_fd = event1_fd;
        }

        tv.tv_sec = 0;
        tv.tv_usec = 50000;

        int ret = select(max_fd + 1, &readfds, NULL, NULL, &tv);
        if (ret < 0)
        {
            if (errno == EINTR)
                continue;
            break;
        }

        long long now = get_time_ms();

        /* Volume repeat */
        if (volup_pressed &&
            (now - volup_press_time) >= REPEAT_INITIAL_DELAY_MS &&
            (now - last_repeat_time) >= REPEAT_RATE_MS)
        {
            adjust_volume(VOLUME_STEP);
            last_repeat_time = now;
        }

        if (voldown_pressed &&
            (now - voldown_press_time) >= REPEAT_INITIAL_DELAY_MS &&
            (now - last_repeat_time) >= REPEAT_RATE_MS)
        {
            adjust_volume(-VOLUME_STEP);
            last_repeat_time = now;
        }

        /* Power hold */
        if (power_pressed && !power_triggered)
        {
            if ((now - power_press_time) >= POWER_HOLD_MS)
            {
                power_triggered = 1;
                trigger_poweroff();
            }
        }

        /* Process events */
        if (event0_fd >= 0 && FD_ISSET(event0_fd, &readfds))
        {
            while (read(event0_fd, &ev, sizeof(ev)) == sizeof(ev))
                handle_key_event(&ev);
        }

        if (event1_fd >= 0 && FD_ISSET(event1_fd, &readfds))
        {
            while (read(event1_fd, &ev, sizeof(ev)) == sizeof(ev))
                handle_key_event(&ev);
        }
    }

    if (event0_fd >= 0) close(event0_fd);
    if (event1_fd >= 0) close(event1_fd);

    printf("Volume daemon exiting\n");
    return 0;
}
