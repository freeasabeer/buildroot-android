#############################################################
#
# slang2
#
#############################################################
SLANG2_VERSION:=2.1.4
SLANG2_SOURCE=slang-$(SLANG2_VERSION).tar.bz2
SLANG2_CAT:=$(BZCAT)
SLANG2_SITE:=ftp://space.mit.edu/pub/davis/slang/v2.1
SLANG2_DIR=$(BUILD_DIR)/slang-$(SLANG2_VERSION)

$(DL_DIR)/$(SLANG2_SOURCE):
	$(call DOWNLOAD,$(SLANG2_SITE),$(SLANG2_SOURCE))

$(SLANG2_DIR)/.unpacked: $(DL_DIR)/$(SLANG2_SOURCE)
	$(SLANG2_CAT) $(DL_DIR)/$(SLANG2_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(SLANG2_DIR) package/slang2/ uclibc.patch slsh-Makefile.patch
	touch $@


$(SLANG2_DIR)/.configured: $(SLANG2_DIR)/.unpacked
	(cd $(SLANG2_DIR); rm -rf config.cache; \
	  $(TARGET_CONFIGURE_OPTS) \
	  $(TARGET_CONFIGURE_ARGS) \
	  ./configure \
	  --build=$(GNU_HOST_NAME) \
	  --host=$(GNU_TARGET_NAME) \
	  --target=$(GNU_TARGET_NAME) \
	  --prefix=/usr \
	  --disable-nls \
	  --disable-static \
	  --with-pcre \
	  --with-png \
	  --with-iconv \
	  $(SLANG2_CONFIGURE_ARGS) \
	)
	sed -i -e '/^LIBS =/s|$$| $$(LDFLAGS)|' $(SLANG2_DIR)/modules/Makefile
	touch $@


$(SLANG2_DIR)/.built: $(SLANG2_DIR)/.configured
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(SLANG2_DIR)
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(SLANG2_DIR) static
	touch $@


$(SLANG2_DIR)/.staged: $(SLANG2_DIR)/.built
	$(MAKE1) -C $(SLANG2_DIR) DESTDIR=$(STAGING_DIR) install-elf
	$(MAKE1) -C $(SLANG2_DIR) DESTDIR=$(STAGING_DIR) install-static
	touch $@


$(TARGET_DIR)/.targeted: $(SLANG2_DIR)/.staged
	$(MAKE1) -C $(SLANG2_DIR) DESTDIR=$(TARGET_DIR) install-elf
	$(MAKE1) -C $(SLANG2_DIR) DESTDIR=$(TARGET_DIR) install-static
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)/usr/bin/slsh \
	  $(TARGET_DIR)/usr/lib/libslang.so.$(SLANG2_VERSION) \
	  $(TARGET_DIR)/usr/lib/slang/v2/modules/*.so 
	touch $@


slang2: uclibc pcre libpng libiconv $(TARGET_DIR)/.targeted

slang2-stage:$(SLANG2_DIR)/.staged

slang2-source: $(DL_DIR)/$(SLANG2_SOURCE)


slang2-clean:
	rm -f $(SLANG2_DIR)/.built
	rm -f $(TARGET_DIR)/usr/lib/libslang.so* $(STAGING_DIR)/usr/lib/libslang.a \
		$(STAGING_DIR)/usr/include/slang.h \
		$(STAGING_DIR)/usr/include/slcurses.h
	-$(MAKE) -C $(SLANG2_DIR) clean


slang2-dirclean:
	rm -rf $(SLANG2_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_SLANG2),y)
TARGETS+=slang2
endif
