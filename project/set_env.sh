#!/bin/sh

export SYSROOT=/home/chris/powkiddy/sysroot
export CC=arm-buildroot-linux-uclibcgnueabihf-gcc
export CXX=arm-buildroot-linux-uclibcgnueabihf-g++
export AR=arm-buildroot-linux-uclibcgnueabihf-ar
export LD=arm-buildroot-linux-uclibcgnueabihf-ld
export RANLIB=arm-buildroot-linux-uclibcgnueabihf-ranlib
export STRIP=arm-buildroot-linux-uclibcgnueabihf-strip

export PATH=/home/chris/powkiddy/buildroot-2015.02/output/host/usr/bin:$PATH

export PKG_CONFIG_LIBDIR=$SYSROOT/usr/local/lib/pkgconfig:$SYSROOT/usr/local/share/pkgconfig:$SYSROOT/usr/lib/pkgconfig
export PKG_CONFIG_PATH=/usr/bin/pkg-config
export PKG_CONFIG=$PKG_CONFIG_PATH
export PKG_CONF_PATH=$PKG_CONFIG_PATH

export DESTDIR=$SYSROOT

export LD_LIBRARY_PATH="$SYSROOT/usr/lib"

#export CPP_FLAGS="-O3 -mfpu=neon -mcpu=cortex-a9 -mfloat-abi=hard -pipe -ffast-math -funsafe-math-optimizations -fomit-frame-pointer --sysroot=$SYSROOT -I$SYSROOT/usr/include"
export CPP_FLAGS="-Os -pipe -ffast-math -funsafe-math-optimizations -fomit-frame-pointer --sysroot=$SYSROOT  -I$SYSROOT/usr/include"

export LD_FLAGS="-L$SYSROOT -L$SYSROOT/lib -L$SYSROOT/usr/lib -L$SYSROOT/usr/local/lib -L$SYSROOT/usr/include/sound"

export CPPFLAGS="$CPP_FLAGS"
export LDFLAGS="$LD_FLAGS"

export CFLAGS="$CPP_FLAGS"
export CCFLAGS="$CPP_FLAGS"
export CXXFLAGS="$CPP_FLAGS"

export INC_DIR="$CPP_FLAGS"
export LIB_DIR="$LD_FLAGS"

export ARMABI=arm-buildroot-linux-uclibcgnueabihf
export TOOLCHAIN_DIR=/home/chris/powkiddy/buildroot-2015.02/output/host/$ARMABI

export CROSS_COMPILE=$ARMABI-

export SDL_CONFIG=$TOOLCHAIN_DIR/sysroot/usr/bin/sdl-config
export FREETYPE_CONFIG=$TOOLCHAIN_DIR/sysroot/usr/bin/freetype-config

