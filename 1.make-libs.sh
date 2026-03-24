#/bin/sh

set -e
export NUM_THREAD=8

cd $(pwd)/project
source set_env.sh
rm -rf zlib-1.2.8
tar xvf zlib-1.2.8.tar.xz
cd zlib-1.2.8
./configure
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..
rm -rf freetype-2.5.5
tar xvjf freetype-2.5.5.tar.bz2
cd freetype-2.5.5
./configure --host=arm-linux-gnueabihf --build=$(gcc -dumpmachine)
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..
rm -rf alsa-lib-1.2.9
tar xvjf alsa-lib-1.2.9.tar.bz2
cd alsa-lib-1.2.9
./configure --host=arm-linux-gnueabihf --enable-shared --disable-python
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..
cd SDL-1.2
chmod +x configure
./configure --host=arm-linux-gnueabihf --disable-video-opengl --disable-video-x11 --disable-video-wayland --enable-video-fbcon --enable-joystick --enable-audio
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
