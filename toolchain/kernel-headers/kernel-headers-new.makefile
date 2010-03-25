#############################################################
#
# full kernel tarballs >= 2.6.19.1
#
#############################################################

# parse linux version string
LNXVER:=$(subst ., , $(strip $(DEFAULT_KERNEL_HEADERS)))
VERSION:=$(word 1, $(LNXVER))
PATCHLEVEL:=$(word 2, $(LNXVER))
SUBLEVEL:=$(word 3, $(LNXVER))
EXTRAVERSION:=$(word 4, $(LNXVER))
LOCALVERSION:=

# should contain prepended dot
SUBLEVEL:=$(if $(SUBLEVEL),.$(SUBLEVEL),)
EXTRAVERSION:=$(if $(EXTRAVERSION),.$(EXTRAVERSION),)

LINUX_HEADERS_VERSION:=$(VERSION).$(PATCHLEVEL)$(SUBLEVEL)$(EXTRAVERSION)
LINUX_HEADERS_SITE:=$(BR2_KERNEL_MIRROR)/linux/kernel/v2.6/
LINUX_HEADERS_SOURCE:=linux-$(LINUX_HEADERS_VERSION).tar.bz2
LINUX_HEADERS_CAT:=$(BZCAT)
LINUX_HEADERS_UNPACK_DIR:=$(TOOLCHAIN_DIR)/linux-$(LINUX_HEADERS_VERSION)
LINUX_HEADERS_DIR:=$(TOOLCHAIN_DIR)/linux

LINUX_HEADERS_DEPENDS:=

$(LINUX_HEADERS_UNPACK_DIR)/.unpacked: $(DL_DIR)/$(LINUX_HEADERS_SOURCE)
	@echo "*** Using kernel-headers generated from kernel source"
	rm -rf $(LINUX_HEADERS_DIR)
	[ -d $(TOOLCHAIN_DIR) ] || $(INSTALL) -d $(TOOLCHAIN_DIR)
	$(LINUX_HEADERS_CAT) $(DL_DIR)/$(LINUX_HEADERS_SOURCE) | tar -C $(TOOLCHAIN_DIR) $(TAR_OPTIONS) -
	touch $@

$(LINUX_HEADERS_UNPACK_DIR)/.patched: $(LINUX_HEADERS_UNPACK_DIR)/.unpacked $(LINUX_HEADERS_DEPENDS)
	toolchain/patch-kernel.sh $(LINUX_HEADERS_UNPACK_DIR) toolchain/kernel-headers \
		linux-$(LINUX_HEADERS_VERSION)-\*.patch{,.gz,.bz2}
ifneq ($(KERNEL_HEADERS_PATCH_DIR),)
	toolchain/patch-kernel.sh $(LINUX_HEADERS_UNPACK_DIR) $(KERNEL_HEADERS_PATCH_DIR) \
		linux-$(LINUX_HEADERS_VERSION)-\*.patch{,.gz,.bz2}
endif
	touch $@

$(LINUX_HEADERS_DIR)/.configured: $(LINUX_HEADERS_UNPACK_DIR)/.patched
	(cd $(LINUX_HEADERS_UNPACK_DIR); \
	 $(MAKE) ARCH=$(KERNEL_ARCH) \
		HOSTCC="$(HOSTCC)" HOSTCFLAGS="$(HOSTCFLAGS)" \
		HOSTCXX="$(HOSTCXX)" \
		INSTALL_HDR_PATH=$(LINUX_HEADERS_DIR) headers_install; \
	)
ifeq ($(BR2_ARCH),"cris")
	ln -s $(LINUX_HEADERS_DIR)/include/arch-v10/arch $(LINUX_HEADERS_DIR)/include/arch
	cp -a $(LINUX_HEADERS_UNPACK_DIR)/include/linux/user.h $(LINUX_HEADERS_DIR)/include/linux
	$(SED) "/^#include <asm\/page\.h>/d" $(LINUX_HEADERS_DIR)/include/asm/user.h
endif
	touch $@
