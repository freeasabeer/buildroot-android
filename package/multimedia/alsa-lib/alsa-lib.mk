#############################################################
#
# alsa-lib
#
#############################################################
ALSA_LIB_VERSION = 1.0.22
ALSA_LIB_SOURCE = alsa-lib-$(ALSA_LIB_VERSION).tar.bz2
ALSA_LIB_SITE = ftp://ftp.alsa-project.org/pub/lib
ALSA_LIB_INSTALL_STAGING = YES
ALSA_LIB_INSTALL_TARGET = YES

ALSA_LIB_CFLAGS=$(TARGET_CFLAGS)

ALSA_LIB_CONF_OPT = --enable-shared \
		    --enable-static \
		    --with-alsa-devdir=$(call qstrip,$(BR2_PACKAGE_ALSA_LIB_DEVDIR)) \
		    --with-pcm-plugins="$(call qstrip,$(BR2_PACKAGE_ALSA_LIB_PCM_PLUGINS))" \
		    --with-ctl-plugins="$(call qstrip,$(BR2_PACKAGE_ALSA_LIB_CTL_PLUGINS))" \
		    --without-versioned

ifneq ($(BR2_PACKAGE_ALSA_LIB_ALOAD),y)
ALSA_LIB_CONF_OPT += --disable-aload
endif
ifneq ($(BR2_PACKAGE_ALSA_LIB_MIXER),y)
ALSA_LIB_CONF_OPT += --disable-mixer
endif
ifneq ($(BR2_PACKAGE_ALSA_LIB_PCM),y)
ALSA_LIB_CONF_OPT += --disable-pcm
endif
ifneq ($(BR2_PACKAGE_ALSA_LIB_RAWMIDI),y)
ALSA_LIB_CONF_OPT += --disable-rawmidi
endif
ifneq ($(BR2_PACKAGE_ALSA_LIB_HWDEP),y)
ALSA_LIB_CONF_OPT += --disable-hwdep
endif
ifneq ($(BR2_PACKAGE_ALSA_LIB_SEQ),y)
ALSA_LIB_CONF_OPT += --disable-seq
endif
ifneq ($(BR2_PACKAGE_ALSA_LIB_ALISP),y)
ALSA_LIB_CONF_OPT += --disable-alisp
endif
ifneq ($(BR2_PACKAGE_ALSA_LIB_OLD_SYMBOLS),y)
ALSA_LIB_CONF_OPT += --disable-old-symbols
endif

ifeq ($(BR2_ENABLE_DEBUG),y)
# install-exec doesn't install the config files
ALSA_LIB_INSTALL_TARGET_OPT = DESTDIR=$(TARGET_DIR) install
ALSA_LIB_CONF_OPT += --enable-debug
endif

ifeq ($(BR2_avr32),y)
ALSA_LIB_CFLAGS+=-DAVR32_INLINE_BUG
endif

ifeq ($(BR2_PACKAGE_ALSA_LIB_PYTHON),y)
ALSA_LIB_CONF_OPT += --with-pythonlibs=-lpython$(PYTHON_VERSION_MAJOR)
ALSA_LIB_CFLAGS+=-I$(STAGING_DIR)/usr/include/python$(PYTHON_VERSION_MAJOR)
ALSA_LIB_DEPENDENCIES = libpython
else
ALSA_LIB_CONF_OPT += --disable-python
endif

ifeq ($(BR2_SOFT_FLOAT),y)
ALSA_LIB_CONF_OPT += --with-softfloat
endif

ALSA_LIB_CONF_ENV = CFLAGS="$(ALSA_LIB_CFLAGS)" \
		    LDFLAGS="$(TARGET_LDFLAGS) -lm"
# the above doesn't work with shared config.cache
ALSA_LIB_USE_CONFIG_CACHE = NO

$(eval $(call AUTOTARGETS,package/multimedia,alsa-lib))

$(ALSA_LIB_TARGET_UNINSTALL):
	-rm -f $(TARGET_DIR)/usr/lib/libasound.so*
	-rm -rf $(TARGET_DIR)/usr/lib/alsa-lib
	-rm -rf $(TARGET_DIR)/usr/share/alsa

$(ALSA_LIB_TARGET_CLEAN):
	-rm -f $(STAGING_DIR)/usr/lib/libasound.*
	-rm -rf $(STAGING_DIR)/usr/lib/alsa-lib
	-rm -rf $(STAGING_DIR)/usr/share/alsa

