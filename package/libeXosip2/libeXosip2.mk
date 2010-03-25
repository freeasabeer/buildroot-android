#############################################################
#
# libeXosip2
#
#############################################################

LIBEXOSIP2_VERSION=3.1.0
LIBEXOSIP2_SOURCE=libeXosip2-$(LIBEXOSIP2_VERSION).tar.gz
LIBEXOSIP2_SITE=http://www.antisip.com/download/exosip2
LIBEXOSIP2_DIR=$(BUILD_DIR)/libeXosip2-$(LIBEXOSIP2_VERSION)
LIBEXOSIP2_CAT:=$(ZCAT)

$(DL_DIR)/$(LIBEXOSIP2_SOURCE):
	$(call DOWNLOAD,$(LIBEXOSIP2_SITE),$(LIBEXOSIP2_SOURCE))

$(LIBEXOSIP2_DIR)/.unpacked: $(DL_DIR)/$(LIBEXOSIP2_SOURCE)
	$(LIBEXOSIP2_CAT) $(DL_DIR)/$(LIBEXOSIP2_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	$(CONFIG_UPDATE) $(LIBEXOSIP2_DIR)
	touch $(LIBEXOSIP2_DIR)/.unpacked

$(LIBEXOSIP2_DIR)/.configured: $(LIBEXOSIP2_DIR)/.unpacked
	(cd $(LIBEXOSIP2_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		OSIP_CFLAGS="$(TARGET_CFLAGS)" \
		OSIP_LIBS="-L$(STAGING_DIR)/usr/lib -losip2 -losipparser2" \
		./configure $(QUIET) \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--enable-shared \
		--enable-static \
		$(DISABLE_NLS) \
	)
	touch $@

$(LIBEXOSIP2_DIR)/.compiled: $(LIBEXOSIP2_DIR)/.configured
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(LIBEXOSIP2_DIR)
	touch $@

#LDFLAGS=$(TARGET_LDFLAGS)

$(STAGING_DIR)/usr/lib/libeXosip2.so: $(LIBEXOSIP2_DIR)/.compiled
	cp -dpf $(LIBEXOSIP2_DIR)/src/.libs/libeXosip2.so* $(STAGING_DIR)/usr/lib
	touch $@

$(STAGING_DIR)/usr/lib/libeXosip2.a: $(LIBEXOSIP2_DIR)/.compiled
	cp -dpf $(LIBEXOSIP2_DIR)/src/.libs/libeXosip2.a $(STAGING_DIR)/usr/lib
	cp -dpf $(LIBEXOSIP2_DIR)/include/*.h $(STAGING_DIR)/usr/include
	touch $@

$(STAGING_DIR)/usr/lib/libeXosip2.la: $(LIBEXOSIP2_DIR)/.compiled
	cp -dpf $(LIBEXOSIP2_DIR)/src/libeXosip2.la $(STAGING_DIR)/usr/lib
	$(SED) "s,^libdir=.*,libdir=\'$(STAGING_DIR)/usr/lib\',g" $(STAGING_DIR)/usr/lib/libeXosip2.la
	touch $@

$(STAGING_DIR)/usr/bin/sip_reg: $(LIBEXOSIP2_DIR)/.compiled
	cp -dpf $(LIBEXOSIP2_DIR)/tools/.libs/sip_reg $(STAGING_DIR)/usr/bin
	touch $@


$(TARGET_DIR)/usr/lib/libeXosip2.so: $(STAGING_DIR)/usr/lib/libeXosip2.so
	mkdir -p $(TARGET_DIR)/usr/lib
	cp -dpf $(STAGING_DIR)/usr/lib/libeXosip2.so* $(TARGET_DIR)/usr/lib/
	$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)/usr/lib/libeXosip2.so*
	touch $@

$(TARGET_DIR)/usr/bin/sip_reg: $(STAGING_DIR)/usr/bin/sip_reg
	mkdir -p $(TARGET_DIR)/usr/bin
	cp -dpf $(STAGING_DIR)/usr/bin/sip_reg $(TARGET_DIR)/usr/bin
	touch $@



libeXosip2: libosip2 $(TARGET_DIR)/usr/lib/libeXosip2.so

libeXosip2-source: $(DL_DIR)/$(LIBEXOSIP2_SOURCE)

libeXosip2-clean:
	-$(MAKE) -C $(LIBEXOSIP2_DIR) clean
	-rm -f $(STAGING_DIR)/usr/lib/libeXosip2.*
	-rm -f $(TARGET_DIR)/usr/lib/libeXosip2.*


libeXosip2-dirclean:
	rm -rf $(LIBEXOSIP2_DIR)

.PHONY: libeXosip2-headers libeXosip2-target-headers
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_LIBEXOSIP2),y)
TARGETS+=libeXosip2
endif
