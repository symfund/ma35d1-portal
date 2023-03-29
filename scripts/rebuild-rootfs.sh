#!/bin/sh

#
# Nuvoton (C) 2023 twjiang@nuvoton.com
#
# When unselect some packages in Buildroot or want to remove unwanted files from rootfs, Buildroot does
# not support "rebuild" rootfs file system.
# This script is a workaround for that. Put this script rebuild-rootfs.sh in /path/to/rebuild-rootfs.sh
# change directory to the root of Buildroot, run this script
# $ source /path/to/rebuild-rootfs.sh
#

rm -rf output/target
find output/ -name ".stamp_target_installed" | xargs rm -rf
make host-gcc-final-rebuild

make
