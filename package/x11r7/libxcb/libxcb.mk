#############################################################
#
# libxcb
#
#############################################################
LIBXCB_VERSION = 1.5
LIBXCB_SOURCE = libxcb-$(LIBXCB_VERSION).tar.bz2
LIBXCB_SITE = http://xcb.freedesktop.org/dist/

LIBXCB_INSTALL_STAGING = YES

LIBXCB_AUTORECONF = NO
LIBXCB_LIBTOOL_PATCH = NO
LIBXCB_DEPENDENCIES = host-libxslt pthread-stubs xcb-proto xlib_libXdmcp xlib_libXau
LIBXCB_CONF_ENV = STAGING_DIR="$(STAGING_DIR)"
LIBXCB_MAKE_OPT = XCBPROTO_XCBINCLUDEDIR=$(STAGING_DIR)/usr/share/xcb XCBPROTO_XCBPYTHONDIR=$(STAGING_DIR)/usr/lib/python2.6/site-packages

$(eval $(call AUTOTARGETS,package/x11r7,libxcb))

