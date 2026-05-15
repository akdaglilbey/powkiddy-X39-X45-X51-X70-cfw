#!/bin/sh
#start adb process
/usr/bin/usb.sh DISABLE_HOST
sleep 1
/usr/bin/usb.sh ADD_FUNCTIONS mass_adb
#spawn script to kill manager immediately
#/mnt/card/kill_manager.sh &

# mount
mount -t ext3 -o loop /mnt/card/rootfs.ext3 /mnt/card/cfw/fs
mount -t proc proc /mnt/card/cfw/fs/proc
mount -t sysfs sysfs /mnt/card/cfw/fs/sys
mount -t tmpfs tmpfs /mnt/card/cfw/fs/tmp
mount -o bind /dev /mnt/card/cfw/fs/dev
mkdir -p /mnt/card/cfw/fs/dev/pts
mount -t devpts devpts /mnt/card/cfw/fs/dev/pts
mkdir -p /mnt/card/card/fs/dev/shm
mount -t tmpfs tmpfs /mnt/card/cfw/fs/dev/shm
mount -t debugfs debugfs /mnt/card/cfw/fs/sys/kernel/debug

# mount original
mount -o bind / /mnt/card/cfw/fs/mnt/original

# new root
NEW_ROOT="/mnt/card/cfw/fs/"
cd ${NEW_ROOT}
exec chroot . /etc/startup.sh
