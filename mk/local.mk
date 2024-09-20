######################################################################################################################################
#                                                                                                                                    #
# Nuvoton Corporation 2024 (twjiang@nuvoton.com)                                                                                     #
#                                                                                                                                    #
######################################################################################################################################

# Overriding packages source directory
ARM_TRUSTED_FIRMWARE_OVERRIDE_SRCDIR=$(call qstrip,$(BR2_ARM_TRUSTED_FIRMWARE_SRCDIR))
UBOOT_OVERRIDE_SRCDIR=$(call qstrip,$(BR2_UBOOT_SRCDIR))
OPTEE_OS_OVERRIDE_SRCDIR=$(call qstrip,$(BR2_OPTEE_OS_SRCDIR))
LINUX_OVERRIDE_SRCDIR=$(call qstrip,$(BR2_LINUX_SRCDIR))

# Buildroot 2016 must override the below 'LINUX_HEADERS_OVERRIDE_SRCDIR', uncomment it.
#LINUX_HEADERS_OVERRIDE_SRCDIR=$(call qstrip,$(BR2_LINUX_SRCDIR))

ifeq ($(BR2_LINUX_KERNEL_USE_DEFCONFIG),y)
ifndef BR2_LINUX_KERNEL_DEFCONFIG_FILE
BR2_LINUX_KERNEL_DEFCONFIG_SHORT_FILE = $(call qstrip,$(BR2_LINUX_KERNEL_DEFCONFIG))
BR2_LINUX_ARCH=$(if $(BR2_aarch64),arm64,arm)
BR2_LINUX_KERNEL_DEFCONFIG_FILE = $(LINUX_OVERRIDE_SRCDIR)/arch/$(BR2_LINUX_ARCH)/configs/$(BR2_LINUX_KERNEL_DEFCONFIG_SHORT_FILE)_defconfig
endif
endif

ifeq ($(BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG),y)
ifndef BR2_LINUX_KERNEL_CUSTOM_USER_CONFIG_FILE
BR2_LINUX_KERNEL_CUSTOM_USER_CONFIG_FILE = $(call qstrip,$(BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE))
endif
endif

ifeq ($(BR2_TARGET_UBOOT_USE_DEFCONFIG),y)
ifndef BR2_UBOOT_DEFCONFIG_FILE
BR2_UBOOT_DEFCONFIG_SHORT_FILE = $(call qstrip,$(BR2_TARGET_UBOOT_BOARD_DEFCONFIG))
BR2_UBOOT_DEFCONFIG_FILE = $(UBOOT_OVERRIDE_SRCDIR)/configs/$(BR2_UBOOT_DEFCONFIG_SHORT_FILE)_defconfig
endif
endif

ifeq ($(BR2_TARGET_UBOOT_USE_CUSTOM_CONFIG),y)
ifndef BR2_UBOOT_CUSTOM_USER_CONFIG_FILE
BR2_UBOOT_CUSTOM_USER_CONFIG_FILE = $(call qstrip,$(BR2_TARGET_UBOOT_CUSTOM_CONFIG_FILE))
endif
endif

ifndef BR2_PACKAGE_BUSYBOX_CONFIG_FILE
BR2_PACKAGE_BUSYBOX_CONFIG_FILE = $(call qstrip,$(BR2_PACKAGE_BUSYBOX_CONFIG))
endif

ifndef BR2_UCLIBC_CONFIG_FILE
BR2_UCLIBC_CONFIG_FILE = $(call qstrip,$(BR2_UCLIBC_CONFIG))
endif

ifndef BR2_BIN_SH
BR2_BIN_SH=$(if $(BR2_SYSTEM_BIN_SH_BUSYBOX),sh,$(call qstrip,$(BR2_SYSTEM_BIN_SH)))
endif

export BR2_SDK_PREFIX_REL=$(BR2_SDK_PREFIX)

define _script

