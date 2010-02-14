#############################################################
#
# ipkg-utils
#
#############################################################

IPKG_UTILS_VERSION = 1.7
IPKG_UTILS_SOURCE = ipkg-utils-$(IPKG_UTILS_VERSION).tar.gz
IPKG_UTILS_SITE = http://www.handhelds.org/download/packages/ipkg-utils
IPKG_UTILS_INSTALL_STAGING = NO
IPKG_UTILS_INSTALL_TARGET = NO
HOST_IPKG_UTILS_LIBTOOL_PATCH = NO

define HOST_IPKG_UTILS_CONFIGURE_CMDS
  (toolchain/patch-kernel.sh $(HOST_IPKG_UTILS_DIR) toolchain/ipkg-utils/ ipkg-utils\*.patch)
endef

#  ($(HOST_MAKE_ENV) $(MAKE) PREFIX="$(STAGING_DIR)/usr" -C $(HOST_IPKG_UTILS_DIR) install)
define HOST_IPKG_UTILS_INSTALL_CMDS
  ($(INSTALL) -m 755 $(HOST_IPKG_UTILS_DIR)/ipkg-build \
                     $(HOST_IPKG_UTILS_DIR)/ipkg-deb-unbuild \
                     $(HOST_IPKG_UTILS_DIR)/ipkg-unbuild \
                     $(HOST_IPKG_UTILS_DIR)/ipkg-compare-versions \
                     $(HOST_IPKG_UTILS_DIR)/ipkg-upload \
                     $(HOST_IPKG_UTILS_DIR)/ipkg-buildpackage \
                     $(HOST_IPKG_UTILS_DIR)/ipkg-make-index \
                     $(HOST_IPKG_UTILS_DIR)/ipkg.py \
                     $(STAGING_DIR)/usr/bin)
endef

$(eval $(call AUTOTARGETS,toolchain,ipkg-utils,host))

