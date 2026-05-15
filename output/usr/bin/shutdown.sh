#!/bin/sh
killall retroarch
sleep 1
killall simplermenu_plus
display_image /mnt/card/cfw/resources/shutdown.bmp
sync
sleep 2
poweroff
