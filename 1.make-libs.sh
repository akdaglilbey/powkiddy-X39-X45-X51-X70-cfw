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

rm -rf lpng1655
unzip lpng1655.zip
cd lpng1655
./configure --host=arm-linux-gnueabihf --build=$(gcc -dumpmachine) --enable-hardware-optimizations=yes --enable-arm-neon-api=yes
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

rm -rf jpeg-9c
tar xvzf jpeg-9c.tar.gz
cd jpeg-9c
./configure --host=arm-linux-gnueabihf --build=$(gcc -dumpmachine)
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
./configure --host=arm-linux-gnueabihf --disable-video-opengl --disable-video-x11 --enable-video-fbcon --enable-joystick --enable-audio --enable-arm-simd --enable-arm-neon --build=$(gcc -dumpmachine) --enable-rpath=no
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
#update pkg-config sdl because it's searching in rpath host libs...
sed -i 's|-Wl,-rpath,[^ ]*||; s|-lpthread|-lpthread -lasound|' $SYSROOT/usr/local/lib/pkgconfig/sdl.pc
cd ..

rm -rf SDL_image-release-1.2.12
unzip sdl_image-1.2.zip
cd SDL_image-release-1.2.12
./configure --host=arm-linux-gnueabihf --build=$(gcc -dumpmachine)
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

find $SYSROOT -name "*.la" -delete

rm -rf SDL_ttf
git clone -b SDL-1.2 --depth 1 https://github.com/libsdl-org/SDL_ttf.git
cd SDL_ttf
./configure --host=arm-linux-gnueabihf --build=$(gcc -dumpmachine)
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

rm -rf mpg123-1.33.4
tar xvjf mpg123-1.33.4.tar.bz2
cd mpg123-1.33.4
 ./configure ./configure --host=arm-linux-gnueabihf --build=$(gcc -dumpmachine) --with-cpu=arm_fpu  --with-network=none  --with-audio=sdl
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

rm -rf SDL_mixer
git clone -b SDL-1.2 --depth 1 https://github.com/libsdl-org/SDL_mixer.git
cd SDL_mixer
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..
