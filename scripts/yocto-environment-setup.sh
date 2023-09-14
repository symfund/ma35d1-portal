#!/bin/sh

# make a new directory 'yocto-ma35d1': $ make -p /path/to/yocto-ma35d1
# Download this script into /path/to/yocto-ma35d1/yocto-setup-build-environment.sh
# Change directory to 'yocto-ma35d1' and run this script
# cd /path/to/yocto-ma35d1 ; source yocto-setup-build-environment.sh

# [DISTRO] sources/meta-ma35d1/conf/distro
# nvt-ma35d1  nvt-ma35d1-directfb
distro=nvt-ma35d1-directfb

# [MACHINE] sources/meta-ma35d1/conf/machine
# numaker-iot-ma35d16f70  numaker-iot-ma35d16f90  numaker-som-ma35d16a81
machine=numaker-som-ma35d16a81

# [IMAGE RECIPE]
# core-image-minimal nvt-image-qt5
recipe=nvt-image-qt5

enable_offline_build=yes
update_yocto=yes

# setting up build environment
if ! test -f ~/.yocto_setup_done ; then
        sudo apt --purge remove firefox* thunderbird* libreoffice* rhythmbox*
        sudo apt update
        #sudo apt upgrade
        sudo apt autoremove

        # chromium-browser openssh-server
        sudo apt install --yes curl git git-lfs

        sudo snap install xmlstarlet

        # yocto required
        sudo apt install --yes gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint3 xterm python3-subunit mesa-common-dev

        # ma35d1 required
        sudo apt install --yes python autoconf automake cvs subversion flex bison u-boot-tools libssl-dev libncurses5-dev xvfb

        touch ~/.yocto_setup_done
fi

# meta yocto layers for MA35D1
if test ! -d "./sources/.git" ; then
        until git clone https://github.com/OpenNuvoton/MA35D1_Yocto-v3.1.3.git sources; do echo "retry..."; done
fi

if [[ ${update_yocto} == "yes" ]] ; then
        cd ./sources
        until git pull origin master; do echo "failed to update yocto, retry..."; done
        cd ..
fi

# output all the attribute names of a element: 'fetch' 'name'
# xml sel -T -t -m "//remote/@*" -v "name()" -n sources/meta-ma35d1/base/ma35d1.xml

# counting the total numbers of remote
remote_count=$(xml sel -t -v "count(//remote)" -n sources/meta-ma35d1/base/ma35d1.xml)
echo "remote count: $remote_count"
echo ""

names_with_newlines=$(xml sel -T -t -v "//remote/@name" -n sources/meta-ma35d1/base/ma35d1.xml)
names="${names_with_newlines//\\n/ }"

# typeset -A remote for some shells
# unique mapping: remote[name][fetch] or remote[name]=[fetch]
declare -gA remote

for name in ${names[@]}
do
	fetch=$(xml sel -t -v "//remote[@name='$name']/@fetch" -n sources/meta-ma35d1/base/ma35d1.xml)
	remote[\"$name\"]=$fetch
	echo "remote[\"$name\"].fetch = "${remote[\"$name\"]}
done
echo ""

# <remote fetch="https://github.com/meta-qt5" name="qt"/>
# <project remote="nuvoton" name="MA35D1_Yocto-v3.1.3" revision="master" path="sources"/>
# xml sel -t -v '//project[@remote="nuvoton"]/@name' -n sources/meta-ma35d1/base/ma35d1.xml
# xml sel -t -v '/manifest/project[@remote="yocto"][@name="poky"]/@path' -n sources/meta-ma35d1/base/ma35d1.xml

# remote	fetch				path				name			revision
# yocto 	https://git.yoctoproject.org	sources/poky			poky			251639560dd29bd2da5e694c1d5958ca26b12d0d
# yocto		https://git.yoctoproject.org	sources/meta-virtualization	meta-virtualization	89abc62b47f6f20db9d00a8ec9b2c1b6b60ac3f9

# for each remote's name get its path
for name in ${names[@]}
do
	echo "remote is $name"
	echo "remote's fetch is ${remote[\"$name\"]}"
	pathes=$(xml sel -t -v "//project[@remote='$name']/@path" -n sources/meta-ma35d1/base/ma35d1.xml)
	for path in ${pathes[@]}
	do
		echo "path is $path"
		repo_names=$(xml sel -t -v "//project[@remote='$name'][@path='$path']/@name" -n sources/meta-ma35d1/base/ma35d1.xml)
			for repo_name in ${repo_names[@]}
			do
				echo "repoitory name is $repo_name"
				revisions=$(xml sel -t -v "//project[@remote='$name'][@path='$path'][@name='$repo_name']/@revision" -n sources/meta-ma35d1/base/ma35d1.xml)
				for revision in ${revisions[@]}
				do
					echo "revision is $revision"

					if test ! -d "./$path/.git" ; then
						echo "the directory ./$path is not existed!"
						if [[ "$name" == "yocto" ]]; then
							# repository from yocto
							until git clone ${remote[\"$name\"]}/$repo_name $path; do echo "retry..."; done
						else
							# repository from github has a postfix '.git'
							until git clone ${remote[\"$name\"]}/$repo_name.git $path; do echo "retry..."; done
						fi

						cd ./$path
						git checkout $revision
						cd -
					else
						rev=$(git -C ./$path rev-parse HEAD)
						echo "current rev is: $rev"

						if [[ ${update_yocto} == "yes" ]]; then
							cd ./$path

							if [[ ${revision} == "master" ]] || [[ ${revision} != ${rev} ]]; then
								until git pull origin master; do echo "retry..."; done
							fi
							
							if [[ ${revision} != ${rev} ]]; then
								git checkout $revision
							fi

							cd -
						fi
					fi
					
					echo ""
				done
			done
	done
done

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
