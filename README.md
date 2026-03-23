# Powkiddy x39pro/x45/x51/x70 Custom firmware with RetroArch

![image](IMG_0052.jpg)

Enjoy real memory card for multicd PSX games and ability to change the screen-scaling !

# Disclaimer:
This custom firmware is provided "as is" without any warranties, express or implied.
I shall not be held responsible for any damage, loss of data, malfunction, bricking of the device, voided warranty, or any other issues resulting from the installation or use of this firmware.
By installing this firmware, you agree that you do so entirely at your own risk and assume full responsibility for any consequences.

# Retroarch
Use:
- **SDL_POWKIDDY** for video
    - You can upscale with Keep aspect ratio and Integer scaling options (Settings -> Video -> Scaling)
    - You can change screen orientation (Settings -> Video -> Output)
- **ALSA (prefered)** or **SDL** for audio
    - Use resampler CC or nearest to 48000
    - Delay to 160ms
- **LINUXRAW** for input
- **LINUXRAW (prefered)** or **SDL** for Gamepad

**L1 + R1** or **MENU** button to get menu in game

**You can copy your bios in cfw/.config/retroarch/system, stock SD card contains some bios in game/.bios**

# Retroarch cores included
- Standalone:
  - 2048
  - mrboom
  - prboom
- GB/GBC/GBA:
  - gambatte
  - gearboy
  - gpsp
  - mgba
  - tgbdual
  - vbam
- NES:
  - fceumm
  - nestopia
  - quicknes
- SNES:
  - snes9x2002
  - snes9x2005
  - snes9x2010
  - snes9x
  - mednafen_supafaust
- Megadrive:
  - genesis_plus_gx
  - picodrive
- PSX:
  - pcsx_rearmed
- Neogeo/CPS/Arcade
  - fbneo
  - mame2000
  - mame2003
  - mame2003_plus
  - fbalpha2012
- Others:
  - mednafen_ngp
  - mednafen_vb
  - ffmpeg

# Installation:
 - Copy run.sh and CFW folder on SD-card
 - Put update.zip on SD Card
      -  update.zip contains original Powkiddy firmware with startup script updated
      -  **Verify the update.zip CRC once copied on SD is correct !**  
 - Reboot the console and perform the update when asked by the console. If the update is not detected, remove and insert the SD card when builtin frontend is started.
 - When the system is now booting, after few seconds the menu is killed and retroarch is started.
 - Console is powered off when exiting retroarch

## In case of CFW update and unless specified, the update.zip process is not required, only extract the cfw to the SD.
 
# Uninstall:
 - Remove run.sh from SD Card