mkdir -p output/images/payload
rm -Rf output/images/payload/*
cp -Rf output/images/${BR2_SDK_PREFIX_REL}.tar.gz output/images/payload

cat > output/images/payload/installer.sh <<EOF
#!/bin/sh

echo ""
echo "============================================================================================="
echo "Installing MA35D1 SDK into /opt/${BR2_SDK_PREFIX_REL}..."
echo "============================================================================================="
sudo tar xzvf ./${BR2_SDK_PREFIX_REL}.tar.gz -C /opt
/opt/${BR2_SDK_PREFIX_REL}/relocate-sdk.sh
echo ""
echo "============================================================================================="
echo "Before compiling source files, set up the build environment as shown below"
echo ""
echo "$ source /opt/${BR2_SDK_PREFIX_REL}/environment-setup"
echo ""
echo "============================================================================================="
echo ""
EOF

chmod +x output/images/payload/installer.sh

cat > output/images/decompress.sh <<'_EOF_'
#!/bin/sh
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

# builder script
rm -Rf output/images/payload.tar.gz
rm -Rf output/images/build-sdk.sh

cat > output/images/build-sdk.sh <<_EOF_
#!/bin/sh

if [ ! -f ../payload.tar.gz ] ; then
        tar czvf ../payload.tar.gz ./*
        cd ..

        cat decompress.sh payload.tar.gz > ${BR2_SDK_PREFIX_REL}_installer
        chmod +x ${BR2_SDK_PREFIX_REL}_installer

        echo ""
        echo "=============================================================================================="
        echo "Generated the SDK installer in output/images/${BR2_SDK_PREFIX_REL}_installer"
        echo "=============================================================================================="
        echo ""

        exit 0
fi
_EOF_
chmod +x output/images/build-sdk.sh

cd output/images/payload
../build-sdk.sh
cd ../../../


endef

export script = $(value _script)

buildroot-save-config:
	@echo ">>>>>>>>>> Saving Buildroot configuration <<<<<<<<<<"
	@make savedefconfig BR2_DEFCONFIG=$(BR2_DEFCONFIG)
	@echo "Buildroot configuration was saved to $(BR2_DEFCONFIG)"

buildroot-update-source:
	@echo ">>>>>>>>>> Updating source of Buildroot <<<<<<<<<<"
	@until git pull; do echo "retry..."; done

busybox-save-config:
	@echo ">>>>>>>>>> Saving Busybox configuration <<<<<<<<<<"
	@make busybox-update-config
	@echo "Busybox configuration was saved to $(BR2_PACKAGE_BUSYBOX_CONFIG_FILE)"

uclibc-save-config:
	@echo ">>>>>>>>>> Saving uClibc configuration <<<<<<<<<<"
	@make uclibc-update-config
	@echo "uClibc configuration was saved to $(BR2_UCLIBC_CONFIG_FILE)"

linux-save-config:
	@echo ">>>>>>>>>> Saving Linux configuration <<<<<<<<<<"

	@if grep -Eq "^BR2_LINUX_KERNEL_USE_DEFCONFIG=y" $(BR2_CONFIG); then \
		sed -i -e 's/BR2_LINUX_KERNEL_USE_DEFCONFIG=y/# BR2_LINUX_KERNEL_USE_DEFCONFIG is not set/' -i $(BR2_CONFIG); \
		sed -i -e 's/# BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG is not set/BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG=y/' -i $(BR2_CONFIG); \
		sed -i "/^BR2_LINUX_KERNEL_DEFCONFIG=.*/c\BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE=\"$(BR2_LINUX_KERNEL_DEFCONFIG_FILE)\"" -i $(BR2_CONFIG); \
		make linux-update-defconfig; \
		if [ $$? -eq 0 ]; then \
			echo "Linux configuration was saved to $(BR2_LINUX_KERNEL_DEFCONFIG_FILE)"; \
		fi; \
		sed -i -e 's/^# BR2_LINUX_KERNEL_USE_DEFCONFIG.*/BR2_LINUX_KERNEL_USE_DEFCONFIG=y/' -i $(BR2_CONFIG); \
		sed -i -e 's/^BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG=y/# BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG is not set/' -i $(BR2_CONFIG); \
		sed -i "/^BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE=.*/c\BR2_LINUX_KERNEL_DEFCONFIG=\"$(BR2_LINUX_KERNEL_DEFCONFIG_SHORT_FILE)\"" -i $(BR2_CONFIG); \
	fi

	@if grep -Eq "^BR2_LINUX_KERNEL_USE_CUSTOM_CONFIG=y" $(BR2_CONFIG); then \
		make linux-update-defconfig; \
		if [ $$? -eq 0 ]; then \
			echo "Linux configuration was saved to $(BR2_LINUX_KERNEL_CUSTOM_USER_CONFIG_FILE)"; \
		fi; \
	fi

