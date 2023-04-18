ifneq ($(KERNELRELEASE),)
include Kbuild

else
KERNELDIR ?= /lib/modules/`uname -r`/build

default:
	$(MAKE) -C $(KERNELDIR) M=$$PWD

clean:
	$(MAKE) -C $(KERNELDIR) M=$$PWD clean

endif
