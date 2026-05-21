#/bin/sh

set -e
export NUM_THREAD=$(nproc)

cd "$(pwd)/project"
source set_env.sh

mkdir -p \
	"$(pwd)/../output/usr/bin" \
	"$(pwd)/../output-sd/cfw/apps/DinguxCommander" \
	"$(pwd)/../output-sd/cfw/apps/st" \
	"$(pwd)/../output-sd/cfw/retroarch/filters/video"

echo "----------------- BUILD RETROARCH ---------------"

cd RetroArch
make clean -f Makefile.powkiddy
make -j$NUM_THREAD -f Makefile.powkiddy
cp retroarch "$(pwd)/../../output/usr/bin"
cp gfx/video_filters/*.filt "$(pwd)/../../output-sd/cfw/retroarch/filters/video/"
cd ..

echo "----------------- BUILD DINGUX COMMANDER ---------------"

cd DinguxCommander
for header in src/*.h; do
	if grep -q 'std::uint[0-9][0-9]*_t' "$header" && ! grep -q '^#include <cstdint>$' "$header"; then
		sed -i '/^#define .*_H_$/a #include <cstdint>' "$header"
	fi
done
sed -i \
	-e 's|^CXXFLAGS += $(shell $(SDL_CONFIG) --cflags)$|SDL_PREFIX ?= $(SYSROOT)/usr/local\nSDL_CFLAGS ?= -I$(SDL_PREFIX)/include -I$(SDL_PREFIX)/include/SDL -D_GNU_SOURCE=1 -D_REENTRANT\nSDL_LIBS ?= -L$(SDL_PREFIX)/lib -lSDL -lpthread\n\nCXXFLAGS += $(SDL_CFLAGS)|' \
	-e 's|^LINKFLAGS += $(shell $(SDL_CONFIG) --libs) -lSDL_image -lSDL_ttf$|LINKFLAGS += $(SDL_LIBS) -lSDL_image -lSDL_ttf|' \
	-e 's|^\t$(CMD)$(CXX) $(LINKFLAGS) -o $@ $^$|\t$(CMD)$(CXX) -o $@ $^ $(LINKFLAGS)|' \
	Makefile
make clean
make -j$NUM_THREAD
cp output/DinguxCommander "$(pwd)/../../output-sd/cfw/apps/DinguxCommander"
cp -rf res "$(pwd)/../../output-sd/cfw/apps/DinguxCommander"
cd ..

echo "----------------- BUILD SIMPLERMENU PLUS ---------------"

cd simplermenu_plus
sed -i 's|-Iinclude/ -DPOWKIDDY=1|-Iinclude/ -I$(SYSROOT)/usr/local/include/SDL -I$(SYSROOT)/usr/local/include -DPOWKIDDY=1|' Makefile.powkiddy
make clean -f Makefile.powkiddy
make -j$NUM_THREAD -f Makefile.powkiddy
cp output/simplermenu_plus "$(pwd)/../../output/usr/bin"
cd ..

echo "----------------- BUILD TERMINAL ST-SDL ---------------"

cd st-sdl
make clean
make \
	CC="$CC" \
	CFLAGS="$CFLAGS -I. -I$SYSROOT/usr/local/include/SDL -I$SYSROOT/usr/local/include -D_GNU_SOURCE=1 -D_REENTRANT -DVERSION=\\\"0.3\\\" -DPOWKIDDY -std=gnu11 -fPIC -ffunction-sections -fdata-sections -Wall" \
	LDFLAGS="-lc -L$SYSROOT/usr/local/lib -L$SYSROOT/usr/lib -lSDL -lpthread -lutil -lasound"
cp st "$(pwd)/../../output-sd/cfw/apps/st"
cd ..

echo "----------------- BUILD DAC-ANALYZER ---------------"

cd dac-analyser
$CC -o dac_decoder reg_dac_analysis.c
cp dac_decoder "$(pwd)/../../output/usr/bin"
cd ..
echo "----------------- BUILD FBSET ---------------"
cd fbset
make clean
make -j$NUM_THREAD
cp fbset "$(pwd)/../../output/usr/bin"
cp modeline2fb "$(pwd)/../../output/usr/bin"
cd ..
echo "----------------- BUILD POWER VOLUME HANDLER ---------------"
cd power_volume_handler
$CC -o power_volume_handler power_volume_handler.c
cp power_volume_handler "$(pwd)/../../output/usr/bin"
cd ..
echo "----------------- BUILD DISPLAY IMAGE ---------------"
cd display_image
$CC -o display_image display_image.c -lm
cp display_image "$(pwd)/../../output/usr/bin"
cd ..
echo "----------------- BUILD WATCHDOG FEEDER ---------------"
cd watchdog_feeder
$CC -o watchdog_feeder watchdog_feeder.c
cp watchdog_feeder "$(pwd)/../../output/usr/bin"
cd ..
echo "----------------- BUILD TINYALSA ---------------"
rm -rf tinyalsa
git clone -b v1.0.0 --depth 1 https://github.com/tinyalsa/tinyalsa.git
cd tinyalsa
PATH=$PATHGCC:$PATH make CROSS_COMPILE=$ARMABI-
rm -f "$(pwd)/../../output/usr/bin/tinyplay" "$(pwd)/../../output/usr/bin/tinycap" "$(pwd)/../../output/usr/bin/tinymix" "$(pwd)/../../output/usr/bin/tinypcminfo"
rm -f "$(pwd)/../../output/usr/lib/libtinyalsa.so" "$(pwd)/../../output/usr/lib/libtinyalsa.a"
make install DESTDIR="$(pwd)/../../output/" PREFIX=/usr DEB_HOST_MULTIARCH=
cd ..
echo "----------------- BUILD BUSYBOX ---------------"
rm -rf busybox
git clone -b 1_36_1 --depth 1 https://github.com/mirror/busybox.git
cd busybox
PATH=$PATHGCC:$PATH make ARCH=arm CROSS-COMPILE=$ARMABI- defconfig
sed -i 's/^CONFIG_TC=y$/# CONFIG_TC is not set/' .config
echo "CONFIG_STATIC=y" >> .config
PATH=$PATHGCC:$PATH make ARCH=arm CROSS-COMPILE=$ARMABI- -j$NUM_THREAD
PATH=$PATHGCC:$PATH make ARCH=arm CROSS-COMPILE=$ARMABI- CONFIG_PREFIX=$SYSROOT/../output install
cd ..
echo "----------------- BUILD STRACE ---------------"
rm -rf strace
git clone -b v6.10 --depth 1 https://github.com/strace/strace.git
cd strace
./bootstrap
./configure --host=$ARMABI --build=$(gcc -dumpmachine)
make -j$NUM_THREAD
cp src/strace "$(pwd)/../../output/usr/bin"
cd ..


#git clone --branch r24 https://github.com/notaz/pcsx_rearmed.git
#cd pcsx_rearmed
#git submodule init
#git submodule update
#SDL_CONFIG=$SYSROOT/usr/local/bin/sdl-config ./configure --enable-neon --enable-threads --sound-drivers=sdl
