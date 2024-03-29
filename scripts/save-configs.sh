#!/bin/sh

#
# Nuvoton (C) 2023 twjiang@nuvoton.com
#
# A script auto saves user's custom configs (buildroot/kernel/uboot/busybox) 
# to the location defined by local.mk.
#
# Origin: 
# https://raw.githubusercontent.com/symfund/ma35d1-portal/master/scripts/save-configs.sh
#
# Usage:
# put this script into ${BR2_DIR}/path/to/save-configs.sh
# change directory to ${BR2_DIR}, that is the root of Buildroot, run this script: 
#
# $ source /path/to/save-configs.sh
#

# =============================================================================
# BLACK			0;30		DARK GRAY		1;30
# RED			0;31		LIGHT RED		1;31
# GREEN			0;32		LIGHT GREEN		1;31
# =============================================================================

RED='\033[0;31m'
NCOLOR='\033[0m'	

CURDIR=$(pwd)
BR2_CONFIG=${CURDIR}/.config

if ! test -f "${CURDIR}/local.mk" ; then
	echo "local.mk is not existed!"
	echo "If want to use relative path in local.mk, use $(CONFIG_DIR) or $(TOPDIR) instead."
	echo "$(CONFIG_DIR) is the root directory of buildroot."
	return	
fi

tmpfile="$(mktemp /tmp/makefile.XXXXXXXX.tmp)" || { echo "Failed to create a temp file"; exit 1; }
tmpdefs="$(mktemp /tmp/defsfile.XXXXXXXX.tmp)" || { echo "Failed to create a temp file"; exit 1; }
make -pn -f Makefile > ${tmpfile} 2>/dev/null
while read var assign value; do
        if [[ ${var} = 'UBOOT_OVERRIDE_SRCDIR' ]] && [[ ${assign} = '=' ]]; then
                echo "UBOOT_OVERRIDE_SRCDIR=$value" >>$tmpdefs
        fi

        if [[ ${var} = 'LINUX_OVERRIDE_SRCDIR' ]] && [[ ${assign} = '=' ]]; then
                echo "LINUX_OVERRIDE_SRCDIR=$value" >>$tmpdefs
        fi

        if [[ ${var} = 'CONFIG_DIR' ]] && [[ ${assign} = ':=' ]]; then
                config_dir=$value
        fi

        if [[ ${var} = 'TOPDIR' ]] && [[ ${assign} = ':=' ]]; then
                top_dir=$value
        fi
done </${tmpfile}
rm -Rf ${tmpfile}

alias CONFIG_DIR='echo "$config_dir"'
alias TOPDIR='echo "top_dir"'

source $tmpdefs ; rm -Rf $tmpdefs

echo "UBOOT_OVERRIDE_SRCDIR = ${UBOOT_OVERRIDE_SRCDIR}"
echo "LINUX_OVERRIDE_SRCDIR = ${LINUX_OVERRIDE_SRCDIR}"
echo "CONFIG_DIR = ${CONFIG_DIR}"
echo "TOPDIR = ${TOPDIR}"

ARCH=$(grep BR2_ARCH= ${BR2_CONFIG} | cut -d'"' -f2)
if [[ "$ARCH" == "aarch64" ]] ; then
	ARCH="arm64"
fi

if test -f "${BR2_CONFIG}" ; then
	BR2_DEFCONFIG_FILE=$(grep BR2_DEFCONFIG= ${BR2_CONFIG} | cut -d'"' -f2)
	make savedefconfig BR2_DEFCONFIG=${BR2_DEFCONFIG_FILE}
	echo -e "${RED}>>> saved custom buildroot configuration file to ${BR2_DEFCONFIG_FILE}\n${NCOLOR}"
else
	echo "Buildroot has not yet been configured, please configure buildroot first!"
fi

	# make uboot-savedefconfig

