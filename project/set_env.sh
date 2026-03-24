#!/bin/sh

export SYSROOT=$(pwd)/../sysroot
export CC="arm-linux-gnueabihf-gcc --sysroot=$SYSROOT"
export CXX="arm-linux-gnueabihf-g++ --sysroot=$SYSROOT"
export AR=arm-linux-gnueabihf-ar
export LD=arm-linux-gnueabihf-ld
export RANLIB=arm-linux-gnueabihf-ranlib
export STRIP=arm-linux-gnueabihf-strip
export NM=arm-linux-gnueabihf-nm
export PATH=$SYSROOT/bin:$PATH

export PKG_CONFIG_LIBDIR=$SYSROOT/usr/local/lib/pkgconfig:$SYSROOT/usr/local/share/pkgconfig:$SYSROOT/usr/lib/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=$SYSROOT
export PKG_CONFIG_PATH=/usr/bin/pkg-config
export PKG_CONFIG=$PKG_CONFIG_PATH
export PKG_CONF_PATH=$PKG_CONFIG_PATH

export DESTDIR=$SYSROOT

export LD_LIBRARY_PATH="$SYSROOT/usr/lib"

#export CPP_FLAGS="-O3 -mfpu=neon -mcpu=cortex-a9 -mfloat-abi=hard -pipe -ffast-math -funsafe-math-optimizations -fomit-frame-pointer --sysroot=$SYSROOT -I$SYSROOT/usr/include"
export CPP_FLAGS="-Os -pipe -ffast-math  -mfpu=neon -mcpu=cortex-a9 -mfloat-abi=hard -funsafe-math-optimizations -fomit-frame-pointer --sysroot=$SYSROOT  -I$SYSROOT/usr/include"

export LD_FLAGS="--sysroot=$SYSROOT -L$SYSROOT -L$SYSROOT/lib -L$SYSROOT/usr/lib -L$SYSROOT/usr/local/lib -L$SYSROOT/usr/include/sound"

export CPPFLAGS="$CPP_FLAGS"
export LDFLAGS="$LD_FLAGS"

export CFLAGS="$CPP_FLAGS"
export CCFLAGS="$CPP_FLAGS"
export CXXFLAGS="$CPP_FLAGS"

export INC_DIR="$CPP_FLAGS"
export LIB_DIR="$LD_FLAGS"

export ARMABI=arm-linux-gnueabihf
export TOOLCHAIN_DIR=$SYSROOT/$ARMABI

export CROSS_COMPILE=$ARMABI-

export SDL_CONFIG="$SYSROOT/usr/local/bin/sdl-config --prefix=$SYSROOT/usr/local"
export FREETYPE_CONFIG="$SYSROOT/usr/local/bin/freetype-config"
