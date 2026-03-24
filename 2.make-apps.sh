#/bin/sh

set -e
export NUM_THREAD=8

cd $(pwd)/project
source set_env.sh

cd RetroArch
make -j$NUM_THREAD -f Makefile.powkiddy

