#!/bin/sh

# It is mandatory to run this script in the root of Buildroot.
# $ source /path/to/build-package.sh

CURDIR=$(pwd)
IMAGES_DIR=${CURDIR}/output/images
NUWRITER_DIR=${CURDIR}/board/nuvoton/ma35d1/nuwriter
HOST_DIR=${CURDIR}/output/host
BR2_CONFIG=${CURDIR}/.config

DTB_OFFSET=
PACK_DEVICE_JSON=
BOOT_DEVICE=

#
# dtb_list extracts the list of DTB files from BR2_LINUX_KERNEL_INTREE_DTS_NAME
# in ${BR_CONFIG}, then prints the corresponding list of file names for the
# genimage configuration file
#
dtb_list()
{
        local DTB_LIST="$(sed -n 's/^BR2_LINUX_KERNEL_INTREE_DTS_NAME="\([\/a-z0-9 \-]*\)"$/\1/p' ${BR2_CONFIG})"

        for dt in $DTB_LIST; do
                echo -n "`basename $dt`"
        done
}

#
# uboot_dtb_name extracts the SDARD size from BR2_TARGET_ROOTFS_EXT2_SIZE in
# ${BR_CONFIG}, then prints the baord corresponding file names
#
uboot_dtb_name()
{
        echo $(sed -n -e 's/^BR2_TARGET_UBOOT_BOARD_DEFCONFIG=/ /p' ${BR2_CONFIG} | sed 's/M/ /g' | sed 's/\"/ /g' | sed '/^$/d')
}

MACHINE="$(dtb_list)"
UBOOT_DTB_NAME=$(uboot_dtb_name)

if [[ $(echo $UBOOT_DTB_NAME | grep "spinand") != "" ]] ; then
	BOOT_DEVICE="spinand"
	PACK_DEVICE_JSON=${NUWRITER_DIR}/pack-spinand.json
elif [[ $(echo $UBOOT_DTB_NAME | grep "nand") != "" ]] ; then
	BOOT_DEVICE="nand"
	PACK_DEVICE_JSON=${NUWRITER_DIR}/pack-nand.json
else
	BOOT_DEVICE="sdcard"
	PACK_DEVICE_JSON=${NUWRITER_DIR}/pack-sdcard.json
fi

LINUX_DTB_OFFSET=$(${HOST_DIR}/bin/jq -r '.image[] | select(.file=="Image.dtb") | .offset' ${PACK_DEVICE_JSON})
LINUX_IMAGE_OFFSET=$(${HOST_DIR}/bin/jq -r '.image[] | select(.file=="Image") | .offset' ${PACK_DEVICE_JSON})

function pack_linux_dtb_json() {
	cat << EOF
{
  "image": [
    {
      "offset": "${LINUX_DTB_OFFSET}",
      "file": "Image.dtb",
      "type": 0
    }
  ]
}

EOF
}

function pack_linux_image_and_dtb_json() {
	cat << EOF
{
  "image": [
    {
      "offset": "${LINUX_DTB_OFFSET}",
      "file": "Image.dtb",
      "type": 0
    },
    {
      "offset": "${LINUX_IMAGE_OFFSET}",
      "file": "Image",
      "type": 0
    }
  ]
}

EOF
}


# -------> A clever way to rebuild packages in Buildroot <----------

usage()
{
echo -e "
=============================== USAGE ===================================================

Usage: $ source /path/to/build-package.sh package [command]
Usage:
	package -- the package name. Special packages are 'rootfs', 'dts' and 'all'
	command -- commands are 'rebuild', 'clean' and 'pack'. If command is not present,
	           it use the command 'clean'
	rebuild -- rebuild package without clean
	clean   -- clean then build package
	pack    -- packing the image for NuWriter

Usage: build uboot
	$ source /path/to/build-package.sh uboot

Usage: rebuild uboot
	$ source /path/to/build-package.sh uboot rebuild

Usage: clean then build uboot
	$ source /path/to/build-package.sh uboot clean
	
=========================================================================================
"
}

if test -z "$1" ; then
	echo "ERROR: missing package name"
	usage
	return 1
fi

if [[ "$1" == "rootfs" ]]; then
	if [[ "$2" == "clean" ]] || test -z "$2"; then
        	rm -Rf output/target
		find output/build -name ".stamp_target_installed" | xargs rm -Rf
		make host-gcc-final-rebuild
		make ; return
	fi

	if [[ "$2" == "rebuild" ]]; then
		make ; return
	fi

	echo "method '$2' not support"
	return
fi

if [[ "$1" == "all" ]]; then
        if [[ "$2" == "clean" ]] || test -z "$2"; then
                rm -Rf output/target output/images
                find output/build -name ".stamp_target_installed" | xargs rm -Rf
		make uboot-dirclean arm-trusted-firmware-dirclean host-uboot-tools-dirclean linux-dirclean optee-os-dirclean host-gcc-final-rebuild
                make ; return
        fi

        if [[ "$2" == "rebuild" ]]; then
		echo "rebuild all is not safe, do nothing" ; return
        fi

        echo "method '$2' not support"
        return
fi

# Only pack dts
if [[ "$1" == "dts" ]] && [[ "$2" == "pack" ]]; then
	rm -Rf output/images/${MACHINE}.dtb output/images/Image.dtb
	make linux-rebuild
	
	cd ${IMAGES_DIR}
	cp ${MACHINE}.dtb Image.dtb
	formal=$(pack_linux_dtb_json)
	echo "${formal}" > pack_dtb.json
	cat pack_dtb.json

	${HOST_DIR}/bin/nuwriter.py -p pack_dtb.json
	cp pack/pack.bin pack-linux-dtb-${MACHINE}-${BOOT_DEVICE}.bin
	rm -rf $(date "+%m%d-*") conv pack;
	rm -rf pack_dtb.json

	cd ${CURDIR}
	return
fi

# Pack linux and dts
if [[ "$1" == "linux" ]] && [[ "$2" == "pack" ]]; then
	rm -Rf output/images/${MACHINE}.dtb output/images/Image.dtb
	make linux-rebuild
	
	cd ${IMAGES_DIR}
	cp ${MACHINE}.dtb Image.dtb
	formal=$(pack_linux_image_and_dtb_json)
	echo "${formal}" > pack_linux_image_and_dtb.json
	cat pack_linux_image_and_dtb.json

	${HOST_DIR}/bin/nuwriter.py -p pack_linux_image_and_dtb.json
	cp pack/pack.bin pack-linux-image-and-dtb-${MACHINE}-${BOOT_DEVICE}.bin
	rm -rf $(date "+%m%d-*") conv pack;
	rm -rf pack_linux_image_and_dtb.json

	cd ${CURDIR}
	return
fi

echo "-----> The following packages depends on $1 <-----"
dependChains=$(make $1-show-recursive-rdepends)
make $1-show-recursive-rdepends
echo

for pkg in ${dependChains[@]}
do
	make $pkg-dirclean
done

if [[ "$2" == "clean" ]] || test -z "$2" ; then
	make $1-dirclean
fi

make $1-rebuild ; make

