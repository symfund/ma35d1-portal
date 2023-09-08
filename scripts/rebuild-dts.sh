#!/bin/sh

#
# Nuvoton (C) 2023 twjiang@nuvoton.com
#
# Avoid rebuilding whole Linux in case of enabling/disabling a device in DTS file
#
# Usage:
# Change directory to the root of Buildroot (${BR2_DIR}), run this script 
#
# $ source /path/to/rebuild-dts.sh
#

echo "rebuild-dts.sh is deprecated, use build-package.sh instead."
echo ""
echo "If only the linux device tree file is modified, pack only the device tree binary show below"
echo "$ source /path/to/build-package.sh dts pack"
echo ""
echo "If both the linux source file and device tree file are changed, pack both them show below"
echo "$ source /path/to/build-package.sh linux pack"
echo ""

return 

echo "================================================================================================="





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

rm -Rf output/images/${MACHINE}.dtb output/images/Image.dtb
make linux-rebuild

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

DTB_OFFSET=$(${HOST_DIR}/bin/jq -r '.image[] | select(.file=="Image.dtb") | .offset' ${PACK_DEVICE_JSON})
echo "DTB offset in ${BOOT_DEVICE} --> ${DTB_OFFSET}"

# Construct JSON
function pack_dtb_json() {
	cat << EOF
{
  "image": [
    {
      "offset": "${DTB_OFFSET}",
      "file": "Image.dtb",
      "type": 0
    }
  ]
}

EOF
}

cd ${IMAGES_DIR}
cp ${MACHINE}.dtb Image.dtb
formal=$(pack_dtb_json)
echo "${formal}" > pack_dtb.json
cat pack_dtb.json

${HOST_DIR}/bin/nuwriter.py -p pack_dtb.json
cp pack/pack.bin pack-dtb-${MACHINE}-${BOOT_DEVICE}.bin
rm -rf $(date "+%m%d-*") conv pack;
rm -rf pack_dtb.json

cd ${CURDIR}