linux-download-source:
	@echo ">>>>>>>>>> Downloading source of Linux <<<<<<<<<<"
	@mkdir -p $(LINUX_OVERRIDE_SRCDIR)
	@until git clone https://github.com/OpenNuvoton/MA35D1_linux-5.10.y.git $(LINUX_OVERRIDE_SRCDIR); \
		do echo "failed to clone Linux repository, retry..."; done

linux-update-source:
	@echo ">>>>>>>>>> Updating source of Linux <<<<<<<<<<"
	@if [[ -n "$(LINUX_OVERRIDE_SRCDIR)" ]]; then cd $(LINUX_OVERRIDE_SRCDIR); until git pull; do echo "retry..."; done; cd -; fi

uboot-save-config:
	@echo ">>>>>>>>>> Saving U-Boot configuration <<<<<<<<<<"
	
	@if grep -Eq "^BR2_TARGET_UBOOT_USE_DEFCONFIG=y" $(BR2_CONFIG); then \
		echo "U-Boot uses default configuration file"; \
		sed -i -e 's/BR2_TARGET_UBOOT_USE_DEFCONFIG=y/# BR2_TARGET_UBOOT_USE_DEFCONFIG is not set/' -i $(BR2_CONFIG); \
		sed -i -e 's/# BR2_TARGET_UBOOT_USE_CUSTOM_CONFIG is not set/BR2_TARGET_UBOOT_USE_CUSTOM_CONFIG=y/' -i $(BR2_CONFIG); \
		sed -i "/^BR2_TARGET_UBOOT_BOARD_DEFCONFIG=.*/c\BR2_TARGET_UBOOT_CUSTOM_CONFIG_FILE=\"$(BR2_UBOOT_DEFCONFIG_FILE)\"" -i $(BR2_CONFIG); \
		make uboot-update-defconfig; \
		if [ $$? -eq 0 ]; then \
			echo "U-Boot configuration was saved to $(BR2_UBOOT_DEFCONFIG_FILE)"; \
		fi; \
		sed -i -e 's/^# BR2_TARGET_UBOOT_USE_DEFCONFIG.*/BR2_TARGET_UBOOT_USE_DEFCONFIG=y/' -i $(BR2_CONFIG); \
		sed -i -e 's/^BR2_TARGET_UBOOT_USE_CUSTOM_CONFIG=y/# BR2_TARGET_UBOOT_USE_CUSTOM_CONFIG is not set/' -i $(BR2_CONFIG); \
		sed -i "/^BR2_TARGET_UBOOT_CUSTOM_CONFIG_FILE=.*/c\BR2_TARGET_UBOOT_BOARD_DEFCONFIG=\"$(BR2_UBOOT_DEFCONFIG_SHORT_FILE)\"" -i $(BR2_CONFIG); \
	fi

	@if grep -Eq "^BR2_TARGET_UBOOT_USE_CUSTOM_CONFIG=y" $(BR2_CONFIG); then \
		echo "U-Boot uses user custom configuration file"; \
		make uboot-update-defconfig; \
		if [ $$? -eq 0 ]; then \
			echo "U-Boot configuration was saved to $(BR2_UBOOT_CUSTOM_USER_CONFIG_FILE)"; \
		fi; \
	fi

uboot-download-source:
	@echo ">>>>>>>>>> Downloading source of U-Boot <<<<<<<<<<"
	@mkdir -p $(UBOOT_OVERRIDE_SRCDIR)
	@until git clone https://github.com/OpenNuvoton/MA35D1_u-boot-v2020.07.git $(UBOOT_OVERRIDE_SRCDIR); \
		do echo "failed to clone U-Boot repository, retry..."; done

