Powkiddy x39pro/x45/x51/x70 toolchain to compile custom binaries 

# How to use:
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

## Retroarch
Use:
- **SDL_DINGUX** for video
    - By default there is no upscaling.
    - You can upscale with Keep aspect ratio and Integer scaling options
- **ALSA** for audio
    - Use resampler CC or nearest to 48000
    - Delay to 64ms
- **SDL** for input
- **LINUXRAW** for Gamepad or **SDL**

To connect to the console, you must have the USB-C (charger) connected and USB-A cable ton USB1 port.

Switch ON the console (press 3s the poweron button) until you see on the display an image with computer and console! if you are on ADB shell on charging screen, the framebuffer and the buttons are not working correctly!

mount the sdcard : 
```mount /dev/mmcblk0p1 /mnt/card/```

## run.sh script:

```export HOME=/mnt/card/
export SDL_VIDEODRIVER=fbcon
export SDL_NOMOUSE=1
export SDL_MOUSEDEV=/dev/null
export SDL_VIDEO_FBCON_ROTATION=CCW
export SDL_AUDIODRIVER=alsa
#activate speakers
/bin/tinymix 35 1
#define volume
/bin/tinymix 15 20
echo "0,0" > /sys/class/graphics/fb0/pan
```

## ALSA SOUND
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
