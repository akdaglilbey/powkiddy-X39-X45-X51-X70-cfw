#/bin/sh

set -e

./0.prepare.sh
./1.make-libs.sh
./2.make-apps.sh
./3.libretro-core.sh
./4.buildoutput.sh
./5.buildext3.sh
./6.strip-cores.sh

cd output-sd
7z a ../SuperX-v1.1.7z *