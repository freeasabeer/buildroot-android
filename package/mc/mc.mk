###########################################################
#
# mc
#
###########################################################
MC_VERSION:=4.6.2
MC_SOURCE:=mc-$(MC_VERSION).tar.gz
MC_SITE:=http://www.midnight-commander.org/downloads
MC_DIR:=$(BUILD_DIR)/mc-$(MC_VERSION)
MC_CAT:=$(ZCAT)
MC_BINARY:=src/mc
MC_TARGET_BINARY:=usr/bin/mc

BR2_PACKAGE_MC_STATIC=y
BR2_PACKAGE_MC_ANDROID=y
ifeq ($(BR2_PACKAGE_MC_STATIC),y)
#MC_ENABLE_STATIC = LIBS="-liconv -static"
#MC_ENABLE_STATIC = LIBS="-static"
endif

$(DL_DIR)/$(MC_SOURCE):
	$(call DOWNLOAD,$(MC_SITE),$(MC_SOURCE))

mc-source: $(DL_DIR)/$(MC_SOURCE)

$(MC_DIR)/.unpacked: $(DL_DIR)/$(MC_SOURCE)
	$(MC_CAT) $(DL_DIR)/$(MC_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	$(CONFIG_UPDATE) $(MC_DIR)
ifeq ($(BR2_PACKAGE_MC_ANDROID),y)
	toolchain/patch-kernel.sh $(MC_DIR) package/mc/ terminfo.patch
endif
ifeq ($(BR2_PACKAGE_MC_STATIC),y)
	toolchain/patch-kernel.sh $(MC_DIR) package/mc/ Makefile.in.patch
endif
	touch $@


# configure stuff here #
$(MC_DIR)/.configured: $(MC_DIR)/.unpacked
	(cd $(MC_DIR); rm -rf config.cache; \
	  $(TARGET_CONFIGURE_OPTS) \
	  $(TARGET_CONFIGURE_ARGS) \
	  $(MC_ENABLE_STATIC) \
		./configure \
		--build=$(GNU_HOST_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--target=$(GNU_TARGET_NAME) \
		--prefix=/usr \
		--with-screen=slang \
		--disable-nls \
		--with-glib-prefix=$(STAGING_DIR) \
		--disable-glibtest \
		--enable-charset \
		--without-gpm-mouse \
		--without-x \
	)
	touch $@


$(MC_DIR)/$(MC_BINARY): $(MC_DIR)/.configured
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(MC_DIR)

$(TARGET_DIR)/$(MC_TARGET_BINARY): $(MC_DIR)/$(MC_BINARY)
	install -D $(MC_DIR)/$(MC_BINARY) $(TARGET_DIR)/$(MC_TARGET_BINARY)
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)/$(MC_TARGET_BINARY)

mc: uclibc libglib2 slang2 e2fsprogs $(TARGET_DIR)/$(MC_TARGET_BINARY)

mc-clean:
	rm -f $(TARGET_DIR)/$(MC_TARGET_BINARY)
	-$(MAKE) -C $(MC_DIR) clean

mc-dirclean:
	rm -rf $(MC_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_MC),y)
TARGETS+=mc
endif
