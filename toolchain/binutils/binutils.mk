#############################################################
#
# build binutils for use on the host system
#
#############################################################
BINUTILS_VERSION:=$(call qstrip,$(BR2_BINUTILS_VERSION))

EXTRA_BINUTILS_CONFIG_OPTIONS=$(call qstrip,$(BR2_EXTRA_BINUTILS_CONFIG_OPTIONS))
BINUTILS_SITE:=$(BR2_KERNEL_MIRROR)/linux/devel/binutils
ifeq ($(BINUTILS_VERSION),2.20)
BINUTILS_SITE:=$(BR2_GNU_MIRROR)/binutils/
endif
ifeq ($(BINUTILS_VERSION),2.19.1)
BINUTILS_SITE:=$(BR2_GNU_MIRROR)/binutils/
endif
ifeq ($(BINUTILS_VERSION),2.19)
BINUTILS_SITE:=$(BR2_GNU_MIRROR)/binutils/
endif
ifeq ($(BINUTILS_VERSION),2.18)
BINUTILS_SITE:=$(BR2_GNU_MIRROR)/binutils/
endif
ifeq ($(BINUTILS_VERSION),2.17)
BINUTILS_SITE:=$(BR2_GNU_MIRROR)/binutils/
endif
ifeq ($(findstring avr32,$(BINUTILS_VERSION)),avr32)
BINUTILS_SITE:=ftp://www.at91.com/pub/buildroot/
endif

# We do not rely on the host's gmp/mpfr but use a known working one
BINUTILS_HOST_PREREQ:=
BINUTILS_TARGET_PREREQ:=

ifeq ($(findstring x4.0,x$(GCC_VERSION)),x4.0)
BINUTILS_NO_MPFR:=y
endif

ifndef BINUTILS_NO_MPFR
BINUTILS_HOST_PREREQ:=$(TOOLCHAIN_DIR)/gmp/lib/libgmp$(HOST_LIBEXT) \
	$(TOOLCHAIN_DIR)/mpfr/lib/libmpfr$(HOST_LIBEXT)
HOST_SOURCE += host-libgmp-source host-libmpfr-source

BINUTILS_TARGET_PREREQ:=$(TARGET_DIR)/usr/lib/libgmp$(LIBTGTEXT) \
	$(TARGET_DIR)/usr/lib/libmpfr$(LIBTGTEXT)

EXTRA_BINUTILS_CONFIG_OPTIONS+=--with-gmp="$(GMP_HOST_DIR)"
EXTRA_BINUTILS_CONFIG_OPTIONS+=--with-mpfr="$(MPFR_HOST_DIR)"

BINUTILS_TARGET_CONFIG_OPTIONS=--with-gmp="$(GMP_TARGET_DIR)"
BINUTILS_TARGET_CONFIG_OPTIONS+=--with-mpfr="$(MPFR_TARGET_DIR)"
endif

BINUTILS_PATCH_DIR:=toolchain/binutils/$(BINUTILS_VERSION)

ifneq ($(filter xtensa%,$(ARCH)),)
include target/xtensa/patch.in
BINUTILS_PATCH_EXTRA:=$(call XTENSA_PATCH,binutils,$(BINUTILS_PATCH_DIR),. ..)
endif

BINUTILS_SOURCE:=binutils-$(BINUTILS_VERSION).tar.bz2
BINUTILS_DIR:=$(TOOLCHAIN_DIR)/binutils-$(BINUTILS_VERSION)
BINUTILS_CAT:=$(BZCAT)

BINUTILS_DIR1:=$(TOOLCHAIN_DIR)/binutils-$(BINUTILS_VERSION)-build

$(DL_DIR)/$(BINUTILS_SOURCE):
	mkdir -p $(DL_DIR)
	$(call DOWNLOAD,$(BINUTILS_SITE),$(BINUTILS_SOURCE))

binutils-unpacked: $(BINUTILS_DIR)/.patched
$(BINUTILS_DIR)/.unpacked: $(DL_DIR)/$(BINUTILS_SOURCE)
	mkdir -p $(TOOLCHAIN_DIR)
	rm -rf $(BINUTILS_DIR)
	$(BINUTILS_CAT) $(DL_DIR)/$(BINUTILS_SOURCE) | tar -C $(TOOLCHAIN_DIR) $(TAR_OPTIONS) -
	$(CONFIG_UPDATE) $(@D)
	touch $@

binutils-patched: $(BINUTILS_DIR)/.patched
$(BINUTILS_DIR)/.patched: $(BINUTILS_DIR)/.unpacked
	# Apply appropriate binutils patches.
ifneq ($(wildcard $(BINUTILS_PATCH_DIR)),)
	toolchain/patch-kernel.sh $(BINUTILS_DIR) $(BINUTILS_PATCH_DIR) \*.patch $(BINUTILS_PATCH_EXTRA)
endif
	touch $@

