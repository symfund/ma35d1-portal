#!/bin/sh

#
# Nuvoton (C) 2023 twjiang@nuvoton.com
#
# A script updates the sources for buildroot, uboot, linux, tf-a and optee-os.
#
# Usage:
# put this script into ${BR2_DIR}/path/to/update-sources.sh
# change directory to ${BR2_DIR}, that is the root of Buildroot, run this script: 
#
# $ source ${BR2_DIR}/path/to/update-sources.sh
#

# =============================================================================
# BLACK			0;30		DARK GRAY		1;30
# RED			0;31		LIGHT RED		1;31
# GREEN			0;32		LIGHT GREEN		1;32
# ORANGE		0;33		YELLOW			1;33
# =============================================================================

RED='\033[0;31m'
NCOLOR='\033[0m'	
YELLOW='\033[1;33m'

CURDIR=$(pwd)
BR2_CONFIG=${CURDIR}/.config

#alias CONFIG_DIR='echo "."'
alias CONFIG_DIR='echo "$CURDIR"'

if ! test -f "${CURDIR}/local.mk" ; then
	echo "local.mk is not existed!"
	return	
else
	source ${CURDIR}/local.mk
fi

# Update buildroot
until git pull origin master ; do echo -e "${YELLOW}failed to update buildroot repository, retry ...${NCOLOR}" ; done
echo -e "${RED}update buildroot repository succeeded.${NCOLOR}"

# Update Linux
cd ${LINUX_OVERRIDE_SRCDIR}
until git pull origin master; do echo -e "${YELLOW}failed to update linux repository, retry ...${NCOLOR}" ; done
echo -e "${RED}update linux repository succeeded.${NCOLOR}"

# Update U-Boot
cd ${$UBOOT_OVERRIDE_SRCDIR}
until git pull origin master; do echo -e "${YELLOW}failed to update uboot repository, retry ...${NCOLOR}" ; done
echo -e "${RED}update uboot repository succeeded.${NCOLOR}"

# Update TF-A
cd ${ARM_TRUSTED_FIRMWARE_OVERRIDE_SRCDIR}
until git pull origin master; do echo -e "${YELLOW}failed to update tf-a repository, retry ...${NCOLOR}" ; done
echo -e "${RED}update tf-a repository succeeded.${NCOLOR}"

# Update optee-os
cd ${OPTEE_OS_OVERRIDE_SRCDIR}
until git pull origin master; do echo -e "${YELLOW}failed to update optee-os repository, retry ...${NCOLOR}" ; done
echo -e "${RED}update optee-os repository succeeded.${NCOLOR}"

cd ${CURDIR}
