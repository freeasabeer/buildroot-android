#############################################################
#
# build ccache to make recompiles faster on the build system
#
#############################################################
CCACHE_VER:=2.4
CCACHE_SITE:=http://samba.org/ftp/ccache
CCACHE_SOURCE:=ccache-$(CCACHE_VER).tar.gz
CCACHE_DIR1:=$(TOOLCHAIN_DIR)/ccache-$(CCACHE_VER)
CCACHE_DIR2:=$(BUILD_DIR)/ccache-$(CCACHE_VER)
CCACHE_CAT:=$(ZCAT)
CCACHE_BINARY:=ccache
CCACHE_TARGET_BINARY:=usr/bin/ccache

$(DL_DIR)/$(CCACHE_SOURCE):
	$(call DOWNLOAD,$(CCACHE_SITE),$(CCACHE_SOURCE))

$(CCACHE_DIR1)/.unpacked: $(DL_DIR)/$(CCACHE_SOURCE)
	$(CCACHE_CAT) $(DL_DIR)/$(CCACHE_SOURCE) | tar -C $(TOOLCHAIN_DIR) $(TAR_OPTIONS) -
	touch $@

$(CCACHE_DIR1)/.patched: $(CCACHE_DIR1)/.unpacked
	# WARNING - this will break if the toolchain is moved.
	# Should probably patch things to use a relative path.
	$(SED) "s,getenv(\"CCACHE_PATH\"),\"$(STAGING_DIR)/usr/bin-ccache\",g" \
		$(CCACHE_DIR1)/execute.c
	# WARNING - this will break if the toolchain build dir is deleted
	#	when using the default cache dir location.
	$(SED) "s,getenv(\"CCACHE_DIR\"),\"$(BR2_CCACHE_DIR)\",g" \
		$(CCACHE_DIR1)/ccache.c
	mkdir -p $(CCACHE_DIR1)/cache
	$(CONFIG_UPDATE) $(@D)
	touch $@

