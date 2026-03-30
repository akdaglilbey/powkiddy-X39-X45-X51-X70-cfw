#/bin/sh

dd if=/dev/zero of=rootfs.ext3 bs=1M count=100
mkfs.ext3 rootfs.ext3
mkdir mnt
sudo mount -o loop rootfs.ext3 mnt
sudo cp -a output/* mnt/
sudo umount mnt
