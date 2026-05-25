#!/bin/sh
display_image /mnt/card/cfw/resources/shutdown-${SCREEN_WIDTH}x${SCREEN_HEIGHT}.bmp &
killall power_volume_handler
tinymix 35 1
tinymix 15 20
tinyplay /mnt/card/cfw/resources/shutdown.wav

killall retroarch
sleep 1
killall simplermenu_plus
sync
sleep 1
poweroff
