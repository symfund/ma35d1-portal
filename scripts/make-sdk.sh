#!/bin/sh

#
# Nuvoton (C) 2023
#

CURDIR=$(pwd)
BR2_CONFIG=${CURDIR}/.config

BR2_SYSTEM_BIN_SH_BUSYBOX=
BR2_SYSTEM_BIN_SH=

if grep -Eq "^BR2_SYSTEM_BIN_SH_BUSYBOX=y$" ${BR2_CONFIG}
then
        BR2_SYSTEM_BIN_SH_BUSYBOX=y
fi

if grep -Eq "^BR2_SYSTEM_BIN_SH_BASH=y$" ${BR2_CONFIG}
then
	BR2_SYSTEM_BIN_SH_BASH=y
	BR2_SYSTEM_BIN_SH="bash"
fi

if grep -Eq "^BR2_SYSTEM_BIN_SH_DASH=y$" ${BR2_CONFIG}
then
	BR2_SYSTEM_BIN_SH_DASH=y
	BR2_SYSTEM_BIN_SH="dash"
fi

if grep -Eq "^BR2_SYSTEM_BIN_SH_MKSH=y$" ${BR2_CONFIG}
then
	BR2_SYSTEM_BIN_SH_MKSH=y
	BR2_SYSTEM_BIN_SH="mksh"
fi

if grep -Eq "^BR2_SYSTEM_BIN_SH_ZSH=y$" ${BR2_CONFIG}
then
	BR2_SYSTEM_BIN_SH_ZSH=y
	BR2_SYSTEM_BIN_SH="zsh"
fi

sed -i -e 's/BR2_INIT_BUSYBOX=y/# BR2_INIT_BUSYBOX is not set/' -i ${BR2_CONFIG}
sed -i -e 's/# BR2_INIT_NONE is not set/BR2_INIT_NONE=y/' -i ${BR2_CONFIG}
sed -i -e 's/# BR2_SYSTEM_BIN_SH_NONE is not set/BR2_SYSTEM_BIN_SH_NONE=y/' -i ${BR2_CONFIG}
sed -i -e 's/BR2_PACKAGE_BUSYBOX=y/# BR2_PACKAGE_BUSYBOX is not set/' -i ${BR2_CONFIG}
sed -i -e 's/BR2_TARGET_ROOTFS_TAR=y/# BR2_TARGET_ROOTFS_TAR is not set/' -i ${BR2_CONFIG}

make olddefconfig

make sdk

sed -i -e 's/# BR2_INIT_BUSYBOX is not set/BR2_INIT_BUSYBOX=y/' -i ${BR2_CONFIG}
sed -i -e 's/BR2_INIT_NONE=y/# BR2_INIT_NONE is not set/' -i ${BR2_CONFIG}
sed -i -e 's/BR2_SYSTEM_BIN_SH_NONE=y/# BR2_SYSTEM_BIN_SH_NONE is not set/' -i ${BR2_CONFIG}
sed -i -e 's/# BR2_PACKAGE_BUSYBOX is not set/BR2_PACKAGE_BUSYBOX=y/' -i ${BR2_CONFIG}
sed -i -e 's/# BR2_TARGET_ROOTFS_TAR is not set/BR2_TARGET_ROOTFS_TAR=y/' -i ${BR2_CONFIG}

if test -z "$BR2_SYSTEM_BIN_SH_BUSYBOX"
then
	case "$BR2_SYSTEM_BIN_SH" in
		bash)
			sed -i -e '/# BR2_SYSTEM_BIN_SH_NONE is not set/a BR2_SYSTEM_BIN_SH="bash"' -i ${BR2_CONFIG}
			sed -i -e 's/# BR2_SYSTEM_BIN_SH_BASH is not set/BR2_SYSTEM_BIN_SH_BASH=y/' -i ${BR2_CONFIG}
			;;
		dash)
                        sed -i -e '/# BR2_SYSTEM_BIN_SH_NONE is not set/a BR2_SYSTEM_BIN_SH="dash"' -i ${BR2_CONFIG}
                        sed -i -e 's/# BR2_SYSTEM_BIN_SH_DASH is not set/BR2_SYSTEM_BIN_SH_DASH=y/' -i ${BR2_CONFIG}
			;;
		mksh)
                        sed -i -e '/# BR2_SYSTEM_BIN_SH_NONE is not set/a BR2_SYSTEM_BIN_SH="mksh"' -i ${BR2_CONFIG}
                        sed -i -e 's/# BR2_SYSTEM_BIN_SH_MKSH is not set/BR2_SYSTEM_BIN_SH_MKSH=y/' -i ${BR2_CONFIG}
			;;
		zsh)
                        sed -i -e '/# BR2_SYSTEM_BIN_SH_NONE is not set/a BR2_SYSTEM_BIN_SH="zsh"' -i ${BR2_CONFIG}
                        sed -i -e 's/# BR2_SYSTEM_BIN_SH_ZSH is not set/BR2_SYSTEM_BIN_SH_ZSH=y/' -i ${BR2_CONFIG}
			;;
		*)
			;;
	esac
fi

make olddefconfig
