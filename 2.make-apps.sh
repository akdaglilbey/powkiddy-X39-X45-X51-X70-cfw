#/bin/sh

set -e
export NUM_THREAD=8

rm -rf $(pwd)/../../output/opt 
mkdir $(pwd)/../../output/opt

cd $(pwd)/project
source set_env.sh

cd RetroArch
make -j$NUM_THREAD -f Makefile.powkiddy
cp retroarch $(pwd)/../../output/opt
cd ..

cd DinguxCommander
make -j$NUM_THREAD
cp output/DinguxCommander $(pwd)/../../output/opt
cd ..

cd simplemenu/simplemenu
make TARGET=MIYOO
cp simplemenu $(pwd)/../../output/opt
cd ..
cd ..

cd st-sdl
make
cp st $(pwd)/../../output/opt
cd ..

rm -rf busybox
git clone -b 1_36_1 --depth 1 https://github.com/mirror/busybox.git
cd busybox
make ARCH=arm CROSS-COMPILE=$ARMABI- defconfig
echo "CONFIG_STATIC=y" >> .config
make ARCH=arm CROSS-COMPILE=$ARMABI- -j$NUM_THREAD
make ARCH=arm CROSS-COMPILE=$ARMABI- CONFIG_PREFIX=$SYSROOT/../output install
cd ..


rm -rf strace
git clone -b v4.26 --depth 1 https://github.com/strace/strace.git
cd strace
./bootstrap
./configure --host=arm-linux-gnueabihf --build=$(gcc -dumpmachine) 
make -j$NUM_THREAD
cp st $(pwd)/../../output/opt