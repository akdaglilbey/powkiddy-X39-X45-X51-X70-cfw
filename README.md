Powkiddy x39pro/x45/x51/x70 Custom firmware and toolchain

# Installation:
 - Copy run.sh and CFW folder on SD-card
 - Put update.zip on SD Card
      -  update.zip contains original Powkiddy firmware with startup script updated
 - Reboot the console and perform the update when asked by the console.
 - When the system is now booting, after few seconds the menu is killed and retroarch is started.
 - Console is powered off when exiting retroarch
 
# Uninstall:
 - Remove run.sh from SD Card

# How to compile:
 - Install ubuntu 16.04 64 bits
 - Get this repository
 - git submodules init
 - build the toolchain (buildroot.2015.02 -> make toolchain
 - In order to compile something with the toolchain, apply the environments variables defined "source project/set_env.sh" and read how-to file
 - SDL1-2 has been modified to set the audio to correct buffer_size/period_size and do joypad remapping
 - Retroarch has been heavily modified to
   - GFX (SDL_DINGUX) : framebuffer specs + resize/stretch screen
   - Alsa driver (ALSA) to use 32_LE format with correct buffer/period size and integration of Bass filter (high pass) to have better sound especially in SNES games
   - Gamepad driver (LINUXRAW) : match the non-standards event code of powkiddy for gamepad input
 - Firmware directory contains the scripts to extract the various partitions of the FW, a repack for update.zip to flash the consoles is possible as well (thanks [fox_exe](https://github.com/FoxExe/PowKiddy_fw) )



# Notes:

## Updated /etc/init.d/rcS script to start retroarch on boot:

This is running run.sh script on the SD Card
```
                        echo "run nomal mode"
                        mount /dev/mmcblk0p1 /mnt/card/
                        sleep 5
                        /mnt/card/run.sh &
                        sleep 5
                        manager &
```

**run.sh on sdcard:**
The script is doing the following:
- Starting the watchdog BEFORE manager so we have ownership on the watchdog
- Kill the powkiddy softwares
- Starting retroarch with various environments variables
- Setting CPU to 900mhz in perf mode
- Reset the framebuffer
- Activate speaker + volume set to 20

When retroarch exit, the console is powered off

```
#!/bin/sh
cd /mnt/card
/mnt/card/watchdog_feeder 5 30 &
sleep 15
killall -9 manager
killall -9 launcher
killall -9 audio_service
killall -9 msg_server
sleep 1
/etc/backlight.sh open &
export HOME=/mnt/card/
export SDL_VIDEODRIVER=fbcon
export SDL_NOMOUSE=1
export SDL_MOUSEDEV=/dev/null
export SDL_VIDEO_FBCON_ROTATION=CCW
export SDL_AUDIODRIVER=alsa
export SDL_AUDIO_ALSA_DEBUG=1
export SDL_AUDIO_ALLOW_FREQUENCY_CHANGE=0
echo "0,0" > /sys/class/graphics/fb0/pan
# Reset virtual position
echo 0 > /sys/class/graphics/fb0/virtual_size
/bin/tinymix 35 1 &
/bin/tinymix 15 20 &
echo 1 >  /sys/devices/system/cpu/cpu1/online
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo performance > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
echo 900000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
killall -9 manager
killall -9 launcher
killall -9 audio_service
killall -9 msg_server
/bin/adbd&
sleep 1
/mnt/card/retroarch
sync &
poweroff &
```

## Retroarch
Use:
- **SDL_DINGUX** for video
    - By default there is no upscaling.
    - You can upscale with Keep aspect ratio and Integer scaling options
- **ALSA (prefered)** or **SDL** for audio
    - Use resampler CC or nearest to 48000
    - Delay to 64ms
- **SDL** for input
- **LINUXRAW (prefered)** or **SDL** for Gamepad


## Infos
To connect to the console, you must have the USB-C (charger) connected and USB-A cable ton USB1 port.

Switch ON the console (press 3s the poweron button) until you see on the display an image with computer and console! if you are on ADB shell on charging screen, the framebuffer and the buttons are not working correctly!

mount the sdcard : 
```mount /dev/mmcblk0p1 /mnt/card/```

## ALSA SOUND
Driver source: https://github.com/LeMaker/linux-actions/tree/linux-3.10.y/sound/soc/atc260x

32 bits / rate 8000-192000 / stereo

Avoid MMAP ! sound is really dirty !

Buffer size 4096

Period size 1024

use plug !

cat /proc/asound/card0/pcm0p/sub0/hw_params

content of /mnt/card/alsa.conf :
```
pcm.hw0 {
    type hw
    card 0
    device 0
}
pcm.!default {
    type plug
    slave.pcm "hw0"
    slave.format S32_LE
    slave.channels 2
}

ctl.!default {
    type hw
    card 0
}

```

## Keybinding
```
/* Powkiddy X39 Pro button mapping - customize based on your evtest results */
#define EVDEV_BTN_A      158  
#define EVDEV_BTN_B      139  
#define EVDEV_BTN_X      308  
#define EVDEV_BTN_Y      352  
#define EVDEV_BTN_L1     407  
#define EVDEV_BTN_R1     412  
#define EVDEV_BTN_L2     313  
#define EVDEV_BTN_R2     312  
#define EVDEV_BTN_SELECT 314  
#define EVDEV_BTN_START  315  
#define EVDEV_BTN_MENU   174  
#define EVDEV_BTN_VOLUP  115  
#define EVDEV_BTN_VOLDOWN 114  
#define EVDEV_BTN_ON 116  
```
## Watchdog

link to driver: https://github.com/LeMaker/linux-actions/blob/linux-3.10.y/drivers/watchdog/owl_wdt.c

