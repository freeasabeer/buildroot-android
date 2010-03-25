################################################################################
#
# font-micro-misc -- No description available
#
################################################################################

XFONT_FONT_MICRO_MISC_VERSION = 1.0.1
XFONT_FONT_MICRO_MISC_SOURCE = font-micro-misc-$(XFONT_FONT_MICRO_MISC_VERSION).tar.bz2
XFONT_FONT_MICRO_MISC_SITE = http://xorg.freedesktop.org/releases/individual/font
XFONT_FONT_MICRO_MISC_AUTORECONF = NO
XFONT_FONT_MICRO_MISC_INSTALL_STAGING_OPT = DESTDIR=$(STAGING_DIR) MKFONTSCALE=/usr/bin/mkfontscale MKFONTDIR=/usr/bin/mkfontdir FCCACHE=/usr/bin/fc-cache install
XFONT_FONT_MICRO_MISC_INSTALL_TARGET_OPT = DESTDIR=$(TARGET_DIR) MKFONTSCALE=/usr/bin/mkfontscale MKFONTDIR=/usr/bin/mkfontdir FCCACHE=/usr/bin/fc-cache install-data
XFONT_FONT_MICRO_MISC_DEPENDENCIES = xfont_font-util

$(eval $(call AUTOTARGETS,package/x11r7,xfont_font-micro-misc))

