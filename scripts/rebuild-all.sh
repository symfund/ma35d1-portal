#!/bin/sh

RED_BACK_BLACK_FORE='\033[1;31;43m'
NCOLOR='\033[0m'

echo -e "${RED_BACK_BLACK_FORE}rebuild-all.sh is deprecated! Use build-package.sh instead.${NCOLOR}"

sleep 3

rm -rf output/target
find output/ -name ".stamp_target_installed" | xargs rm -rf

make host-gcc-final-rebuild

rm -rf output/images
make arm-trusted-firmware-dirclean uboot-dirclean optee-os-dirclean linux-dirclean

time make