uboot-update-source:
	@echo ">>>>>>>>>> Updating source of U-Boot <<<<<<<<<<"
	@if [[ -n "$(UBOOT_OVERRIDE_SRCDIR)" ]]; then cd $(UBOOT_OVERRIDE_SRCDIR); until git pull; do echo "retry..."; done; cd -; fi

# '$ make uboot-show-recursive-rdepends' produces the dependent packages of uboot reversely
UBOOT_RDEPS=$$(make uboot-show-recursive-rdepends)

uboot-alter-rebuild:
	@make uboot-rebuild
	@for pkg in $(UBOOT_RDEPS); do \
		echo ">>>>>>>>>> Rebuilding $$pkg <<<<<<<<<<"; \
		make $$pkg-rebuild; \
	done 
	@make

arm-trusted-firmware-download-source:
	@echo ">>>>>>>>>> Downloading source of Trusted Firmware for Arm <<<<<<<<<<"
	@mkdir -p $(ARM_TRUSTED_FIRMWARE_OVERRIDE_SRCDIR)
	@until git clone https://github.com/OpenNuvoton/MA35D1_arm-trusted-firmware-v2.3.git \
		$(ARM_TRUSTED_FIRMWARE_OVERRIDE_SRCDIR); \
		do echo "failed to clone tf-a repository, retry..."; done

arm-trusted-firmware-update-source:
	@echo ">>>>>>>>>> Updating source of Trusted Firmware for Arm <<<<<<<<<<"
	@if [[ -n "$(ARM_TRUSTED_FIRMWARE_OVERRIDE_SRCDIR)" ]]; then cd $(ARM_TRUSTED_FIRMWARE_OVERRIDE_SRCDIR); until git pull; do echo "retry..."; done; cd -; fi

optee-os-download-source:
	@echo ">>>>>>>>>> Downloading source of optee OS <<<<<<<<<<"
	@mkdir -p $(OPTEE_OS_OVERRIDE_SRCDIR)
	@until git clone https://github.com/OpenNuvoton/MA35D1_optee_os-v3.9.0.git $(OPTEE_OS_OVERRIDE_SRCDIR); \
		do echo "failed to clone optee-os repository, retry..."; done

optee-os-update-source:
	@echo ">>>>>>>>>> Updating source of optee OS <<<<<<<<<<"
	@if [[ -n "$(OPTEE_OS_OVERRIDE_SRCDIR)" ]]; then cd $(OPTEE_OS_OVERRIDE_SRCDIR); until git pull; do echo "retry..."; done; cd -; fi

all-download-source:
	@echo ">>>>>>>>>> Downloading all sources <<<<<<<<<<"
	@make arm-trusted-firmware-download-source
	@make uboot-download-source
	@make optee-os-download-source
	@make linux-download-source
	@echo "all sources downloaded done"

all-update-source:
	@echo ">>>>>>>>>> Updating all sources <<<<<<<<<<"
	@make arm-trusted-firmware-update-source
	@make uboot-update-source
	@make optee-os-update-source
	@make linux-update-source
	@make buildroot-update-source
	@echo "all sources updated done"

all-save-config:
	@echo ">>>>>>>>>> Saving all configurations <<<<<<<<<<"
	@make buildroot-save-config
	@make uboot-save-config
	@make linux-save-config
	@make busybox-save-config
	@make uclibc-save-config
	@echo "All configurations are saved successfully."

rootfs-clean:
	@echo ">>>>>>>>>> Cleaning rootfs <<<<<<<<<<"
	@rm -Rf output/target; find output/build -name ".stamp_target_installed" | xargs rm -Rf
	@echo "rootfs cleaned done"

rootfs-rebuild:
	@echo ">>>>>>>>>> Rebuilding rootfs <<<<<<<<<<"
	@make rootfs-clean
	@make host-gcc-final-rebuild
	@make
	@echo "rootfs rebuilt done"

all-clean:
	@echo ">>>>>>>>>> Cleaning all <<<<<<<<<<"
	@make rootfs-clean
	@rm -Rf output/images
	@make uboot-dirclean arm-trusted-firmware-dirclean host-uboot-tools-dirclean linux-dirclean optee-os-dirclean
	@echo "All clean done"

