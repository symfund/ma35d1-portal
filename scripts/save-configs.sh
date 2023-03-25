#
# Nuvoton (C) 2023 twjiang@nuvoton.com
#
# A script auto saves user's custom configs (buildroot/kernel/uboot) 
# to the location defined by local.mk.
#
# Origin: 
# https://raw.githubusercontent.com/symfund/ma35d1-portal/master/scripts/save-configs.sh
#
# Usage:
# put this script into ${BR2_DIR}/path/to/save-configs.sh
# change directory to ${BR2_DIR}, that is the root of Buildroot, run this script: 
#
# $ source ${BR2_DIR}/path/to/save-configs.sh
#

#!/bin/sh

# =============================================================================
# BLACK			0;30		DARK GRAY		1;30
# RED			0;31		LIGHT RED		1;31
# GREEN			0;32		LIGHT GREEN		1;31
# =============================================================================

RED='\033[0;31m'
NCOLOR='\033[0m'	

CURDIR=$(pwd)
BR2_CONFIG=${CURDIR}/.config

#alias CONFIG_DIR='echo "."'
alias CONFIG_DIR='echo "$CURDIR"'
source ${CURDIR}/local.mk

if ! test -f "${CURDIR}/local.mk" ; then
	echo "local.mk is not existed!"
	return	
fi

mkdir -p ${CURDIR}/workspace/configs

if test -f "${BR2_CONFIG}" ; then
	BR2_DEFCONFIG_FILE=$(grep BR2_DEFCONFIG ${BR2_CONFIG} | cut -d'"' -f2)
	make savedefconfig BR2_DEFCONFIG=${BR2_DEFCONFIG_FILE}
	cp -f ${BR2_DEFCONFIG_FILE} ${CURDIR}/workspace/configs
	echo -e "${RED}>>> saved custom buildroot configuration file to ${BR2_DEFCONFIG_FILE}\n${NCOLOR}"
else
	echo "Buildroot has not yet been configured, please configure buildroot first!"
fi

if grep -Eq "^BR2_TARGET_UBOOT_USE_DEFCONFIG=y$" ${BR2_CONFIG}; then
	UBOOT_BOARD_DEFCONFIG_FILE=$(grep BR2_TARGET_UBOOT_BOARD_DEFCONFIG ${BR2_CONFIG} | cut -d'"' -f2)
	UBOOT_BOARD_DEFCONFIG_FULL_PATH=$UBOOT_OVERRIDE_SRCDIR/configs/${UBOOT_BOARD_DEFCONFIG_FILE}_defconfig
	sed -i -e 's/BR2_TARGET_UBOOT_USE_DEFCONFIG=y/# BR2_TARGET_UBOOT_USE_DEFCONFIG is not set/' -i ${BR2_CONFIG}
	sed -i -e 's/# BR2_TARGET_UBOOT_USE_CUSTOM_CONFIG is not set/BR2_TARGET_UBOOT_USE_CUSTOM_CONFIG=y/' -i ${BR2_CONFIG}
	sed -i "/^BR2_TARGET_UBOOT_BOARD_DEFCONFIG=.*/c\BR2_TARGET_UBOOT_CUSTOM_CONFIG_FILE=\"${UBOOT_BOARD_DEFCONFIG_FULL_PATH}\"" -i ${BR2_CONFIG}

	make uboot-update-defconfig
	cp -f $UBOOT_BOARD_DEFCONFIG_FULL_PATH ${CURDIR}/workspace/configs
	echo -e "${RED}>>> saved custom uboot configuration file to $UBOOT_BOARD_DEFCONFIG_FULL_PATH\n${NCOLOR}"	
	
	sed -i -e 's/^# BR2_TARGET_UBOOT_USE_DEFCONFIG.*/BR2_TARGET_UBOOT_USE_DEFCONFIG=y/' -i ${BR2_CONFIG}
        sed -i -e 's/^BR2_TARGET_UBOOT_USE_CUSTOM_CONFIG=y/# BR2_TARGET_UBOOT_USE_CUSTOM_CONFIG is not set/' -i ${BR2_CONFIG}
        sed -i "/^BR2_TARGET_UBOOT_CUSTOM_CONFIG_FILE=.*/c\BR2_TARGET_UBOOT_BOARD_DEFCONFIG=\"${UBOOT_BOARD_DEFCONFIG_FILE}\"" -i ${BR2_CONFIG}
fi

if grep -Eq "^BR2_LINUX_KERNEL_USE_DEFCONFIG=y$" ${BR2_CONFIG}; then
        LINUX_KERNEL_DEFCONFIG_FILE=$(grep BR2_LINUX_KERNEL_DEFCONFIG ${BR2_CONFIG} | cut -d'"' -f2)
        LINUX_KERNEL_DEFCONFIG_FULL_PATH=$LINUX_OVERRIDE_SRCDIR/arch/arm64/configs/${LINUX_KERNEL_DEFCONFIG_FILE}_defconfig
        sed -i -e 's/BR2_LINUX_KERNEL_USE_DEFCONFIG=y/# BR2_LINUX_KERNEL_USE_DEFCONFIG is not set/' -i ${BR2_CONFIG}
        sed -i -e 's/# BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG is not set/BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG=y/' -i ${BR2_CONFIG}
        sed -i "/^BR2_LINUX_KERNEL_DEFCONFIG=.*/c\BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE=\"${LINUX_KERNEL_DEFCONFIG_FULL_PATH}\"" -i ${BR2_CONFIG}

        make linux-update-defconfig
	cp -f ${LINUX_KERNEL_DEFCONFIG_FULL_PATH} ${CURDIR}/workspace/configs
	echo -e "${RED}>>> saved custom kernel configuration file to ${LINUX_KERNEL_DEFCONFIG_FULL_PATH}\n${NCOLOR}"

        sed -i -e 's/^# BR2_LINUX_KERNEL_USE_DEFCONFIG.*/BR2_LINUX_KERNEL_USE_DEFCONFIG=y/' -i ${BR2_CONFIG}
        sed -i -e 's/^BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG=y/# BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG is not set/' -i ${BR2_CONFIG}
        sed -i "/^BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE=.*/c\BR2_LINUX_KERNEL_DEFCONFIG=\"${LINUX_KERNEL_DEFCONFIG_FILE}\"" -i ${BR2_CONFIG}
fi
