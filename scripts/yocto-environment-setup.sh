#!/bin/sh

# [DISTRO] sources/meta-ma35d1/conf/distro
# nvt-ma35d1  nvt-ma35d1-directfb
distro=nvt-ma35d1

# [MACHINE] sources/meta-ma35d1/conf/machine
# numaker-iot-ma35d16f70  numaker-iot-ma35d16f90  numaker-som-ma35d16a81
machine=numaker-iot-ma35d16f70

# [IMAGE RECIPE]
# core-image-minimal nvt-image-qt5
recipe=core-image-minimal

enable_offline_build=yes
update_yocto=no

# libxml2-utils 
# parse sources/meta-ma35d1/base/ma35d1.xml

if ! test -f ~/.yocto_setup_done ; then
	sudo apt --purge remove firefox* thunderbird* libreoffice* rhythmbox*
	sudo apt update
	sudo apt upgrade
	sudo apt autoremove

	# chromium-browser openssh-server
	sudo apt install --yes curl git git-lfs

	# yocto required
	sudo apt install --yes gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint3 xterm python3-subunit mesa-common-dev

	# ma35d1 required
	sudo apt install --yes python autoconf automake cvs subversion flex bison u-boot-tools libssl-dev libncurses5-dev xvfb
	
	touch ~/.yocto_setup_done
fi

if test ! -d "./sources" ; then
	until git clone https://github.com/OpenNuvoton/MA35D1_Yocto-v3.1.3.git sources; do echo "retry..."; done
fi

if [[ ${update_yocto} == "yes" ]] ; then
	cd ./sources
	until git pull origin master; do echo "failed to update yocto, retry..."; done
	cd ..
fi

# git clone specific commits
if test ! -d "./sources/poky" ; then
	until git clone https://git.yoctoproject.org/poky sources/poky; do echo "retry..."; done
	cd ./sources/poky
	git checkout 251639560dd29bd2da5e694c1d5958ca26b12d0d
	cd ../../
fi

if test ! -d "./sources/meta-virtualization" ; then
	until git clone https://git.yoctoproject.org/meta-virtualization sources/meta-virtualization; do echo "retry..."; done
	cd ./sources/meta-virtualization
	git checkout 89abc62b47f6f20db9d00a8ec9b2c1b6b60ac3f9
	cd ../../
fi

if test ! -d "./sources/meta-openembedded" ; then
	until git clone https://github.com/openembedded/meta-openembedded.git sources/meta-openembedded; do echo "retry..."; done
	cd ./sources/meta-openembedded
	git checkout 430ef96fe65f62d8da995f446d5b9b093544f031
	cd ../../
fi

# upstream
if test ! -d "./sources/meta-qt5" ; then
	until git clone https://github.com/meta-qt5/meta-qt5.git sources/meta-qt5; do echo "retry..."; done
	cd ./sources/meta-qt5
	git checkout -b dunfell b4d24d70aca75791902df5cd59a4f4a54aa4a125
	cd ../../
fi

if test -f "build/conf/local.conf" ; then
	old_machine=$(grep 'MACHINE ??= ' build/conf/local.conf | cut -d"'" -f2)

	old_distro=$(grep 'DISTRO ?= ' build/conf/local.conf | cut -d"'" -f2)

	if [[ $old_machine != $machine || $old_distro != $distro ]] ; then
		rm -Rf build/conf
	fi
fi

DISTRO=${distro} MACHINE=${machine} source sources/init-build-env build

tfa_revision=master
tfa_dir=downloads/git2/github.com.OpenNuvoton.MA35D1_arm-trusted-firmware-v2.3.git
uboot_revision=master
uboot_dir=downloads/git2/github.com.OpenNuvoton.MA35D1_u-boot-v2020.07.git
optee_revision=master
optee_dir=downloads/git2/github.com.OpenNuvoton.MA35D1_optee_os-v3.9.0.git
linux_revision=master
linux_dir=downloads/git2/github.com.OpenNuvoton.MA35D1_linux-5.10.y.git
yocto_revision=master
yocto_dir=sources

machine_conf=sources/meta-ma35d1/conf/machine/${machine}.conf

cd ..

tfa_revision=$(git -C ${tfa_dir} rev-parse HEAD)
echo "tf-a-ma35d1: $tfa_revision"
uboot_revision=$(git -C ${uboot_dir} rev-parse HEAD)
echo "u-boot-ma35d1: $uboot_revision"
optee_revision=$(git -C ${optee_dir} rev-parse HEAD)
echo "optee-os-ma35d1: $optee_revision"
linux_revision=$(git -C ${linux_dir} rev-parse HEAD)
echo "linux-ma35d1: $linux_revision"
yocto_revision=$(git -C ${yocto_dir} rev-parse HEAD)
echo "yocto: $yocto_revision"

enable_offline_build() {
	sed -i 's/^KERNEL_SRCREV.*/KERNEL_SRCREV = "'${linux_revision}'"/' ${machine_conf}
	sed -i 's/^UBOOT_SRCREV.*/UBOOT_SRCREV = "'${uboot_revision}'"/' ${machine_conf}
	sed -i 's/^TFA_SRCREV.*/TFA_SRCREV = "'${tfa_revision}'"/' ${machine_conf}
	sed -i 's/^OPTEE_SRCREV.*/OPTEE_SRCREV = "'${optee_revision}'"/' ${machine_conf}

	if grep -q "BB_NO_NETWORK" build/conf/local.conf ; then
		sed -i 's/^BB_NO_NETWORK.*/BB_NO_NETWORK = "1"/' build/conf/local.conf
	else
		sed -i -e '$aBB_NO_NETWORK = "1"' build/conf/local.conf
	fi
}

disable_offline_build() {
        sed -i 's/^KERNEL_SRCREV.*/KERNEL_SRCREV = "master"/' ${machine_conf}
        sed -i 's/^UBOOT_SRCREV.*/UBOOT_SRCREV = "master"/' ${machine_conf}
        sed -i 's/^TFA_SRCREV.*/TFA_SRCREV = "master"/' ${machine_conf}
        sed -i 's/^OPTEE_SRCREV.*/OPTEE_SRCREV = "master"/' ${machine_conf}

        if grep -q "BB_NO_NETWORK" build/conf/local.conf ; then
                sed -i 's/^BB_NO_NETWORK.*/BB_NO_NETWORK = "0"/' build/conf/local.conf
        else
                sed -i -e '$aBB_NO_NETWORK = "0"' build/conf/local.conf
        fi
}

if [[ ${enable_offline_build} == "yes" ]] ; then
	enable_offline_build
fi

if [[ ${enable_offline_build} == "no" ]] ; then
	disable_offline_build
fi

cd build

if [[ ${enable_offline_build} == "no" ]] ; then
	bitbake -c cleansstate tf-a-ma35d1 optee-os-ma35d1 u-boot-ma35d1 linux-ma35d1 nvt-image-qt5
fi

until bitbake ${recipe}; do echo "retry..."; done

#bitbake nvt-image-qt5 -c populate_sdk
#bitbake tf-a-ma35d1 optee-os-ma35d1 u-boot-ma35d1 linux-ma35d1 nvt-image-qt5
#bitbake -f -c [cleansstate] [devshell] [compile] [menuconfig] [listtasks] nvt-image-qt5
