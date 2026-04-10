#!/bin/sh
arm-linux-gnueabihf-strip --strip-unneeded output-sd/cfw/lib/*.so*
arm-linux-gnueabihf-strip --strip-unneeded output-sd/cfw/retroarch/cores/*.so*
