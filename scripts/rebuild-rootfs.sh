#!/bin/sh

#
# Nuvoton (C) 2023 twjiang@nuvoton.com
#
# When unselect some packages in Buildroot or decide to remove unwanted plenty of files from target rootfs file system,
# there is no such "rebuild" in Buildroot to save rebuild time, since the Buildroot build system is different from
# the traditional compiler infrastructure "make" facility.
#
# This script provided a workaround for rootfs rebuild. Put this script rebuild-rootfs.sh in /path/to/rebuild-rootfs.sh
# change directory to the root of Buildroot, run this script
# $ source /path/to/rebuild-rootfs.sh
#

rm -rf output/target
find output/ -name ".stamp_target_installed" | xargs rm -rf
make host-gcc-final-rebuild

make