all-rebuild:
	@echo ">>>>>>>>>> Rebuilding all <<<<<<<<<<"
	@make all-clean
	@mkdir -p output/target output/images
	@make host-gcc-final-rebuild
	@make

sdk-tool:
	@echo ">>>>>>>>>> Making SDK <<<<<<<<<<"
	@echo "$(BR2_BIN_SH)" > .shell
	@sed -i 's/BR2_INIT_BUSYBOX=y/# BR2_INIT_BUSYBOX is not set/g' $(BR2_CONFIG) 
	@sed -i 's/# BR2_INIT_NONE is not set/BR2_INIT_NONE=y/g' $(BR2_CONFIG)
	@sed -i 's/# BR2_SYSTEM_BIN_SH_NONE is not set/BR2_SYSTEM_BIN_SH_NONE=y/g' $(BR2_CONFIG) 
	@sed -i '/BR2_SYSTEM_BIN_SH_BUSYBOX=y/d' $(BR2_CONFIG) 
	@sed -i 's/BR2_PACKAGE_BUSYBOX=y/# BR2_PACKAGE_BUSYBOX is not set/g' $(BR2_CONFIG) 
	@sed -i 's/BR2_TARGET_ROOTFS_TAR=y/# BR2_TARGET_ROOTFS_TAR is not set/g' $(BR2_CONFIG) 
	@make olddefconfig
	@make sdk

	@eval "$$script"

	@sed -i 's/# BR2_INIT_BUSYBOX is not set/BR2_INIT_BUSYBOX=y/g' $(BR2_CONFIG) 
	@sed -i 's/BR2_INIT_NONE=y/# BR2_INIT_NONE is not set/g' $(BR2_CONFIG) 

	@if [[ $$(cat .shell) == "sh" ]]; then \
		sed -i '/^# BR2_SYSTEM_BIN_SH_BASH is not set/i BR2_SYSTEM_BIN_SH_BUSYBOX=y' $(BR2_CONFIG); \
		sed -i 's/BR2_SYSTEM_BIN_SH_NONE=y/# BR2_SYSTEM_BIN_SH_NONE is not set/g' $(BR2_CONFIG); \
	fi

	@if [[ $$(cat .shell) == "bash" ]]; then \
		sed -i '/^# BR2_SYSTEM_BIN_SH_BASH is not set/i # BR2_SYSTEM_BIN_SH_BUSYBOX is not set' $(BR2_CONFIG); \
		sed -i 's/^# BR2_SYSTEM_BIN_SH_BASH is not set/BR2_SYSTEM_BIN_SH_BASH=y/g' $(BR2_CONFIG); \
		sed -i '/^BR2_SYSTEM_BIN_SH_NONE=y/a BR2_SYSTEM_BIN_SH="bash"' $(BR2_CONFIG); \
		sed -i 's/^BR2_SYSTEM_BIN_SH_NONE=y/# BR2_SYSTEM_BIN_SH_NONE is not set/g' $(BR2_CONFIG); \
	fi

	@if [[ $$(cat .shell) == "dash" ]]; then \
                sed -i '/^# BR2_SYSTEM_BIN_SH_BASH is not set/i # BR2_SYSTEM_BIN_SH_BUSYBOX is not set' $(BR2_CONFIG); \
                sed -i 's/^# BR2_SYSTEM_BIN_SH_DASH is not set/BR2_SYSTEM_BIN_SH_DASH=y/g' $(BR2_CONFIG); \
                sed -i '/^BR2_SYSTEM_BIN_SH_NONE=y/a BR2_SYSTEM_BIN_SH="dash"' $(BR2_CONFIG); \
                sed -i 's/^BR2_SYSTEM_BIN_SH_NONE=y/# BR2_SYSTEM_BIN_SH_NONE is not set/g' $(BR2_CONFIG); \
        fi

	@if [[ $$(cat .shell) == "mksh" ]]; then \
		sed -i '/^# BR2_SYSTEM_BIN_SH_BASH is not set/i # BR2_SYSTEM_BIN_SH_BUSYBOX is not set' $(BR2_CONFIG); \
		sed -i 's/^# BR2_SYSTEM_BIN_SH_MKSH is not set/BR2_SYSTEM_BIN_SH_MKSH=y/g' $(BR2_CONFIG); \
		sed -i '/^BR2_SYSTEM_BIN_SH_NONE=y/a BR2_SYSTEM_BIN_SH="mksh"' $(BR2_CONFIG); \
		sed -i 's/^BR2_SYSTEM_BIN_SH_NONE=y/# BR2_SYSTEM_BIN_SH_NONE is not set/g' $(BR2_CONFIG); \
	fi

	@if [[ $$(cat .shell) == "zsh" ]]; then \
		sed -i '/^# BR2_SYSTEM_BIN_SH_BASH is not set/i # BR2_SYSTEM_BIN_SH_BUSYBOX is not set' $(BR2_CONFIG); \
		sed -i 's/^# BR2_SYSTEM_BIN_SH_ZSH is not set/BR2_SYSTEM_BIN_SH_ZSH=y/g' $(BR2_CONFIG); \
		sed -i '/^BR2_SYSTEM_BIN_SH_NONE=y/a BR2_SYSTEM_BIN_SH="zsh"' $(BR2_CONFIG); \
		sed -i 's/^BR2_SYSTEM_BIN_SH_NONE=y/# BR2_SYSTEM_BIN_SH_NONE is not set/g' $(BR2_CONFIG); \
	fi

	@sed -i 's/# BR2_PACKAGE_BUSYBOX is not set/BR2_PACKAGE_BUSYBOX=y/g' $(BR2_CONFIG) 
	@sed -i 's/# BR2_TARGET_ROOTFS_TAR is not set/BR2_TARGET_ROOTFS_TAR=y/g' $(BR2_CONFIG) 
	@rm -Rf .shell
	@make olddefconfig
	@make