# Changelog
## V0.3:
**Many thanks to @dmolina007 [https://github.com/dmolina007] for the tests and suggestions !**

- Audio delay set to 160 
- 4 Scaling mode:
  - integer_scaling && !keep_aspect : fill full physical height
  - !integer_scaling && keep_aspect: core output resolution
  - integer_scaling && keep_aspect: max scaling rounded to integer (x2,x3,x4)
  - !integer_scaling && !keep_aspect: full screen stretch
- Charging mode do not start Retroarch
- 3 new cores (mednafen_ngp, mednafen_vb, ffmpeg [degraded performances and crash])
- Correct gamepad button assignement
- Earphone detection
- ADB shell and file transfer activation on USB detection
- Restart Retroarch and Bilinear filtering options removed
- Screen rotation in RetroArch's settings
- Cleanup source code

## V0.2
- Scaling and rotation of the screen in retroarch to avoid SDL Shadowbuf, FPS > 150 in menu
- Upscaling nearest (fast) and bilinear (slow unless we use HW scaler)
- Better sound parameters and usage of ATC2603 registers

# How to compile:
 - Install Ubuntu or WSL2
 - Get this repository
 - git submodule init
 - git submodule update
 - extract toolchain
 - In order to compile something with the toolchain, apply the environments variables defined "source project/set_env.sh" and read how-to file
 - SDL1-2 has been modified to set the audio to correct buffer_size/period_size and do joypad remapping
 - Retroarch has been heavily modified to
   - GFX (SDL_POWKIDDY) : framebuffer specs + resize/stretch screen
   - Alsa driver (ALSA) to use 32_LE format with correct buffer/period size and integration of Bass filter (high pass) to have better sound especially in SNES games
   - Gamepad driver (LINUXRAW) : match the non-standards event code of powkiddy for gamepad input
 - Firmware directory contains the scripts to extract the various partitions of the FW, a repack for update.zip to flash the consoles is possible as well (thanks [fox_exe](https://github.com/FoxExe/PowKiddy_fw) )

## Needed package:
 - build-essentials bzip2 automake
# Improvements:
 - Add a menu like gmenu2x to be able to start ports or programs

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
- Activate speaker + volume set to 40

When retroarch exit, the console is powered off

```
#!/bin/sh
export LD_LIBRARY_PATH=/mnt/card/cfw/libs:$LD_LIBRARY_PATH
cd /mnt/card/cfw
/mnt/card/cfw/tools/watchdog_feeder 5 30 &
sleep 15
while ps w | grep "[p]oweron" > /dev/null
do
    sleep 5
done
echo 1 >  /sys/devices/system/cpu/cpu1/online
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo performance > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
echo 900000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo 900000 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq

killall -9 manager
killall -9 launcher
killall -9 audio_service
killall -9 msg_server
killall -9 adbd
sleep 1
/etc/backlight.sh open &
export HOME=/mnt/card/cfw
export SDL_VIDEODRIVER=fbcon
export SDL_NOMOUSE=1
export SDL_MOUSEDEV=/dev/null
#export SDL_VIDEO_FBCON_ROTATION=CCW
export SDL_AUDIODRIVER=alsa
export SDL_AUDIO_ALSA_DEBUG=0
export SDL_AUDIO_ALLOW_FREQUENCY_CHANGE=0
echo "0,0" > /sys/class/graphics/fb0/pan
# Reset virtual position
echo 0 > /sys/class/graphics/fb0/virtual_size
/bin/tinymix 35 1 &
/bin/tinymix 30 1 &
/bin/tinymix 15 40 &
echo 1 >  /sys/devices/system/cpu/cpu1/online
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo performance > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
echo 900000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo 900000 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq
killall -9 manager
killall -9 launcher
killall -9 audio_service
killall -9 msg_server
killall -9 adbd
echo "2 0x0223" > /sys/kernel/debug/asoc/s900_link/atc260x-audio/codec_reg
echo "0 0x0022" > /sys/kernel/debug/asoc/s900_link/atc260x-audio/codec_reg
echo "3 0xbebe" > /sys/kernel/debug/asoc/s900_link/atc260x-audio/codec_reg
echo "5 0x0468"  > /sys/kernel/debug/asoc/s900_link/atc260x-audio/codec_reg
echo "7 0x26BF"  > /sys/kernel/debug/asoc/s900_link/atc260x-audio/codec_reg

/mnt/card/cfw/tools/power_volume_daemon &
sleep 1
/mnt/card/cfw/retroarch
sync &
poweroff &

```

## Infos
To connect to the console, you must have the USB-C (charger) connected and USB-A cable ton USB1 port.

Switch ON the console (press 3s the poweron button) until you see on the display an image with computer and console! if you are on ADB shell on charging screen, the framebuffer and the buttons are not working correctly!

mount the sdcard : 
```mount /dev/mmcblk0p1 /mnt/card/```

## ALSA SOUND
Driver source: https://github.com/LeMaker/linux-actions/tree/linux-3.10.y/sound/soc/atc260x

32 bits / rate 8000-192000 / stereo

Avoid MMAP ! sound is really dirty !

Buffer size 768

Period size 7680

use plug !

cat /proc/asound/card0/pcm0p/sub0/hw_params

content of /mnt/card/cfw/alsa.conf :
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

## Hardware video scaler

https://github.com/LeMaker/linux-actions/tree/linux-3.10.y/drivers/video/owl/dss
fb0 = LCD principal (854×480)
fb1 = HDMI (pas utilisé)
video0 = Display Engine layer 0 (background)
video1 = Display Engine layer 1 (overlay avec scaling)

echo $((fb0_phys_start + 1639680)) > /sys/kernel/debug/de/video1/addr0
echo 256 > /sys/kernel/debug/de/video1/width
echo 224 > /sys/kernel/debug/de/video1/height
echo 854 > /sys/kernel/debug/de/video1/out_width
echo 480 > /sys/kernel/debug/de/video1/out_height
echo 1 > /sys/kernel/debug/de/video1/apply

```
#!/bin/sh
# Test Actions OWL Display Engine Hardware Scaler
# This tests video1 layer with hardware scaling

DE_VIDEO1="/sys/kernel/debug/de/video1"

echo "=== Current video1 configuration ==="
for f in width height out_width out_height pos_x pos_y color_mode addr0 pitch0; do
    echo "$f: $(cat $DE_VIDEO1/$f 2>/dev/null)"
done

echo ""
echo "=== Testing hardware scaler: 256x224 ? 854x480 ==="

# Configure video1 layer for SNES scaling
# Source: 256x224 (SNES resolution)
# Output: 854x480 (fullscreen)

echo 256 > $DE_VIDEO1/width
echo 224 > $DE_VIDEO1/height

echo 854 > $DE_VIDEO1/out_width
echo 480 > $DE_VIDEO1/out_height

# Position at (0,0)
echo 0 > $DE_VIDEO1/pos_x
echo 0 > $DE_VIDEO1/pos_y

# Color mode: RGB565 = 1
echo 1 > $DE_VIDEO1/color_mode

# Pitch (stride): 256 pixels * 2 bytes = 512
echo 512 > $DE_VIDEO1/pitch0

# Get framebuffer physical address (we'll need this)
# For now, just show current config
echo ""
echo "=== New configuration ==="
for f in width height out_width out_height; do
    echo "$f: $(cat $DE_VIDEO1/$f)"
done

echo ""
echo "Hardware scaler configured!"
echo "Now we need to:"
echo "1. Allocate a buffer for 256x224 pixels"
echo "2. Write pixels to that buffer"  
echo "3. Set addr0 to physical address of buffer"
echo "4. Echo 1 > apply to activate"

```





