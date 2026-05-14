#/bin/sh

set -e
export NUM_THREAD="$(nproc)"

cd "$(pwd)/project"
source set_env.sh

git clone https://github.com/libretro/libretro-super.git
cd libretro-super
./libretro-fetch.sh 2048
platform=classic_armv7_a7 ./libretro-build.sh 2048
./libretro-fetch.sh mrboom
platform=classic_armv7_a7 ./libretro-build.sh mrboom
./libretro-fetch.sh prboom
platform=classic_armv7_a7 ./libretro-build.sh prboom
./libretro-fetch.sh gambatte
platform=classic_armv7_a7 ./libretro-build.sh gambatte
./libretro-fetch.sh gearboy
platform=classic_armv7_a7 ./libretro-build.sh gearboy
./libretro-fetch.sh gpsp
platform=classic_armv7_a7 ./libretro-build.sh gpsp
./libretro-fetch.sh mgba
platform=classic_armv7_a7 ./libretro-build.sh mgba
./libretro-fetch.sh tgbdual
platform=classic_armv7_a7 ./libretro-build.sh tgbdual
./libretro-fetch.sh vbam
platform=classic_armv7_a7 ./libretro-build.sh vbam
./libretro-fetch.sh fceumm
platform=classic_armv7_a7 ./libretro-build.sh fceumm
./libretro-fetch.sh nestopia
platform=classic_armv7_a7 ./libretro-build.sh nestopia
./libretro-fetch.sh quicknes
platform=classic_armv7_a7 ./libretro-build.sh quicknes
./libretro-fetch.sh snes9x2002
platform=classic_armv7_a7 ./libretro-build.sh snes9x2002
./libretro-fetch.sh snes9x2005
platform=classic_armv7_a7 ./libretro-build.sh snes9x2005
./libretro-fetch.sh snes9x2010
platform=classic_armv7_a7 ./libretro-build.sh snes9x2010
./libretro-fetch.sh snes9x
platform=classic_armv7_a7 ./libretro-build.sh snes9x
./libretro-fetch.sh mednafen_supafaust
platform=classic_armv7_a7 ./libretro-build.sh mednafen_supafaust
./libretro-fetch.sh genesis_plus_gx
platform=classic_armv7_a7 ./libretro-build.sh genesis_plus_gx
./libretro-fetch.sh picodrive
platform=classic_armv7_a7 ./libretro-build.sh picodrive
./libretro-fetch.sh pcsx_rearmed
platform=classic_armv7_a7 ./libretro-build.sh pcsx_rearmed
./libretro-fetch.sh fbneo
platform=classic_armv7_a7 ./libretro-build.sh fbneo
./libretro-fetch.sh mame2000
platform=classic_armv7_a7 ./libretro-build.sh mame2000
./libretro-fetch.sh mame2003
platform=classic_armv7_a7 ./libretro-build.sh mame2003
./libretro-fetch.sh mame2003_plus
platform=classic_armv7_a7 ./libretro-build.sh mame2003_plus
./libretro-fetch.sh fbalpha2012
platform=classic_armv7_a7 ./libretro-build.sh fbalpha2012
./libretro-fetch.sh mednafen_ngp
platform=classic_armv7_a7 ./libretro-build.sh mednafen_ngp
./libretro-fetch.sh mednafen_vb
platform=classic_armv7_a7 ./libretro-build.sh mednafen_vb

./libretro-fetch.sh freeintv
platform=classic_armv7_a7 ./libretro-build.sh freeintv

./libretro-fetch.sh mednafen_lynx
platform=classic_armv7_a7 ./libretro-build.sh mednafen_lynx

./libretro-fetch.sh retro8
CFLAGS+=" -DUSE_RGB565" platform=classic_armv7_a7 ./libretro-build.sh retro8

./libretro-fetch.sh vice_xvic
platform=classic_armv7_a7 ./libretro-build.sh vice_xvic -j"$NUM_THREAD"
./libretro-fetch.sh vice_x64
platform=classic_armv7_a7 ./libretro-build.sh vice_x64 -j"$NUM_THREAD"

#download cores from buildbot
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/atari800_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/bluemsx_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/cap32_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/freechaf_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/fuse_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/gw_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/handy_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/mednafen_pce_fast_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/mednafen_pce_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/mednafen_supergrafx_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/mednafen_wswan_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/o2em_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/pokemini_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/prosystem_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/puae_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/scummvm_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/tic80_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/vecx_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
# all cores are stored on SD Card
cp -rf dist/unix/* "$(pwd)/../../output-sd/cfw/retroarch/cores/"

cd ..
git clone https://github.com/schellingb/dosbox-pure.git
cd dosbox-pure
platform=classic_armv7_a7 make -j"$NUM_THREAD"
cp  dosbox_pure_libretro.so $(pwd)/../../output-sd/cfw/retroarch/cores/
