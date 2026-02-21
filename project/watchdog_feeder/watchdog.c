/* Watchdog Feeder for Actions OWL (ATM7051)
 * Keeps the system alive by feeding the hardware watchdog
 * Compile: arm-linux-gcc -o watchdog_feeder watchdog_feeder.c
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/watchdog.h>
#include <signal.h>
#include <string.h>
#include <errno.h>

static int wdt_fd = -1;

void cleanup(int sig)
{
    if (wdt_fd >= 0)
    {
        /* Write magic byte 'V' to disable watchdog before closing */
        write(wdt_fd, "V", 1);
        close(wdt_fd);
        printf("Watchdog disabled cleanly\n");
    }
    exit(0);
}

int main(int argc, char *argv[])
{
    int timeout = 30;      /* Default 30 seconds timeout */
    int interval = 10;     /* Feed every 10 seconds */
    int dummy;
    
    /* Parse arguments */
    if (argc > 1)
        interval = atoi(argv[1]);
    
    if (argc > 2)
        timeout = atoi(argv[2]);
    
    /* Setup signal handlers for clean exit */
    signal(SIGINT, cleanup);
    signal(SIGTERM, cleanup);
    
    /* Open watchdog device */
    wdt_fd = open("/dev/watchdog", O_WRONLY);
    if (wdt_fd < 0)
    {
        perror("ERROR: Cannot open /dev/watchdog");
        return 1;
    }
    
    printf("Watchdog feeder started\n");
    
    /* Set timeout (optional - driver may have default) */
    if (ioctl(wdt_fd, WDIOC_SETTIMEOUT, &timeout) == 0)
    {
        printf("Watchdog timeout set to %d seconds\n", timeout);
        
        /* Read back actual timeout */
        if (ioctl(wdt_fd, WDIOC_GETTIMEOUT, &timeout) == 0)
            printf("Actual timeout: %d seconds\n", timeout);
    }
    else
    {
        printf("Warning: Could not set timeout (using driver default)\n");
    }
    
    /* Enable watchdog */
    int options = WDIOS_ENABLECARD;
    if (ioctl(wdt_fd, WDIOC_SETOPTIONS, &options) < 0)
        printf("Warning: Could not explicitly enable watchdog\n");
    
    printf("Feeding watchdog every %d seconds...\n", interval);
    
    /* Main loop - feed the watchdog */
    while (1)
    {
        /* Method 1: Use KEEPALIVE ioctl (preferred) */
        if (ioctl(wdt_fd, WDIOC_KEEPALIVE, &dummy) < 0)
        {
            perror("ERROR: WDIOC_KEEPALIVE failed");
            
            /* Method 2: Fallback - write any byte */
            if (write(wdt_fd, "\0", 1) < 0)
            {
                perror("ERROR: write to watchdog failed");
                break;
            }
        }
        
        sleep(interval);
    }
    
    cleanup(0);
    return 0;
}