#############################################################
#
# rsync
#
#############################################################

RSYNC_VERSION:=3.0.7
RSYNC_SOURCE:=rsync-$(RSYNC_VERSION).tar.gz
RSYNC_SITE:=http://rsync.samba.org/ftp/rsync/src
RSYNC_INSTALL_STAGING:=NO
RSYNC_INSTALL_TARGET:=YES
RSYNC_CONF_OPT=$(if $(BR2_ENABLE_DEBUG),--enable-debug,--disable-debug) --with-rsh=dropbear
ifeq ($(BR2_ENABLE_DEBUG),y)
RSYNC_INSTALL_TARGET_OPT:=DESTDIR=$(TARGET_DIR) INSTALLCMD='./install-sh -c' \
			  install
else
RSYNC_INSTALL_TARGET_OPT:=DESTDIR=$(TARGET_DIR) INSTALLCMD='./install-sh -c' \
			  STRIPPROG="$(TARGET_STRIP)" install-strip
endif
RSYNC_CONF_OPT:=--with-included-popt

$(eval $(call AUTOTARGETS,package,rsync))
