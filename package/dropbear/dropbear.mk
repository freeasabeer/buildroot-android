#############################################################
#
# dropbear
#
#############################################################

DROPBEAR_VERSION = 0.52
DROPBEAR_SOURCE = dropbear-$(DROPBEAR_VERSION).tar.gz
DROPBEAR_SITE = http://matt.ucc.asn.au/dropbear/releases
DROPBEAR_DEPENDENCIES = zlib
DROPBEAR_TARGET_BINS = dbclient dropbearkey dropbearconvert scp ssh
# make PROGRAMS="dropbear dbclient scp" MULTI=1 STATIC=1 SCPPROGRESS=1
#DROPBEAR_MAKE =	$(MAKE) MULTI=1 SCPPROGRESS=1 \
#		PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp"
DROPBEAR_MAKE =	$(MAKE) MULTI=1 STATIC=1 SCPPROGRESS=1 \
		PROGRAMS="dropbear dbclient dropbearkey scp"
DROPBEAR_CONF_OPT=--prefix=/system --bindir=/system/xbin --disable-loginfunc --disable-utmp --disable-utmpx --disable-wtmp --disable-wtmpx --disable-lastlog

define DROPBEAR_CONFIGURE_CMDS
  (cd $(@D) && rm -rf config.cache && \
  $(TARGET_CONFIGURE_OPTS) \
  $(TARGET_CONFIGURE_ARGS) \
  $(TARGET_CONFIGURE_ENV) \
  $(DROPBEAR_CONF_ENV) \
  ./configure \
    --cache-file="$(BUILD_DIR)/tgt-config.cache" \
    --target=$(GNU_TARGET_NAME) \
    --host=$(GNU_TARGET_NAME) \
    --build=$(GNU_HOST_NAME) \
    ./configure \
    $(DROPBEAR_CONF_OPT) \
  )
endef

$(eval $(call AUTOTARGETS,package,dropbear))

$(DROPBEAR_HOOK_POST_EXTRACT):
	$(SED) 's,^#define XAUTH_COMMAND.*/xauth,#define XAUTH_COMMAND "/usr/bin/xauth,g' $(DROPBEAR_DIR)/options.h
	touch $@

$(DROPBEAR_TARGET_INSTALL_TARGET):
	$(call MESSAGE,"Installing to target")
	$(INSTALL) -m 755 $(DROPBEAR_DIR)/dropbearmulti \
		$(TARGET_DIR)/usr/sbin/dropbear
	ln -snf ../sbin/dropbear $(TARGET_DIR)/usr/bin/dbclient
	ln -snf ../sbin/dropbear $(TARGET_DIR)/usr/bin/dropbearkey
	ln -snf ../sbin/dropbear $(TARGET_DIR)/usr/bin/dropbearconvert
	ln -snf ../sbin/dropbear $(TARGET_DIR)/usr/bin/scp
	ln -snf ../sbin/dropbear $(TARGET_DIR)/usr/bin/ssh
	if [ ! -f $(TARGET_DIR)/etc/init.d/S50dropbear ]; then \
		$(INSTALL) -m 0755 -D package/dropbear/S50dropbear $(TARGET_DIR)/etc/init.d/S50dropbear; \
	fi
	touch $@

$(DROPBEAR_TARGET_UNINSTALL):
	$(call MESSAGE,"Uninstalling")
	rm -f $(TARGET_DIR)/usr/sbin/dropbear
	rm -f $(addprefix $(TARGET_DIR)/usr/bin/, $(DROPBEAR_TARGET_BINS))
	rm -f $(TARGET_DIR)/etc/init.d/S50dropbear
	rm -f $(DROPBEAR_TARGET_INSTALL_TARGET) $(DROPBEAR_HOOK_POST_INSTALL)

