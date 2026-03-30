#/bin/sh

set -e
export NUM_THREAD=8

cd $(pwd)/project
source set_env.sh

git clone https://github.com/libretro/libretro-super.git
cd libretro-super
./libretro-fetch.sh gambatte
platform=classic_armv7_a7 ./libretro-build.sh gambatte
