# ma35d1-portal
tutorials, FAQs, static GitHub pages

# Linux Development with Buildroot

# Silently Configure Buildroot in Noninteractive Mode to Save Custom Configuration Files for Buildroot, Linux and U-Boot
See: https://raw.githubusercontent.com/symfund/ma35d1-portal/master/scripts/save-configs.sh

# Overriding Packages Source Directory
To override packages source drectory, by creating a file 'local.mk' in the Buildroot directory with content like the below
```
ARM_TRUSTED_FIRMWARE_OVERRIDE_SRCDIR=$(CONFIG_DIR)/workspace/tf-a
UBOOT_OVERRIDE_SRCDIR=$(CONFIG_DIR)/workspace/uboot
LINUX_OVERRIDE_SRCDIR=$(CONFIG_DIR)/workspace/linux
```
# Wayland Desktop Environment
![Content of Wayland Desktop Environment](/pics/wayland-desktop-environment-content.png)

# LVGL with Wayland
See doc/Wayland Desktop Environment.pdf
![LVGL with Wayland](/pics/lvgl-with-wayland.png)
