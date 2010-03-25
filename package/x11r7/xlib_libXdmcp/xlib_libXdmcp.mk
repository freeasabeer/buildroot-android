################################################################################
#
# xlib_libXdmcp -- X.Org Xdmcp library
#
################################################################################

XLIB_LIBXDMCP_VERSION = 1.0.3
XLIB_LIBXDMCP_SOURCE = libXdmcp-$(XLIB_LIBXDMCP_VERSION).tar.bz2
XLIB_LIBXDMCP_SITE = http://xorg.freedesktop.org/releases/individual/lib
XLIB_LIBXDMCP_AUTORECONF = NO
XLIB_LIBXDMCP_LIBTOOL_PATCH = NO
XLIB_LIBXDMCP_INSTALL_STAGING = YES
XLIB_LIBXDMCP_DEPENDENCIES = xutil_util-macros xproto_xproto
XLIB_LIBXDMCP_CONF_OPT = --enable-shared --disable-static

$(eval $(call AUTOTARGETS,package/x11r7,xlib_libXdmcp))