$(BINUTILS_DIR1)/.configured: $(BINUTILS_DIR)/.patched
	mkdir -p $(BINUTILS_DIR1)
	(cd $(BINUTILS_DIR1); rm -rf config.cache; \
		$(HOST_CONFIGURE_OPTS) \
		$(BINUTILS_DIR)/configure $(QUIET) \
		--prefix=$(BR2_SYSROOT_PREFIX)/usr \
		--build=$(GNU_HOST_NAME) \
		--host=$(GNU_HOST_NAME) \
		--target=$(REAL_GNU_TARGET_NAME) \
		--mandir=$(BR2_SYSROOT_PREFIX)/usr/share/man \
		--infodir=$(BR2_SYSROOT_PREFIX)/usr/share/info \
		$(BR2_CONFIGURE_DEVEL_SYSROOT) \
		$(BR2_CONFIGURE_STAGING_SYSROOT) \
		$(DISABLE_NLS) \
		$(MULTILIB) \
		--disable-werror \
		$(SOFT_FLOAT_CONFIG_OPTION) \
		$(EXTRA_BINUTILS_CONFIG_OPTIONS) \
		$(QUIET) \
	)
	touch $@

$(BINUTILS_DIR1)/binutils/objdump: $(BINUTILS_DIR1)/.configured
	$(MAKE) -C $(BINUTILS_DIR1) all

# Make install will put gettext data in staging_dir/share/locale.
# Unfortunatey, it isn't configureable.
$(STAGING_DIR)/usr/bin/$(REAL_GNU_TARGET_NAME)-ld: $(BINUTILS_DIR1)/binutils/objdump
	$(MAKE) -C $(BINUTILS_DIR1) $(BR2_SYSROOT_STAGING_DESTDIR) install
	#	tooldir=/usr build_tooldir=/usr install
	#rm -f $(STAGING_DIR)/usr/bin/{ar,as,ld,nm,objdump,ranlib,strip}

binutils: uclibc-configured $(BINUTILS_HOST_PREREQ) $(STAGING_DIR)/usr/bin/$(REAL_GNU_TARGET_NAME)-ld

binutils-source: $(DL_DIR)/$(BINUTILS_SOURCE)

binutils-clean:
	-$(MAKE) -C $(BINUTILS_DIR1) DESTDIR=$(STAGING_DIR) \
		tooldir=/usr build_tooldir=/usr uninstall
	-$(MAKE) -C $(BINUTILS_DIR1) clean
	rm -rf $(wildcard $(patsubst %,$(STAGING_DIR)/usr/bin/*%,ar as ld nm objdump ranlib strip c++filt)) \
		$(wildcard $(patsubst %,$(STAGING_DIR)/usr/lib/%*,libiberty ldscripts))

binutils-dirclean:
	rm -rf $(BINUTILS_DIR1)

binutils-src-dirclean:
	rm -rf $(BINUTILS_DIR)

#############################################################
#
# build binutils for use on the target system
#
#############################################################
BINUTILS_DIR2:=$(BUILD_DIR)/binutils-$(BINUTILS_VERSION)-target
$(BINUTILS_DIR2)/.configured: $(BINUTILS_DIR)/.patched
	mkdir -p $(BINUTILS_DIR2)
	(cd $(BINUTILS_DIR2); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(BINUTILS_DIR)/configure $(QUIET) \
		--prefix=/usr \
		--exec-prefix=/usr \
		--build=$(GNU_HOST_NAME) \
		--host=$(REAL_GNU_TARGET_NAME) \
		--target=$(REAL_GNU_TARGET_NAME) \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
		$(DISABLE_NLS) \
		$(MULTILIB) \
		$(BINUTILS_TARGET_CONFIG_OPTIONS) \
		--disable-werror \
		$(SOFT_FLOAT_CONFIG_OPTION) \
	)
	touch $@

$(BINUTILS_DIR2)/binutils/objdump: $(BINUTILS_DIR2)/.configured
	PATH=$(TARGET_PATH) $(MAKE) -C $(BINUTILS_DIR2) all

$(TARGET_DIR)/usr/bin/ld: $(BINUTILS_DIR2)/binutils/objdump
	PATH=$(TARGET_PATH) \
	$(MAKE) DESTDIR=$(TARGET_DIR) \
		tooldir=/usr build_tooldir=/usr \
		-C $(BINUTILS_DIR2) install
ifneq ($(BR2_HAVE_MANPAGES),y)
	rm -rf $(TARGET_DIR)/usr/man
endif
ifneq ($(BR2_HAVE_INFOPAGES),y)
	rm -rf $(TARGET_DIR)/usr/info
endif
	rm -rf $(TARGET_DIR)/share/locale $(TARGET_DIR)/usr/share/doc
	-$(STRIPCMD) $(TARGET_DIR)/usr/$(REAL_GNU_TARGET_NAME)/bin/* > /dev/null 2>&1
	-$(STRIPCMD) $(TARGET_DIR)/usr/bin/* > /dev/null 2>&1

# If both binutils-target and busybox are selected, make certain binutils
# gets to run after busybox, so it can overwrite the busybox symlink for
# ar if enabled
ifeq ($(BR2_PACKAGE_BUSYBOX),y)
BINUTILS_TARGET_PREREQ += busybox
endif

binutils_target: $(BINUTILS_TARGET_PREREQ) $(TARGET_DIR)/usr/bin/ld

binutils_target-clean:
	-$(MAKE) -C $(BINUTILS_DIR2) clean
	rm -f $(TARGET_DIR)/bin/$(REAL_GNU_TARGET_NAME)* \
		$(addprefix $(TARGET_DIR)/usr/bin/, addr2line ar as gprof ld nm objcopy objdump ranlib readelf size strings strip c++filt)

binutils_target-dirclean:
	rm -rf $(BINUTILS_DIR2)
