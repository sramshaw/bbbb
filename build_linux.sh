#!/bin/bash
cp defconfigs/linux-defconfig modules/linux/.config
cd modules/linux
echo PATH=$PATH
echo ARCH=$ARCH
echo CROSS_COMPILE=$CROSS_COMPILE
yes "" | make oldconfig
make -j 20
