#/bin/sh

set -e
export NUM_THREAD="$(nproc)"

cd "$(pwd)/project"
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

rm -rf tslib
git clone https://github.com/libts/tslib.git
cd tslib
./autogen.sh
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
# Drop libtool archives before SDL_image links against SDL to avoid absolute
# dependency paths like /usr/local/lib/libts.la leaking out of DESTDIR installs.
find "$SYSROOT" -name "*.la" -delete
cd ..

rm -rf SDL_image-release-1.2.12
unzip sdl_image-1.2.zip
cd SDL_image-release-1.2.12
./configure --host=arm-linux-gnueabihf --build=$(gcc -dumpmachine)
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

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
./configure --host=arm-linux-gnueabihf --build=$(gcc -dumpmachine)
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

rm -rf SDL_gfx
git clone https://github.com/ferzkopp/SDL_gfx.git
cd SDL_gfx
./configure --host=arm-linux-gnueabihf --build=$(gcc -dumpmachine) --disable-mmx
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

rm -rf rapidjson-1.1.0
unzip rapidjson-1.1.0.zip
cp -rf rapidjson-1.1.0/include/rapidjson $SYSROOT/usr/include


#boost
rm -rf boost
git clone -b boost-1.87.0 --depth 1 https://github.com/boostorg/boost.git
cd boost
git submodule init
git submodule update
PATH=/usr/bin:/bin ./bootstrap.sh --with-libraries=filesystem,locale --with-toolset=gcc
echo "using gcc : arm : /home/chris/powkiddy/sysroot/bin/arm-linux-gnueabihf-g++ ;" >> project-config.jam
./b2 toolset=gcc-arm architecture=arm target-os=linux link=static      --with-filesystem --with-locale      cxxflags="-std=c++11 -march=armv7-a -mfpu=neon -mfloat-abi=hard --sysroot=/home/chris/powkiddy-X39-X45-X51-X70-cfw/sysroot"      stage
./b2 headers
./b2 toolset=gcc-arm architecture=arm target-os=linux link=static,shared --with-filesystem --with-locale cxxflags="-std=c++11 --sysroot=/home/chris/powkiddy-X39-X45-X51-X70-cfw/sysroot" --prefix=/home/chris/powkiddy-X39-X45-X51-X70-cfw/sysroot/usr install

cd ..
rm -rf tiff-4.6.0
wget https://download.osgeo.org/libtiff/tiff-4.6.0.tar.gz
tar xf tiff-4.6.0.tar.gz
cd tiff-4.6.0
./configure --host=arm-linux-gnueabihf --build=$(gcc -dumpmachine)
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

cd ..
rm -rf tiff-4.0.10
wget https://download.osgeo.org/libtiff/tiff-4.0.10.tar.gz
tar xf tiff-4.0.10.tar.gz
cd tiff-4.0.10
./configure --host=arm-linux-gnueabihf --build=$(gcc -dumpmachine)
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

rm -rf libwebp-1.2.4
wget https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.2.4.tar.gz
tar xf libwebp-1.2.4.tar.gz
cd libwebp-1.2.4
./configure --host=arm-linux-gnueabihf --build=$(gcc -dumpmachine) --enable-neon
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

rm -rf libmad-0.15.1b
wget https://downloads.sourceforge.net/mad/libmad-0.15.1b.tar.gz
tar xf libmad-0.15.1b.tar.gz
cd libmad-0.15.1b
./configure --host=arm-linux-gnueabihf --build=$(gcc -dumpmachine)
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