$(CCACHE_DIR1)/.configured: $(CCACHE_DIR1)/.patched
	mkdir -p $(CCACHE_DIR1)
	(cd $(CCACHE_DIR1); rm -rf config.cache; \
		CC="$(HOSTCC)" \
		$(CCACHE_DIR1)/configure $(QUIET) \
		--target=$(GNU_HOST_NAME) \
		--host=$(GNU_HOST_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		$(QUIET) \
	)
	touch $@

$(CCACHE_DIR1)/$(CCACHE_BINARY): $(CCACHE_DIR1)/.configured
	$(MAKE) CC="$(HOSTCC)" -C $(CCACHE_DIR1)

$(STAGING_DIR)/$(CCACHE_TARGET_BINARY): $(CCACHE_DIR1)/$(CCACHE_BINARY)
	mkdir -p $(STAGING_DIR)/usr/bin
	cp $(CCACHE_DIR1)/ccache $(STAGING_DIR)/usr/bin
	# Keep the actual toolchain binaries in a directory at the same level.
	# Otherwise, relative paths for include dirs break.
	mkdir -p $(STAGING_DIR)/usr/bin-ccache
	(cd $(STAGING_DIR)/usr/bin-ccache; \
		ln -fs $(REAL_GNU_TARGET_NAME)-gcc $(GNU_TARGET_NAME)-gcc; \
		ln -fs $(REAL_GNU_TARGET_NAME)-gcc $(GNU_TARGET_NAME)-cc; \
		ln -fs $(REAL_GNU_TARGET_NAME)-gcc $(REAL_GNU_TARGET_NAME)-cc; \
	)
	[ -f $(STAGING_DIR)/usr/bin/$(REAL_GNU_TARGET_NAME)-gcc ] && \
		mv $(STAGING_DIR)/usr/bin/$(REAL_GNU_TARGET_NAME)-gcc \
			$(STAGING_DIR)/usr/bin-ccache/
	(cd $(STAGING_DIR)/usr/bin; \
		ln -fs ccache $(GNU_TARGET_NAME)-cc; \
		ln -fs ccache $(GNU_TARGET_NAME)-gcc; \
		ln -fs ccache $(REAL_GNU_TARGET_NAME)-cc; \
		ln -fs ccache $(REAL_GNU_TARGET_NAME)-gcc; \
	)
ifeq ($(BR2_INSTALL_LIBSTDCPP),y)
	[ -f $(STAGING_DIR)/usr/bin/$(REAL_GNU_TARGET_NAME)-c++ ] && \
		mv $(STAGING_DIR)/usr/bin/$(REAL_GNU_TARGET_NAME)-c++ \
			$(STAGING_DIR)/usr/bin-ccache/
	[ -f $(STAGING_DIR)/usr/bin/$(REAL_GNU_TARGET_NAME)-g++ ] && \
		mv $(STAGING_DIR)/usr/bin/$(REAL_GNU_TARGET_NAME)-g++ \
			$(STAGING_DIR)/usr/bin-ccache/
	(cd $(STAGING_DIR)/usr/bin; \
		ln -fs ccache $(GNU_TARGET_NAME)-c++; \
		ln -fs ccache $(GNU_TARGET_NAME)-g++;\
		ln -fs ccache $(REAL_GNU_TARGET_NAME)-c++; \
		ln -fs ccache $(REAL_GNU_TARGET_NAME)-g++; \
	)
	(cd $(STAGING_DIR)/usr/bin-ccache; \
		ln -fs $(REAL_GNU_TARGET_NAME)-c++ $(GNU_TARGET_NAME)-c++; \
		ln -fs $(REAL_GNU_TARGET_NAME)-g++ $(GNU_TARGET_NAME)-g++; \
	)
endif

ccache: gcc $(STAGING_DIR)/$(CCACHE_TARGET_BINARY)

ccache-clean:
	rm -rf $(STAGING_DIR)/usr/bin/$(GNU_TARGET_NAME)-cc
	rm -rf $(STAGING_DIR)/usr/bin/$(GNU_TARGET_NAME)-gcc
	rm -rf $(STAGING_DIR)/usr/bin/$(REAL_GNU_TARGET_NAME)-cc
	rm -rf $(STAGING_DIR)/usr/bin/$(REAL_GNU_TARGET_NAME)-gcc
	if [ -f $(STAGING_DIR)/usr/bin-ccache/$(REAL_GNU_TARGET_NAME)-gcc ]; then \
		mv $(STAGING_DIR)/usr/bin-ccache/$(REAL_GNU_TARGET_NAME)-gcc \
			$(STAGING_DIR)/usr/bin/; \
		(cd $(STAGING_DIR)/usr/bin; \
			ln -fs $(REAL_GNU_TARGET_NAME)-gcc \
				$(REAL_GNU_TARGET_NAME)-cc; \
			ln -fs $(REAL_GNU_TARGET_NAME)-gcc \
				$(GNU_TARGET_NAME)-cc; \
			ln -fs $(REAL_GNU_TARGET_NAME)-gcc \
				$(GNU_TARGET_NAME)-gcc; \
		); \
	fi
	if [ -f $(STAGING_DIR)/usr/bin-ccache/$(REAL_GNU_TARGET_NAME)-c++ ]; then \
		rm -f $(STAGING_DIR)/usr/bin/$(REAL_GNU_TARGET_NAME)-c++; \
		mv $(STAGING_DIR)/usr/bin-ccache/$(REAL_GNU_TARGET_NAME)-c++ \
			$(STAGING_DIR)/usr/bin/; \
	fi
	if [ -f $(STAGING_DIR)/usr/bin-ccache/$(REAL_GNU_TARGET_NAME)-g++ ]; then \
		rm -f $(STAGING_DIR)/usr/bin/$(REAL_GNU_TARGET_NAME)-g++; \
		mv $(STAGING_DIR)/usr/bin-ccache/$(REAL_GNU_TARGET_NAME)-g++ \
			$(STAGING_DIR)/usr/bin/; \
	fi
	rm -rf $(STAGING_DIR)/usr/bin-ccache/*
	(cd $(STAGING_DIR)/usr/bin; \
		ln -fs $(REAL_GNU_TARGET_NAME)-g++ $(GNU_TARGET_NAME)-c++; \
		ln -fs $(REAL_GNU_TARGET_NAME)-g++ $(GNU_TARGET_NAME)-g++; \
		ln -fs $(REAL_GNU_TARGET_NAME)-g++ $(REAL_GNU_TARGET_NAME)-c++; \
	)
	-$(MAKE) -C $(CCACHE_DIR1) clean

ccache-dirclean:
	rm -rf $(CCACHE_DIR1)




#############################################################
#
# build ccache for use on the target system
#
#############################################################

$(CCACHE_DIR2)/.unpacked: $(DL_DIR)/$(CCACHE_SOURCE)
	$(CCACHE_CAT) $(DL_DIR)/$(CCACHE_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $@

$(CCACHE_DIR2)/.patched: $(CCACHE_DIR2)/.unpacked
	touch $@

$(CCACHE_DIR2)/.configured: $(CCACHE_DIR2)/.patched
	mkdir -p $(CCACHE_DIR2)
	(cd $(CCACHE_DIR2); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(CCACHE_DIR2)/configure $(QUIET) \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--sysconfdir=/etc \
		$(DISABLE_NLS) \
		$(QUIET) \
	)
	touch $@

$(CCACHE_DIR2)/$(CCACHE_BINARY): $(CCACHE_DIR2)/.configured
	$(MAKE) -C $(CCACHE_DIR2) CFLAGS="$(TARGET_CFLAGS)"

$(TARGET_DIR)/$(CCACHE_TARGET_BINARY): $(CCACHE_DIR2)/$(CCACHE_BINARY)
	$(MAKE) DESTDIR=$(TARGET_DIR) -C $(CCACHE_DIR2) install
	# put a bunch of symlinks into /bin, since that is earlier
	# in the default PATH than /usr/bin where gcc lives
	(cd $(TARGET_DIR)/bin; \
		ln -fs /usr/bin/ccache cc; \
		ln -fs /usr/bin/ccache gcc; \
		ln -fs /usr/bin/ccache c++; \
		ln -fs /usr/bin/ccache g++; \
	)

ccache_target: uclibc $(TARGET_DIR)/$(CCACHE_TARGET_BINARY)

ccache_target-sources: $(DL_DIR)/$(CCACHE_SOURCE)

ccache_target-clean:
	rm -f $(TARGET_DIR)/$(CCACHE_TARGET_BINARY) \
	      $(addprefix $(TARGET_DIR)/bin/,cc gcc c++ g++)
	-$(MAKE) -C $(CCACHE_DIR2) clean

ccache_target-dirclean:
	rm -rf $(CCACHE_DIR2)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_CCACHE),y)
TARGETS+=ccache
endif
ifeq ($(BR2_PACKAGE_CCACHE_TARGET),y)
TARGETS+=ccache_target
endif
