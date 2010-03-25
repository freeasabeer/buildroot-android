################################################################################
#
# font-screen-cyrillic -- No description available
#
################################################################################

XFONT_FONT_SCREEN_CYRILLIC_VERSION = 1.0.2
XFONT_FONT_SCREEN_CYRILLIC_SOURCE = font-screen-cyrillic-$(XFONT_FONT_SCREEN_CYRILLIC_VERSION).tar.bz2
XFONT_FONT_SCREEN_CYRILLIC_SITE = http://xorg.freedesktop.org/releases/individual/font
XFONT_FONT_SCREEN_CYRILLIC_AUTORECONF = NO
XFONT_FONT_SCREEN_CYRILLIC_INSTALL_STAGING_OPT = DESTDIR=$(STAGING_DIR) MKFONTSCALE=/usr/bin/mkfontscale MKFONTDIR=/usr/bin/mkfontdir FCCACHE=/usr/bin/fc-cache install
XFONT_FONT_SCREEN_CYRILLIC_INSTALL_TARGET_OPT = DESTDIR=$(TARGET_DIR) MKFONTSCALE=/usr/bin/mkfontscale MKFONTDIR=/usr/bin/mkfontdir FCCACHE=/usr/bin/fc-cache install-data
XFONT_FONT_SCREEN_CYRILLIC_DEPENDENCIES = xfont_font-util

$(eval $(call AUTOTARGETS,package/x11r7,xfont_font-screen-cyrillic))

