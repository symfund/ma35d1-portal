#!/bin/sh

#
# Nuvoton (C) 2023 twjiang@nuvoton.com
#

rm -rf output/target
find output/ -name ".stamp_target_installed" | xargs rm -rf

make host-gcc-final-rebuild

rm -rf output/images
make arm-trusted-firmware-dirclean uboot-dirclean optee-os-dirclean linux-dirclean

time make
