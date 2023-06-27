#!/bin/sh

#
# Nuvoton (C) 2023 twjiang@nuvoton.com
#
# A script updates the sources for buildroot, uboot, linux, tf-a and optee-os.
#
# Usage:
# put this script into /path/to/update-sources.sh
# change directory to ${BR2_DIR}, that is the root of Buildroot, run this script: 
#
# $ source /path/to/update-sources.sh
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

if ! test -f "${CURDIR}/local.mk" ; then
	echo "local.mk is not existed!"
	return	
fi

tmpfile="$(mktemp /tmp/makefile.XXXXXXXX.tmp)" || { echo "Failed to create a temp file"; exit 1; }
make -pn -f Makefile > ${tmpfile} 2>/dev/null
while read var assign value; do
        if [[ ${var} = 'UBOOT_OVERRIDE_SRCDIR' ]] && [[ ${assign} = '=' ]]; then
                UBOOT_OVERRIDE_SRCDIR="$value"
        fi

        if [[ ${var} = 'LINUX_OVERRIDE_SRCDIR' ]] && [[ ${assign} = '=' ]]; then
                LINUX_OVERRIDE_SRCDIR="$value"
        fi

        if [[ ${var} = 'CONFIG_DIR' ]] && [[ ${assign} = ':=' ]]; then
                CONFIG_DIR="$value"
        fi

        if [[ ${var} = 'TOPDIR' ]] && [[ ${assign} = ':=' ]]; then
                TOPDIR="$value"
        fi
done </${tmpfile}
rm -Rf ${tmpfile}

echo "UBOOT_OVERRIDE_SRCDIR = ${UBOOT_OVERRIDE_SRCDIR}"
echo "LINUX_OVERRIDE_SRCDIR = ${LINUX_OVERRIDE_SRCDIR}"
echo "CONFIG_DIR = ${CONFIG_DIR}"
echo "TOPDIR = ${TOPDIR}"

# Update buildroot
if [ ! -d ".git" ] ; then
	echo -e "${YELLOW}The source code of buildroot is not controlled by a git repository!${NCOLOR}"
	cd ${CURDIR}
	return
else
	until git pull origin master ; do echo -e "${YELLOW}failed to update buildroot repository, retry ...${NCOLOR}" ; done
	echo -e "${RED}update buildroot repository succeeded.${NCOLOR}"
fi

# Update Linux
if [[ ! -z "${LINUX_OVERRIDE_SRCDIR}" ]] ; then
	cd ${LINUX_OVERRIDE_SRCDIR}
	if [ ! -d ".git" ] ; then
        	echo -e "${YELLOW}The source code of linux is not controlled by a git repository!${NCOLOR}"
        	cd ${CURDIR}
        	return
	else
        	until git pull origin master; do echo -e "${YELLOW}failed to update linux repository, retry ...${NCOLOR}" ; done
        	echo -e "${RED}update linux repository succeeded.${NCOLOR}"
	fi
fi

# Update U-Boot
if [[ ! -z "${UBOOT_OVERRIDE_SRCDIR}" ]] ; then
	cd ${UBOOT_OVERRIDE_SRCDIR}
	if [ ! -d ".git" ] ; then
        	echo -e "${YELLOW}The source code of uboot is not controlled by a git repository!${NCOLOR}"
        	cd ${CURDIR}
        	return
	else
        	until git pull origin master; do echo -e "${YELLOW}failed to update uboot repository, retry ...${NCOLOR}" ; done
        	echo -e "${RED}update uboot repository succeeded.${NCOLOR}"
	fi
fi

# Update TF-A
if [[ ! -z "${ARM_TRUSTED_FIRMWARE_OVERRIDE_SRCDIR}" ]] ; then
	cd ${ARM_TRUSTED_FIRMWARE_OVERRIDE_SRCDIR}
	if [ ! -d ".git" ] ; then
		echo -e "${YELLOW}The source code of tf-a is not controlled by a git repository!${NCOLOR}"
		cd ${CURDIR}
		return
	else
        	until git pull origin master; do echo -e "${YELLOW}failed to update tf-a repository, retry ...${NCOLOR}" ; done
        	echo -e "${RED}update tf-a repository succeeded.${NCOLOR}"
	fi
fi

# Update optee-os
if [[ ! -z "${OPTEE_OS_OVERRIDE_SRCDIR}" ]] ; then
	cd ${OPTEE_OS_OVERRIDE_SRCDIR}
	if [ ! -d ".git" ] ; then
		echo -e "${YELLOW}The source code of optee-os is not controlled by a git repository!${NCOLOR}"
		cd ${CURDIR}
		return
	else
        	until git pull origin master; do echo -e "${YELLOW}failed to update optee-os repository, retry ...${NCOLOR}" ; done
        	echo -e "${RED}update optee-os repository succeeded.${NCOLOR}"
	fi
fi

cd ${CURDIR}
