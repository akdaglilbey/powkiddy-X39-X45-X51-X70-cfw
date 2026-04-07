#/bin/sh

set -e
export NUM_THREAD=8

cd $(pwd)/project
source set_env.sh

cd RetroArch
make -j$NUM_THREAD -f Makefile.powkiddy
cp retroarch $(pwd)/../../output/usr/bin
cd ..

cd DinguxCommander
make -j$NUM_THREAD
cp output/DinguxCommander $(pwd)/../../output/usr/bin
cd ..

cd simplermenu_plus
make -j$NUM_THREAD -f Makefile.powkiddy
cp output/simplermenu_plus $(pwd)/../../output/usr/bin
cd ..

cd st-sdl
make
cp st $(pwd)/../../output/usr/bin
cd ..

cd dac-analyser
$CC -o dac_decoder reg_dac_analysis.c
cp dac_decoder $(pwd)/../../output/usr/bin
cd ..

cd fbset
make clean
make -j$NUM_THREAD
cp fbset $(pwd)/../../output/usr/bin
cp modeline2fb $(pwd)/../../output/usr/bin
cd ..

cd power_volume_handler
$CC -o power_volume_handler power_volume_handler.c
cp power_volume_handler $(pwd)/../../output/usr/bin
cd ..

cd watchdog_feeder
$CC -o watchdog_feeder watchdog_feeder.c
cp watchdog_feeder $(pwd)/../../output/usr/bin
cd ..

rm -rf tinyalsa
git clone -b v1.0.0 --depth 1 https://github.com/tinyalsa/tinyalsa.git
cd tinyalsa
make CROSS_COMPILE=$ARMABI-
make install DESTDIR=$(pwd)/../../output/

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
cp st $(pwd)/../../output/usr/bin