if grep -Eq "^BR2_TARGET_UBOOT_USE_DEFCONFIG=y$" ${BR2_CONFIG}; then
	UBOOT_BOARD_DEFCONFIG_FILE=$(grep BR2_TARGET_UBOOT_BOARD_DEFCONFIG ${BR2_CONFIG} | cut -d'"' -f2)
	UBOOT_BOARD_DEFCONFIG_FULL_PATH=$UBOOT_OVERRIDE_SRCDIR/configs/${UBOOT_BOARD_DEFCONFIG_FILE}_defconfig
	sed -i -e 's/BR2_TARGET_UBOOT_USE_DEFCONFIG=y/# BR2_TARGET_UBOOT_USE_DEFCONFIG is not set/' -i ${BR2_CONFIG}
	sed -i -e 's/# BR2_TARGET_UBOOT_USE_CUSTOM_CONFIG is not set/BR2_TARGET_UBOOT_USE_CUSTOM_CONFIG=y/' -i ${BR2_CONFIG}
	sed -i "/^BR2_TARGET_UBOOT_BOARD_DEFCONFIG=.*/c\BR2_TARGET_UBOOT_CUSTOM_CONFIG_FILE=\"${UBOOT_BOARD_DEFCONFIG_FULL_PATH}\"" -i ${BR2_CONFIG}

	make uboot-update-defconfig
	echo -e "${RED}>>> saved custom uboot configuration file to $UBOOT_BOARD_DEFCONFIG_FULL_PATH\n${NCOLOR}"	
	
	sed -i -e 's/^# BR2_TARGET_UBOOT_USE_DEFCONFIG.*/BR2_TARGET_UBOOT_USE_DEFCONFIG=y/' -i ${BR2_CONFIG}
        sed -i -e 's/^BR2_TARGET_UBOOT_USE_CUSTOM_CONFIG=y/# BR2_TARGET_UBOOT_USE_CUSTOM_CONFIG is not set/' -i ${BR2_CONFIG}
        sed -i "/^BR2_TARGET_UBOOT_CUSTOM_CONFIG_FILE=.*/c\BR2_TARGET_UBOOT_BOARD_DEFCONFIG=\"${UBOOT_BOARD_DEFCONFIG_FILE}\"" -i ${BR2_CONFIG}
fi

if grep -Eq "^BR2_TARGET_UBOOT_USE_CUSTOM_CONFIG=y$" ${BR2_CONFIG}; then
	UBOOT_CUSTOM_CONFIG_FILE=$(grep BR2_TARGET_UBOOT_CUSTOM_CONFIG_FILE= ${BR2_CONFIG} | cut -d '"' -f2)
	make uboot-update-defconfig
	echo -e "${RED}>>> saved custom uboot configuration file to ${UBOOT_CUSTOM_CONFIG_FILE}\n${NCOLOR}"
fi

	# make linux-savedefconfig

if grep -Eq "^BR2_LINUX_KERNEL_USE_DEFCONFIG=y$" ${BR2_CONFIG}; then
        LINUX_KERNEL_DEFCONFIG_FILE=$(grep BR2_LINUX_KERNEL_DEFCONFIG ${BR2_CONFIG} | cut -d'"' -f2)
        LINUX_KERNEL_DEFCONFIG_FULL_PATH=$LINUX_OVERRIDE_SRCDIR/arch/${ARCH}/configs/${LINUX_KERNEL_DEFCONFIG_FILE}_defconfig
        sed -i -e 's/BR2_LINUX_KERNEL_USE_DEFCONFIG=y/# BR2_LINUX_KERNEL_USE_DEFCONFIG is not set/' -i ${BR2_CONFIG}
        sed -i -e 's/# BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG is not set/BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG=y/' -i ${BR2_CONFIG}
        sed -i "/^BR2_LINUX_KERNEL_DEFCONFIG=.*/c\BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE=\"${LINUX_KERNEL_DEFCONFIG_FULL_PATH}\"" -i ${BR2_CONFIG}

        make linux-update-defconfig
	echo -e "${RED}>>> saved custom kernel configuration file to ${LINUX_KERNEL_DEFCONFIG_FULL_PATH}\n${NCOLOR}"

        sed -i -e 's/^# BR2_LINUX_KERNEL_USE_DEFCONFIG.*/BR2_LINUX_KERNEL_USE_DEFCONFIG=y/' -i ${BR2_CONFIG}
        sed -i -e 's/^BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG=y/# BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG is not set/' -i ${BR2_CONFIG}
        sed -i "/^BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE=.*/c\BR2_LINUX_KERNEL_DEFCONFIG=\"${LINUX_KERNEL_DEFCONFIG_FILE}\"" -i ${BR2_CONFIG}
fi

if grep -Eq "^BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG=y$" ${BR2_CONFIG}; then
	LINUX_KERNEL_CUSTOM_CONFIG_FILE=$(grep BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE= ${BR2_CONFIG} | cut -d '"' -f2)
	make linux-update-defconfig
	echo -e "${RED}>>> saved custom kernel configuration file to ${LINUX_KERNEL_CUSTOM_CONFIG_FILE}\n${NCOLOR}"	
fi

BUSYBOX_CUSTOM_CONFIG_FILE=$(grep BR2_PACKAGE_BUSYBOX_CONFIG= ${BR2_CONFIG} | cut -d '"' -f2)
make busybox-update-config
echo -e "${RED}>>> saved custom busybox configuration file to ${BUSYBOX_CUSTOM_CONFIG_FILE}\n${NCOLOR}"
