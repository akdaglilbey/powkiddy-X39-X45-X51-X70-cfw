set -e
export NUM_THREAD="$(nproc)"

cd "$(pwd)/project"
source set_env.sh
export LIBRETRO="$(pwd)/libretro-super"
export OUTPUT_CORES="$(pwd)/../output-sd/cfw/retroarch/cores/"

rm -rf fake-08
git clone -b rg35xx-libretro --depth 1 https://github.com/jtothebell/fake-08.git
cd fake-08
git submodule init
git submodule update
sed -i 's/CC = arm-linux-gnueabihf-gcc/#CC = arm-linux-gnueabihf-gcc/g; s/CXX = arm-linux-gnueabihf-g++/#CXX = arm-linux-gnueabihf-g++/g; s/AR = arm-linux-gnueabihf-ar/#AR = arm-linux-gnueabihf-ar/g; s/STRIP = arm-linux-gnueabihf-strip/#STRIP = arm-linux-gnueabihf-strip/g; s/, miyoomini/, powkiddy/g; s/_libretro_miyoomini.so/_libretro.so/g; s/CXXFLAGS += -marm -mtune=cortex-a7/CFLAGS += -DLUA_USE_MKSTEMP -D_NEED_FULL_PATH_   #CXXFLAGS += -marm -mtune=cortex-a7/g;' platform/libretro/Makefile
platform=powkiddy make -j$NUM_THREAD -C platform/libretro
find . -type f \( -name "*.so" -o -name "*.so" \) -exec cp -t $OUTPUT_CORES {} +
cd ..

rm -rf BennuGD_libretro
git clone https://github.com/diekleinekuh/BennuGD_libretro.git
cd BennuGD_libretro
mkdir build
cd build
cmake -DCMAKE_SYSROOT=$SYSROOT -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=arm -DCMAKE_C_COMPILER=$PATHGCC/$ARMABI-gcc -DCMAKE_CXX_COMPILER=$PATHGCC/$ARMABI-g++ -DCMAKE_FIND_ROOT_PATH=$SYSROOT -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="$CFLAGS" -DPNG_ARM_NEON=off ..
make -j$NUM_THREAD
find . -type f \( -name "*.so" -o -name "*.so" \) -exec cp -t $OUTPUT_CORES {} +
cd ../..

### JAVA for free2jme and free2jme-plus
wget https://cdn.azul.com/zulu-embedded/bin/zulu11.70.15-ca-jre11.0.22-linux_aarch32hf.tar.gz
tar xvzf zulu11.70.15-ca-jre11.0.22-linux_aarch32hf.tar.gz
rm -rf $(pwd)/../output-sd/cfw/java
mv zulu11.70.15-ca-jre11.0.22-linux_aarch32hf $(pwd)/../output-sd/cfw/java

cat > $(pwd)/../output-sd/cfw/java/lib/fontconfig.properties << 'EOF'
version=1
sequence.allfonts=default
fonts.default=DejaVu Sans
EOF

rm -rf zulu11.70.15-ca-jre11.0.22-linux_aarch32hf.tar.gz

