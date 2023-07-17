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



#################################################################################################################
#                                                                                                               #
# Create SDK self-installer                                                                                     #
#                                                                                                               #
#################################################################################################################


mkdir -p output/images/payload
mv output/images/aarch64-nuvoton-linux-gnu_sdk-buildroot.tar.gz output/images/payload

# creating a installer script
if [[ ! -f output/images/payload/installer.sh ]] ; then
	cat > output/images/payload/installer.sh <<_EOF_
#! /bin/sh

echo ""
echo "============================================================================================="
echo "Installing MA35D1 SDK into /usr/local/aarch64-nuvoton-linux-gnu_sdk-buildroot..."
echo "============================================================================================="
sudo tar xzvf ./aarch64-nuvoton-linux-gnu_sdk-buildroot.tar.gz -C /usr/local
/usr/local/aarch64-nuvoton-linux-gnu_sdk-buildroot/relocate-sdk.sh
echo ""
echo "============================================================================================="
echo "Before compiling source files, set up the build environment as shown below"
echo ""
echo "$ source /usr/local/aarch64-nuvoton-linux-gnu_sdk-buildroot/environment-setup"
echo ""
echo "============================================================================================="
echo ""

_EOF_

	chmod +x output/images/payload/installer.sh
fi

# decompress
if [[ ! -f output/images/decompress.sh ]]; then
	# prevent variable in heredoc from expanding
	cat > output/images/decompress.sh <<'_EOF_'
#! /bin/sh
echo ""
echo "Self Extracting Installer"
echo ""

export TMPDIR=`mktemp -d /tmp/selfextract.XXXXXX`

ARCHIVE=`awk '/^__ARCHIVE_BELOW__/ { print NR + 1; exit 0; }' $0`
tail -n+$ARCHIVE $0 | tar xzv -C $TMPDIR

CURDIR=`pwd`
cd $TMPDIR
./installer.sh

cd $CURDIR
rm -rf $TMPDIR

exit 0

__ARCHIVE_BELOW__
_EOF_

	chmod +x output/images/decompress.sh
fi

# builder script
rm -Rf output/images/build-sdk.sh
cat > output/images/build-sdk.sh <<_EOF_
#! /bin/sh

if [ ! -f ../payload.tar.gz ] ; then
	tar czvf ../payload.tar.gz ./* 
	cd ..

	cat decompress.sh payload.tar.gz > aarch64-nuvoton-linux-gnu_sdk-buildroot_installer
	chmod +x aarch64-nuvoton-linux-gnu_sdk-buildroot_installer

	echo ""
	echo "=============================================================================================="
	echo "Generated the SDK installer in output/images/aarch64-nuvoton-linux-gnu_sdk-buildroot_installer"
	echo "=============================================================================================="
	echo ""
	
	exit 0
fi 
_EOF_
chmod +x output/images/build-sdk.sh

cd output/images/payload
../build-sdk.sh
cd ../../../



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
