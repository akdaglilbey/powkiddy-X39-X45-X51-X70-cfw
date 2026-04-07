#!/bin/sh
#start watchdog
export PATH=$PATH:/usr/local/bin
watchdog_feeder 5 30 &

# unload and reload adcjoystick to get the controls
rmmod owl_gpio_matrix_adcjoystick 2>/dev/null
insmod /lib/modules/3.10.0/owl_gpio_matrix_adcjoystick.ko tiny_mode=0

#activate cpu1 and set to performance the cpu, maybe only cpu0 is needed
echo 1 >  /sys/devices/system/cpu/cpu1/online
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo performance > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
echo 900000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo 900000 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq

/etc/backlight.sh open &
tinymix 35 1 &
tinymix 30 1 &
tinymix 15 40 &

#set correct values for good sound
echo "2 0x0223" > /sys/kernel/debug/asoc/s900_link/atc260x-audio/codec_reg
echo "0 0x0022" > /sys/kernel/debug/asoc/s900_link/atc260x-audio/codec_reg
echo "3 0xbebe" > /sys/kernel/debug/asoc/s900_link/atc260x-audio/codec_reg
echo "5 0x0468"  > /sys/kernel/debug/asoc/s900_link/atc260x-audio/codec_reg
echo "7 0x26BF"  > /sys/kernel/debug/asoc/s900_link/atc260x-audio/codec_reg
power_volume_handler &
mount /dev/mmcblk0p1 /mnt/card/
export HOME=/mnt/card
export SDL_VIDEODRIVER=fbcon
export SMP_BASEPATH=/mnt/card/cfw/simplermenu_plus
export SMP_STATEFILE=/tmp/.state
export RA_CONFIG=/mnt/card/cfw/retroarch/retroarch.cfg
export SDL_NOMOUSE=1
export SDL_MOUSEDEV=/dev/null
export SDL_VIDEO_FBCON_ROTATION=CCW
export SDL_AUDIODRIVER=alsa
export SDL_AUDIO_ALSA_DEBUG=0
export SDL_AUDIO_ALLOW_FREQUENCY_CHANGE=0
echo "0,1" > /sys/class/graphics/fb0/pan
echo "0,0" > /sys/class/graphics/fb0/pan
simplermenu_plus
#sync
#poweroff
