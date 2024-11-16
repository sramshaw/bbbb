#!/bin/bash
cd modules/u-boot
rm .config
echo PATH=$PATH
echo ARCH=$ARCH
echo CROSS_COMPILE=$CROSS_COMPILE
make am335x_evm_defconfig
make DEVICE_TREE=am335x-boneblack -j 20
