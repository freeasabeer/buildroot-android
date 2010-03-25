#############################################################
#
# sylpheed
#
#############################################################
SYLPHEED_VERSION = 2.4.8
SYLPHEED_SOURCE = sylpheed-$(SYLPHEED_VERSION).tar.bz2
SYLPHEED_SITE = http://sylpheed.sraoss.jp/sylpheed/v2.4
SYLPHEED_AUTORECONF = NO
SYLPHEED_INSTALL_STAGING = NO
SYLPHEED_INSTALL_TARGET = YES
SYLPHEED_INSTALL_TARGET_OPT = DESTDIR=$(TARGET_DIR) install

SYLPHEED_CONF_OPT = --disable-gtkspell --program-prefix=""

SYLPHEED_DEPENDENCIES = host-pkg-config libgtk2

$(eval $(call AUTOTARGETS,package,sylpheed))