verbose:
	@echo "ARM_TRUSTED_FIRMWARE_OVERRIDE_SRCDIR=$(ARM_TRUSTED_FIRMWARE_OVERRIDE_SRCDIR)"
	@echo "UBOOT_OVERRIDE_SRCDIR=$(UBOOT_OVERRIDE_SRCDIR)"
	@echo "OPTEE_OS_OVERRIDE_SRCDIR=$(OPTEE_OS_OVERRIDE_SRCDIR)"
	@echo "LINUX_OVERRIDE_SRCDIR=$(LINUX_OVERRIDE_SRCDIR)"
	@echo "BR2_DEFCONFIG=$(BR2_DEFCONFIG)"
	@echo "BR2_CONFIG=$(BR2_CONFIG)"
	@echo "BR2_BIN_SH=$(BR2_BIN_SH)"
	@echo "BR2_LINUX_ARCH=$(BR2_LINUX_ARCH)"
	@echo "BR2_LINUX_KERNEL_DEFCONFIG_SHORT_FILE=$(BR2_LINUX_KERNEL_DEFCONFIG_SHORT_FILE)"
	@echo "BR2_LINUX_KERNEL_DEFCONFIG_FILE=$(BR2_LINUX_KERNEL_DEFCONFIG_FILE)"
	@echo "BR2_UBOOT_DEFCONFIG_SHORT_FILE=$(BR2_UBOOT_DEFCONFIG_SHORT_FILE)"
	@echo "BR2_UBOOT_DEFCONFIG_FILE=$(BR2_UBOOT_DEFCONFIG_FILE)"
	@echo "BR2_TARGET_UBOOT_CUSTOM_TARBALL_LOCATION=$(BR2_TARGET_UBOOT_CUSTOM_TARBALL_LOCATION)"
	@echo "BR2_TARGET_ARM_TRUSTED_FIRMWARE_CUSTOM_TARBALL_LOCATION=$(BR2_TARGET_ARM_TRUSTED_FIRMWARE_CUSTOM_TARBALL_LOCATION)"
	@echo "BR2_SDK_PREFIX=$(BR2_SDK_PREFIX)"
