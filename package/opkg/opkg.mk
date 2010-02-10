#############################################################
#
# opkg
#
#############################################################

OPKG_VERSION = 519
OPKG_SOURCE = opkg-$(OPKG_VERSION).tar.gz
OPKG_SITE = http://opkg.googlecode.com/svn/trunk
OPKG_DIR:=$(BUILD_DIR)/opkg-$(OPKG_VERSION)
OPKG_BINARY:= opkg
OPKG_TARGET_BINARY:=usr/bin/opkg

$(DL_DIR)/$(OPKG_SOURCE):
	(mkdir -p $(DL_DIR)/svn && cd $(DL_DIR)/svn; \
	 svn co --revision $(OPKG_VERSION) $(OPKG_SITE) opkg-$(OPKG_VERSION) ; \
	 tar czf $(DL_DIR)/$(OPKG_SOURCE) opkg-$(OPKG_VERSION))

$(OPKG_DIR)/.source: $(DL_DIR)/$(OPKG_SOURCE)
	$(ZCAT) $(DL_DIR)/$(OPKG_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $@

$(OPKG_DIR)/.patched: $(OPKG_DIR)/.source
	toolchain/patch-kernel.sh $(OPKG_DIR) package/opkg/ opkg\*.patch
	touch $@

$(OPKG_DIR)/.configured: $(OPKG_DIR)/.patched
	(cd $(OPKG_DIR); rm -rf config.cache; \
		./autogen.sh; \
		$(TARGET_CONFIGURE_OPTS) \
                $(TARGET_CONFIGURE_ARGS) \
                ./configure \
		--target=$(GNU_TARGET_NAME) --host=$(GNU_TARGET_NAME) --build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--sysconfdir=/data/local \
		--with-opkglibdir=/data/local/opkg/lib \
		--with-opkgetcdir=/data/local \
		--disable-curl --disable-ssl-curl --disable-gpg --disable-shave \
	)
	touch $@

$(OPKG_DIR)/$(OPKG_BINARY): $(OPKG_DIR)/.configured
	$(MAKE) CC=$(TARGET_CC) -C $(OPKG_DIR)

$(TARGET_DIR)/$(OPKG_TARGET_BINARY): $(OPKG_DIR)/$(OPKG_BINARY)
	$(MAKE) DESTDIR=$(TARGET_DIR) -C $(OPKG_DIR) install-strip
	mv $(TARGET_DIR)/usr/bin/opkg-cl $(TARGET_DIR)/$(OPKG_TARGET_BINARY)
	rm -Rf $(TARGET_DIR)/usr/man

opkg: uclibc $(TARGET_DIR)/$(OPKG_TARGET_BINARY)

opkg-source: $(DL_DIR)/$(OPKG_SOURCE)

opkg-clean:
	$(MAKE) prefix=$(TARGET_DIR)/usr -C $(OPKG_DIR) uninstall
	-$(MAKE) -C $(OPKG_DIR) clean

opkg-dirclean:
	rm -rf $(OPKG_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_OPKG),y)
TARGETS+=opkg
endif
