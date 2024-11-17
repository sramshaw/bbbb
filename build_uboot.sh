#!/bin/bash
cp uboot-defconfig modules/u-boot/.config 
cd modules/u-boot
echo PATH=$PATH
echo ARCH=$ARCH
echo CROSS_COMPILE=$CROSS_COMPILE
yes "" | make oldconfig
make DEVICE_TREE=am335x-boneblack -j 20
