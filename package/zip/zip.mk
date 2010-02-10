#############################################################
#
# zip
#
#############################################################
ZIP_VERSION:=30
ZIP_SOURCE:=zip$(ZIP_VERSION).tar.gz
ZIP_SITE:=http://$(BR2_SOURCEFORGE_MIRROR).dl.sourceforge.net/project/infozip/Zip%203.x%20%28latest%29/3.0
ZIP_INSTALL_STAGING=NO

define ZIP_BUILD_CMDS
	(cd $(@D) && $(MAKE) -f unix/Makefile CC="$(TARGET_CC)" CPP="$(TARGET_CPP)" LOCAL_ZIP="-mtune=arm1136jf-s -march=armv6j -mabi=aapcs-linux -msoft-float" generic)
endef

define ZIP_INSTALL_TARGET_CMDS
        mkdir -p $(TARGET_DIR)/usr/bin
        cp -dpf $(@D)/zip $(@D)/zipnote $(@D)/zipcloak $(@D)/zipsplit $(TARGET_DIR)/usr/bin
        -$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)/usr/bin/zip*
endef

$(eval $(call AUTOTARGETS,package,zip))
#$(eval $(call GENTARGETS,package,zip))

$(ZIP_HOOK_POST_EXTRACT):
	toolchain/patch-kernel.sh $(ZIP_DIR) package/zip/ Makefile.patch
	touch $@

$(ZIP_TARGET_CONFIGURE):
	touch $@

$(ZIP_TARGET_INSTALL):
	(cd $(@D) && $(MAKE) -f unix/Makefile CC="$(TARGET_CC)" LOCAL_ZIP="$(TARGET_CFLAGS)" install)
