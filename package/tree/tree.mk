#############################################################
#
# tree
#
#############################################################
TREE_VERSION:=1.5.3
TREE_SOURCE:=tree-$(TREE_VERSION).tgz
TREE_SITE:=ftp://mama.indstate.edu/linux/tree
TREE_DIR:=$(BUILD_DIR)/tree-$(TREE_VERSION)
TREE_BINARY:=tree
TREE_TARGET_BINARY:=usr/bin/tree

$(DL_DIR)/$(TREE_SOURCE):
	$(call DOWNLOAD,$(TREE_SITE),$(TREE_SOURCE))

$(TREE_DIR)/.source: $(DL_DIR)/$(TREE_SOURCE)
	$(ZCAT) $(DL_DIR)/$(TREE_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $@

$(TREE_DIR)/.configured: $(TREE_DIR)/.source
	touch $@

$(TREE_DIR)/$(TREE_BINARY): $(TREE_DIR)/.configured
	$(MAKE) CC=$(TARGET_CC) XOBJS=strverscmp.o LDFLAGS=-static -C $(TREE_DIR)

$(TARGET_DIR)/$(TREE_TARGET_BINARY): $(TREE_DIR)/$(TREE_BINARY)
	(cd $(TREE_DIR) && $(TARGET_STRIP) $(TREE_BINARY) && cp $(TREE_BINARY) $(TARGET_DIR)/$(TREE_TARGET_BINARY))

tree: $(TARGET_DIR)/$(TREE_TARGET_BINARY)

tree-source: $(DL_DIR)/$(TREE_SOURCE)

tree-clean:
	$(MAKE) prefix=$(TARGET_DIR)/usr -C $(TREE_DIR) uninstall
	-$(MAKE) -C $(TREE_DIR) clean

tree-dirclean:
	rm -rf $(TREE_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_TREE),y)
TARGETS+=tree
endif

