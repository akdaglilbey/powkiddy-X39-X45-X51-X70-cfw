#!/bin/sh
export SYSROOT="$(pwd)/../sysroot"
export PATHGCC=$SYSROOT/bin
#export PATHGCC=$SYSROOT/../gcc-7.5
export ARMABI=arm-linux-gnueabihf
export CC="$PATHGCC/$ARMABI-gcc --sysroot=$SYSROOT"
export CXX="$PATHGCC/$ARMABI-g++ --sysroot=$SYSROOT"
export AR="$PATHGCC/$ARMABI-ar"
export LD="$PATHGCC/$ARMABI-ld"
export RANLIB="$PATHGCC/$ARMABI-ranlib"
export STRIP="$PATHGCC/$ARMABI-strip"
export NM="$PATHGCC/$ARMABI-nm"

export PKG_CONFIG_LIBDIR=$SYSROOT/usr/local/lib/pkgconfig:$SYSROOT/usr/local/share/pkgconfig:$SYSROOT/usr/lib/pkgconfig
export PKG_CONFIG_SYSROOT_DIR=$SYSROOT
export PKG_CONFIG=/usr/bin/pkg-config
export PKG_CONFIG_PATH=
export PKG_CONF_PATH=

export DESTDIR=$SYSROOT

export TARGET_CPU="${TARGET_CPU:-cortex-a9}"
export TARGET_FPU="${TARGET_FPU:-neon}"
export TARGET_FLOAT_ABI="${TARGET_FLOAT_ABI:-hard}"
export TARGET_ARCH_FLAGS="-mcpu=cortex-a9 -mfpu=neon -mfloat-abi=hard"
export TARGET_OPT_FLAGS="-Os -pipe -ffast-math -funsafe-math-optimizations -fomit-frame-pointer"
export CPP_FLAGS="$TARGET_OPT_FLAGS $TARGET_ARCH_FLAGS --sysroot=$SYSROOT -I$SYSROOT/usr/include"

export LD_FLAGS="--sysroot=$SYSROOT -L$SYSROOT -L$SYSROOT/lib -L$SYSROOT/usr/lib -L$SYSROOT/usr/local/lib -L$SYSROOT/usr/include/sound"

export CPPFLAGS="$CPP_FLAGS"
export LDFLAGS="$LD_FLAGS"

export CFLAGS="$CPP_FLAGS"
export CCFLAGS="$CPP_FLAGS"
export CXXFLAGS="$CPP_FLAGS"

export INC_DIR="$CPP_FLAGS"
export LIB_DIR="$LD_FLAGS"

export CROSS_COMPILE=$ARMABI-

export SDL_CONFIG="$SYSROOT/usr/local/bin/sdl-config --prefix=$SYSROOT/usr/local"
export FREETYPE_CONFIG="$SYSROOT/usr/local/bin/freetype-config"
