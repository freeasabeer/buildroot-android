#############################################################
#
# mpfr
#
#############################################################
MPFR_VERSION:=2.4.1
MPFR_PATCH:=patches
MPFR_PATCH_FILE:=mpfr-$(MPFR_VERSION).patch
MPFR_SOURCE:=mpfr-$(MPFR_VERSION).tar.bz2
MPFR_CAT:=$(BZCAT)
MPFR_SITE:=http://www.mpfr.org/mpfr-$(MPFR_VERSION)
MPFR_DIR:=$(TOOLCHAIN_DIR)/mpfr-$(MPFR_VERSION)
MPFR_TARGET_DIR:=$(BUILD_DIR)/mpfr-$(MPFR_VERSION)
MPFR_BINARY:=libmpfr$(LIBTGTEXT)
MPFR_HOST_BINARY:=libmpfr$(HOST_LIBEXT)
MPFR_LIBVERSION:=1.2.0

# need patch
ifneq ($(MPFR_PATCH),)
MPFR_PATCH_SOURCE:=$(DL_DIR)/$(MPFR_PATCH_FILE)

$(MPFR_PATCH_SOURCE):
	$(call DOWNLOAD,$(MPFR_SITE),$(MPFR_PATCH))
ifeq ($(SPIDER),) # this breaks source-check/external-deps
	mv $(DL_DIR)/$(MPFR_PATCH) $@
endif
endif

$(DL_DIR)/$(MPFR_SOURCE):
	 $(call DOWNLOAD,$(MPFR_SITE),$(MPFR_SOURCE))

$(MPFR_DIR)/.unpacked: $(DL_DIR)/$(MPFR_SOURCE) $(MPFR_PATCH_SOURCE)
	$(MPFR_CAT) $(DL_DIR)/$(MPFR_SOURCE) | tar -C $(TOOLCHAIN_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(MPFR_DIR) package/mpfr/ \*.patch
	$(CONFIG_UPDATE) $(@D)
ifneq ($(MPFR_PATCH),)
	toolchain/patch-kernel.sh $(MPFR_DIR) $(DL_DIR)/ $(MPFR_PATCH_FILE)
endif
	touch $@

$(MPFR_TARGET_DIR)/.configured: $(MPFR_DIR)/.unpacked $(STAGING_DIR)/usr/lib/$(GMP_BINARY)
	mkdir -p $(MPFR_TARGET_DIR)
	(cd $(MPFR_TARGET_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		$(MPFR_DIR)/configure $(QUIET) \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		$(PREFERRED_LIB_FLAGS) \
		--with-gmp-build=$(GMP_TARGET_DIR) \
		$(DISABLE_NLS) \
	)
	touch $@

$(MPFR_TARGET_DIR)/.libs/$(MPFR_BINARY): $(MPFR_TARGET_DIR)/.configured
	#$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(MPFR_TARGET_DIR)
	$(MAKE) -C $(MPFR_TARGET_DIR)

$(STAGING_DIR)/usr/lib/$(MPFR_BINARY): $(MPFR_TARGET_DIR)/.libs/$(MPFR_BINARY)
	$(MAKE) DESTDIR=$(STAGING_DIR) -C $(MPFR_TARGET_DIR) install
	$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(STAGING_DIR)/usr/lib/libmpfr$(LIBTGTEXT)*

$(TARGET_DIR)/usr/lib/libmpfr.so $(TARGET_DIR)/usr/lib/libmpfr.so.$(MPFR_LIBVERSION) $(TARGET_DIR)/usr/lib/libmpfr.a: $(STAGING_DIR)/usr/lib/$(MPFR_BINARY)
	cp -dpf $(STAGING_DIR)/usr/lib/libmpfr$(LIBTGTEXT)* $(TARGET_DIR)/usr/lib/
ifeq ($(BR2_PACKAGE_LIBMPFR_HEADERS),y)
	cp -dpf $(STAGING_DIR)/usr/include/mpfr.h $(STAGING_DIR)/usr/include/mpf2mpfr.h \
		$(TARGET_DIR)/usr/include/
endif

.PHONY: libmpfr-source

libmpfr-source: $(DL_DIR)/$(MPFR_SOURCE) $(MPFR_PATCH_SOURCE)

libmpfr: $(TARGET_DIR)/usr/lib/libmpfr$(LIBTGTEXT)
stage-libmpfr: $(STAGING_DIR)/usr/lib/$(MPFR_BINARY)

libmpfr-clean:
	rm -f $(TARGET_DIR)/usr/lib/libmpfr.* \
		$(TARGET_DIR)/usr/include/mpfr.h \
		$(TARGET_DIR)/usr/include/mpf2mpfr.h \
		$(STAGING_DIR)/usr/lib/libmpfr* $(STAGING_DIR)/usr/include/mpfr*
	-$(MAKE) -C $(MPFR_TARGET_DIR) clean

libmpfr-dirclean:
	rm -rf $(MPFR_TARGET_DIR)

MPFR_DIR2:=$(TOOLCHAIN_DIR)/mpfr-$(MPFR_VERSION)-host
MPFR_HOST_DIR:=$(TOOLCHAIN_DIR)/mpfr
$(MPFR_DIR2)/.configured: $(MPFR_DIR)/.unpacked $(GMP_HOST_DIR)/lib/$(GMP_HOST_BINARY)
	mkdir -p $(MPFR_DIR2)
	(cd $(MPFR_DIR2); \
		$(HOST_CONFIGURE_OPTS) \
		$(MPFR_DIR)/configure $(QUIET) \
		--prefix="$(MPFR_HOST_DIR)" \
		--build=$(GNU_HOST_NAME) \
		--host=$(GNU_HOST_NAME) \
		--disable-shared \
		--enable-static \
		--with-gmp=$(GMP_HOST_DIR) \
		$(DISABLE_NLS) \
	)
	touch $@

$(MPFR_HOST_DIR)/lib/libmpfr$(HOST_LIBEXT): $(MPFR_DIR2)/.configured
	$(MAKE) -C $(MPFR_DIR2) install

host-libmpfr: $(MPFR_HOST_DIR)/lib/$(MPFR_HOST_BINARY)
host-libmpfr-source: libmpfr-source
host-libmpfr-clean:
	rm -rf $(MPFR_HOST_DIR)
	-$(MAKE) -C $(MPFR_DIR2) clean
host-libmpfr-dirclean:
	rm -rf $(MPFR_HOST_DIR) $(MPFR_DIR2)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_LIBMPFR),y)
TARGETS+=libmpfr
endif
