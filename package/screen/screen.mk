#############################################################
#
# screen
#
#############################################################
SCREEN_VERSION = 4.0.2
SCREEN_SITE = $(BR2_GNU_MIRROR)/screen

SCREEN_DEPENDENCIES = ncurses

SCREEN_CONF_ENV = CFLAGS=-DSYSV=1

SCREEN_MAKE_OPT = -j1

SCREEN_INSTALL_TARGET_OPT = DESTDIR=$(TARGET_DIR) SCREEN=screen install_bin

#SCREEN_CONF_OPT = --with-socket-dir=/sdcard/tmp/screens --with-sys-screenrc=/etc/screenrc
$(eval $(call AUTOTARGETS,package,screen))

BR2_PACKAGE_SCREEN_STATIC=y
ifeq ($(BR2_PACKAGE_SCREEN_STATIC),y)
$(info static build required)
$(SCREEN_HOOK_POST_EXTRACT):
	toolchain/patch-kernel.sh $(SCREEN_DIR) package/screen/ screen-static-binary.conditionalpatch
	touch $@
endif

$(SCREEN_TARGET_CONFIGURE):
	(cd $(SCREEN_DIR) && rm -f config.cache &&  \
        $(TARGET_CONFIGURE_OPTS) \
        $(TARGET_CONFIGURE_ARGS) \
        $(TARGET_CONFIGURE_ENV) \
        $(SCREEN_CONF_ENV) \
        ./configure \
        --target=$(GNU_TARGET_NAME) \
        --host=$(GNU_TARGET_NAME) \
        --build=$(GNU_HOST_NAME) \
        --prefix=/usr \
        --exec-prefix=/usr \
        --datadir=/data \
        --sysconfdir=/etc \
        --with-socket-dir=/data/local/tmp/screens \
        --with-sys-screenrc=/data/screen/screenrc \
        )
	touch $@

$(SCREEN_HOOK_POST_INSTALL):
	cp $(SCREEN_DIR)/etc/screenrc $(TARGET_DIR)/etc/screen/screenrc