rm -rf freej2me-plus
git clone -b v1.52 --depth 1 https://github.com/TASEmulators/freej2me-plus.git
cd freej2me-plus
git apply ../freej2me-plus_fix_java8_settings_default_options.patch
ant
rm -rf $OUTPUT_CORES/../../resources/freej2me-plus
mkdir $OUTPUT_CORES/../../resources/freej2me-plus
cp build/*.jar $OUTPUT_CORES/../../resources/freej2me-plus
cd src/libretro
make
mv freej2me_libretro.so $OUTPUT_CORES/../../resources/freej2me-plus

cd ../../..

rm -rf freej2me
git clone https://github.com/hex007/freej2me.git
cd freej2me
sed -i 's/<javac/<javac source="8" target="8"/g;' build.xml
ant
rm -rf $OUTPUT_CORES/../../resources/freej2me
mkdir $OUTPUT_CORES/../../resources/freej2me
cp build/*.jar $OUTPUT_CORES/../../resources/freej2me
cd src/libretro
sed -i 's/{ port_1, 16 }/{ port_1, 2 }/' freej2me_libretro.h
make
mv freej2me_libretro.so $OUTPUT_CORES/../../resources/freej2me

cd ../../..

build_core_custom() {
	core_name="$1"
	./libretro-fetch.sh "$core_name"
	cd "libretro-$1"
	git reset --hard
	if [ -n "$3" ]; then
		cd $3
	fi
	sed -i 's/-O3/-Os/g; s/-O2/-Os/g; s/-mtune=cortex-a7//g; s/-mfpu=neon-vfpv4//g; s/-mfloat-abi=hard//g; s/-march=armv7-a//g; s/-march=armv7ve//g; s/-static-libgcc//g; s/-static-libstdc++//g; s/-flto=4//g; s/-fwhole-program//g; s/$(findstring armv,$(platform)/$(findstring armv8,$(platform)/g;' $2
	platform=classic_armv7_a7 make -f $2 clean
	if [ -n "$4" ]; then
		make -f "$2" platform=classic_armv7_a7 -j"$NUM_THREAD" LDFLAGS+="$4"
	else
		make -f "$2" platform=classic_armv7_a7 -j"$NUM_THREAD"
	fi
	cd "$LIBRETRO"
}
build_core_custom_folder() {
	core_name="$1"
	./libretro-fetch.sh "$core_name"
	cd "$3"
	git reset --hard
	sed -i 's/-O3/-Os/g; s/-O2/-Os/g; s/-mtune=cortex-a7//g; s/-mfpu=neon-vfpv4//g; s/-mfloat-abi=hard//g; s/-march=armv7-a//g; s/-march=armv7ve//g; s/-static-libgcc//g; s/-static-libstdc++//g; s/-flto=4//g; s/-fwhole-program//g; s/$(findstring armv,$(platform)/$(findstring armv8,$(platform)/g;' $2
	platform=classic_armv7_a7 make -f $2 clean
	if [ -n "$4" ]; then
		make -f "$2" platform=classic_armv7_a7 -j"$NUM_THREAD" $4
	else
		make -f "$2" platform=classic_armv7_a7 -j"$NUM_THREAD"
	fi
	cd "$LIBRETRO"
}
build_core_custom_platform() {
	core_name="$1"
	./libretro-fetch.sh "$core_name"
	cd "libretro-$1"
	git reset --hard
	if [ -n "$3" ]; then
		cd $3
	fi
	sed -i 's/-O3/-Os/g; s/-O2/-Os/g; s/-mtune=cortex-a7//g; s/-mfpu=neon-vfpv4//g; s/-mfloat-abi=hard//g; s/-march=armv7-a//g; s/-march=armv7ve//g; s/-static-libgcc//g; s/-static-libstdc++//g; s/-flto=4//g; s/-fwhole-program//g; s/$(findstring armv,$(platform)/$(findstring armv8,$(platform)/g; s/-march=armv8-a//g;' $2
	if [ -n "$4" ]; then
		if [ -n "$5" ]; then
			platform=$4 make -f $2 clean
			platform=$4 make -f $2 -j$NUM_THREAD $5
		else
			platform=$4 make -f $2 clean
			platform=$4 make -f $2 -j$NUM_THREAD
		fi
	else
		make -f $2 clean
		make -f $2 -j$NUM_THREAD
	fi
	cd "$LIBRETRO"
}

build_core() {
	build_core_custom $1 Makefile.libretro
}

build_core_simple() {
	build_core_custom $1 Makefile
}


rm -rf libretro-super
git clone https://github.com/libretro/libretro-super.git
cd "$LIBRETRO"
build_core 2048
build_core_simple mrboom
build_core_simple prboom
build_core gambatte
build_core_custom gearboy Makefile platforms/libretro/
build_core_simple gpsp
build_core mgba
build_core_simple tgbdual
build_core_custom vbam Makefile src/libretro
build_core fceumm
build_core_custom nestopia Makefile libretro
build_core_simple quicknes
build_core_simple snes9x2002
build_core_simple snes9x2005
build_core snes9x2010
build_core_custom snes9x Makefile libretro
build_core picodrive
build_core pcsx_rearmed
build_core_simple mame2000
build_core_simple mame2003
build_core_simple mame2003_plus
build_core_custom fbalpha2012 makefile.libretro svn-current/trunk
build_core_simple mednafen_ngp
build_core_simple mednafen_vb
build_core_simple freeintv
build_core_simple mednafen_lynx
build_core_custom_folder vice_xvic Makefile libretro-vice "EMUTYPE=xvic"
build_core_custom_folder vice_x64 Makefile libretro-vice "EMUTYPE=x64"
build_core_custom_platform uae4arm Makefile .
build_core_simple atari800
build_core_simple bluemsx
build_core_custom_platform cap32 Makefile . rg35xx "CROSS_COMPILE=$PATHGCC/$ARMABI-"
build_core_simple freechaf
build_core fuse
build_core gw
build_core_simple handy
build_core_simple mednafen_pce_fast
build_core_simple mednafen_supergrafx
build_core_simple mednafen_pce_fast
build_core_simple mednafen_wswan
build_core_simple o2em
build_core pokemini
build_core_simple prosystem
build_core_custom puae2021 Makefile . "-ldl -lrt -lm -lpthread"
build_core_simple dosbox_pure
build_core_custom scummvm Makefile backends/platform/libretro
build_core_custom_platform vecx Makefile.libretro . classic_armv7_a7 "HAS_GPU=0"
build_core_simple stella2014
build_core_custom fbneo Makefile src/burner/libretro "-pthread -lrt"
mv libretro-fbneo/src/burner/libretro/fbneo_libretro.so libretro-fbneo/src/burner/libretro/fbneo_new_libretro.so


./libretro-fetch.sh genesis_plus_gx
./libretro-build.sh genesis_plus_gx

wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/fbneo_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/tic80_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/puae_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix

./libretro-fetch.sh mednafen_pce
unset CPPFLAGS
unset CFLAGS
unset CCFLAGS
unset CXXFLAGS
CPPFLAGS="-Os $TARGET_ARCH_FLAGS --sysroot=$SYSROOT -I$SYSROOT/usr/include" ./libretro-build.sh mednafen_pce

# delete cores from output to avoid error during copy at the end of the script
rm -rf dist/unix/mednafen_pce_libretro.so
rm -rf dist/unix/genesis_plus_gx_libretro.so

# copy bluemsx and scummvm data files to output-sd
cp libretro-bluemsx/system/bluemsx/* $OUTPUT_CORES/../system/ -rf
mkdir $OUTPUT_CORES/../system/scummvm
cp libretro-scummvm/dists/engine-data/* $OUTPUT_CORES/../system/scummvm -rf

find . -type f \( -name "*.so" -o -name "*.so" \) -exec cp -t $OUTPUT_CORES {} +

### not working or bad performances or old stuff

#git clone https://github.com/schellingb/dosbox-pure.git
#cd dosbox-pure
#platform=classic_armv7_a7 make -j$NUM_THREAD
#cp dosbox_pure_libretro.so $(pwd)/../../output-sd/cfw/retroarch/cores/
#cd ..


#download cores from buildbot
#wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/atari800_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
#wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/bluemsx_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
#wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/cap32_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
#wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/freechaf_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
#wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/fuse_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
#wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/gw_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
#wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/handy_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
#wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/mednafen_pce_fast_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
#wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/mednafen_pce_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
#wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/mednafen_supergrafx_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
#wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/mednafen_wswan_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
#wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/o2em_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
#wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/pokemini_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
#wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/prosystem_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix

#wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/scummvm_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
#wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/vecx_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
#./libretro-fetch.sh tic80
#./libretro-build.sh tic80
#build_core_simple retro8
