#############################################################
#
# htop
#
#############################################################
HTOP_VERSION:=0.8.3
HTOP_SOURCE:=htop-$(HTOP_VERSION).tar.gz
HTOP_SITE:=http://$(BR2_SOURCEFORGE_MIRROR).dl.sourceforge.net/sourceforge/htop
HTOP_DIR:=$(BUILD_DIR)/htop-$(HTOP_VERSION)
HTOP_BINARY:=htop
HTOP_TARGET_BINARY:=usr/bin/htop

$(DL_DIR)/$(HTOP_SOURCE):
	$(call DOWNLOAD,$(HTOP_SITE),$(HTOP_SOURCE))

$(HTOP_DIR)/.unpacked: $(DL_DIR)/$(HTOP_SOURCE)
	$(ZCAT) $(DL_DIR)/$(HTOP_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(HTOP_DIR) package/htop/ Makefile.in.patch
	touch $@

$(HTOP_DIR)/.configured: $(HTOP_DIR)/.unpacked
	(cd $(HTOP_DIR); rm -rf config.cache; \
    $(TARGET_CONFIGURE_OPTS) \
    $(TARGET_CONFIGURE_ARGS) \
    ac_cv_file__proc_stat=yes \
    ac_cv_file__proc_meminfo=yes \
    ./configure $(QUIET) \
    --target=$(GNU_TARGET_NAME) \
    --host=$(GNU_TARGET_NAME) \
    --build=$(GNU_HOST_NAME) \
    --prefix=/usr \
    $(DISABLE_NLS) \
  )
	touch $@


$(HTOP_DIR)/$(HTOP_BINARY): $(HTOP_DIR)/.configured
	$(MAKE) CC=$(TARGET_CC) -C $(HTOP_DIR)
	(cd $(HTOP_DIR) && $(TARGET_CC) -pedantic -Wall -std=c99 -D_XOPEN_SOURCE_EXTENDED -O2 -static -o htop htop-AvailableMetersPanel.o htop-CategoriesPanel.o htop-CheckItem.o htop-ClockMeter.o htop-ColorsPanel.o htop-ColumnsPanel.o htop-CPUMeter.o htop-CRT.o htop-DebugMemory.o htop-DisplayOptionsPanel.o htop-FunctionBar.o htop-Hashtable.o htop-Header.o htop-htop.o htop-ListItem.o htop-LoadAverageMeter.o htop-MemoryMeter.o htop-Meter.o htop-MetersPanel.o htop-Object.o htop-Panel.o htop-BatteryMeter.o htop-Process.o htop-ProcessList.o htop-RichString.o htop-ScreenManager.o htop-Settings.o htop-SignalItem.o htop-SignalsPanel.o htop-String.o htop-SwapMeter.o htop-TasksMeter.o htop-TraceScreen.o htop-UptimeMeter.o htop-UsersTable.o htop-Vector.o htop-AvailableColumnsPanel.o htop-AffinityPanel.o htop-HostnameMeter.o htop-OpenFilesScreen.o  -lpthread ./plpa-1.1/src/.libs/libplpa_included.a -lncurses -lm)
	(cd $(HTOP_DIR) && $(TARGET_STRIP) $(HTOP_BINARY))


$(TARGET_DIR)/$(HTOP_TARGET_BINARY): $(HTOP_DIR)/$(HTOP_BINARY)
	(cd $(HTOP_DIR) && $(TARGET_STRIP) $(HTOP_BINARY) && cp $(HTOP_BINARY) $(TARGET_DIR)/$(HTOP_TARGET_BINARY))

htop: ncurses $(TARGET_DIR)/$(HTOP_TARGET_BINARY)

htop-source: $(DL_DIR)/$(HTOP_SOURCE)

htop-clean:
	$(MAKE) prefix=$(TARGET_DIR)/usr -C $(HTOP_DIR) uninstall
	-$(MAKE) -C $(HTOP_DIR) clean

htop-dirclean:
	rm -rf $(HTOP_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_HTOP),y)
TARGETS+=htop
endif

