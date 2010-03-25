################################################################################
#
# xdriver_xf86-input-aiptek -- Aiptek USB Digital Tablet Input Driver for Linux
#
################################################################################

XDRIVER_XF86_INPUT_AIPTEK_VERSION = 1.3.0
XDRIVER_XF86_INPUT_AIPTEK_SOURCE = xf86-input-aiptek-$(XDRIVER_XF86_INPUT_AIPTEK_VERSION).tar.bz2
XDRIVER_XF86_INPUT_AIPTEK_SITE = http://xorg.freedesktop.org/releases/individual/driver
XDRIVER_XF86_INPUT_AIPTEK_AUTORECONF = NO
XDRIVER_XF86_INPUT_AIPTEK_LIBTOOL_PATCH = NO
XDRIVER_XF86_INPUT_AIPTEK_DEPENDENCIES = xserver_xorg-server xproto_inputproto xproto_randrproto xproto_xproto
XDRIVER_XF86_INPUT_AIPTEK_INSTALL_TARGET_OPT = DESTDIR=$(TARGET_DIR) install

$(eval $(call AUTOTARGETS,package/x11r7,xdriver_xf86-input-aiptek))
