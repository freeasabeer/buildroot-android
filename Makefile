# Makefile for buildroot2
#
# Copyright (C) 1999-2005 by Erik Andersen <andersen@codepoet.org>
# Copyright (C) 2006-2010 by the Buildroot developers <buildroot@uclibc.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#

#--------------------------------------------------------------
# Just run 'make menuconfig', configure stuff, then run 'make'.
# You shouldn't need to mess with anything beyond this point...
#--------------------------------------------------------------
# absolute path
TOPDIR:=$(shell pwd)
CONFIG_CONFIG_IN=Config.in
CONFIG_DEFCONFIG=.defconfig
CONFIG=package/config
DATE:=$(shell date +%Y%m%d)

noconfig_targets:=menuconfig xconfig config oldconfig randconfig \
	defconfig allyesconfig allnoconfig release \
	randpackageconfig allyespackageconfig allnopackageconfig \
	source-check help

# Strip quotes and then whitespaces
qstrip=$(strip $(subst ",,$(1)))
#"))

# Variables for use in Make constructs
comma:=,
empty:=
space:=$(empty) $(empty)

# $(shell find . -name *_defconfig |sed 's/.*\///')
# Pull in the user's configuration file
ifeq ($(filter $(noconfig_targets),$(MAKECMDGOALS)),)
-include .config
endif

# Override BR2_DL_DIR if shell variable defined
ifneq ($(BUILDROOT_DL_DIR),)
BR2_DL_DIR:=$(BUILDROOT_DL_DIR)
endif

# To put more focus on warnings, be less verbose as default
# Use 'make V=1' to see the full commands
ifdef V
  ifeq ("$(origin V)", "command line")
    KBUILD_VERBOSE=$(V)
  endif
endif
ifndef KBUILD_VERBOSE
  KBUILD_VERBOSE=0
endif

ifeq ($(KBUILD_VERBOSE),1)
  quiet=
  Q=
ifndef VERBOSE
  VERBOSE=1
endif
else
  quiet=quiet_
  Q=@
endif

# we want bash as shell
SHELL:=$(shell if [ -x "$$BASH" ]; then echo $$BASH; \
	else if [ -x /bin/bash ]; then echo /bin/bash; \
	else echo sh; fi; fi)

# kconfig uses CONFIG_SHELL
CONFIG_SHELL:=$(SHELL)

export SHELL CONFIG_SHELL quiet Q KBUILD_VERBOSE VERBOSE

ifndef HOSTAR
HOSTAR:=ar
endif
ifndef HOSTAS
HOSTAS:=as
endif
ifndef HOSTCC
HOSTCC:=gcc
else
endif
ifndef HOSTCXX
HOSTCXX:=g++
endif
ifndef HOSTFC
HOSTFC:=gfortran
endif
ifndef HOSTCPP
HOSTCPP:=cpp
endif
ifndef HOSTLD
HOSTLD:=ld
endif
ifndef HOSTLN
HOSTLN:=ln
endif
ifndef HOSTNM
HOSTNM:=nm
endif
HOSTAR:=$(shell which $(HOSTAR) || type -p $(HOSTAR) || echo ar)
HOSTAS:=$(shell which $(HOSTAS) || type -p $(HOSTAS) || echo as)
HOSTCC:=$(shell which $(HOSTCC) || type -p $(HOSTCC) || echo gcc)
HOSTCXX:=$(shell which $(HOSTCXX) || type -p $(HOSTCXX) || echo g++)
HOSTFC:=$(shell which $(HOSTLD) || type -p $(HOSTLD) || echo || which g77 || type -p g77 || echo gfortran)
HOSTCPP:=$(shell which $(HOSTCPP) || type -p $(HOSTCPP) || echo cpp)
HOSTLD:=$(shell which $(HOSTLD) || type -p $(HOSTLD) || echo ld)
HOSTLN:=$(shell which $(HOSTLN) || type -p $(HOSTLN) || echo ln)
HOSTNM:=$(shell which $(HOSTNM) || type -p $(HOSTNM) || echo nm)

ifndef CFLAGS_FOR_BUILD
CFLAGS_FOR_BUILD:=-g -O2
endif
ifndef CXXFLAGS_FOR_BUILD
CXXFLAGS_FOR_BUILD:=-g -O2
endif
ifndef FCFLAGS_FOR_BUILD
FCFLAGS_FOR_BUILD:=-g -O2
endif
export HOSTAR HOSTAS HOSTCC HOSTCXX HOSTFC HOSTLD


ifeq ($(BR2_HAVE_DOT_CONFIG),y)

# cc-option
# Usage: cflags-y+=$(call cc-option, -march=winchip-c6, -march=i586)
# sets -march=winchip-c6 if supported else falls back to -march=i586
# without checking the latter.
cc-option=$(shell if $(TARGET_CC) $(TARGET_CFLAGS) $(1) -S -o /dev/null -xc /dev/null \
	> /dev/null 2>&1; then echo "$(1)"; else echo "$(2)"; fi ;)

#############################################################
#
# Hide troublesome environment variables from sub processes
#
#############################################################
unexport CROSS_COMPILE
unexport ARCH

#############################################################
#
# Setup the proper filename extensions for the host
#
##############################################################
ifneq ($(findstring linux,$(BR2_GNU_BUILD_SUFFIX)),)
HOST_EXEEXT:=
HOST_LIBEXT:=.a
HOST_SHREXT:=.so
endif
ifneq ($(findstring apple,$(BR2_GNU_BUILD_SUFFIX)),)
HOST_EXEEXT:=
HOST_LIBEXT:=.a
HOST_SHREXT:=.dylib
endif
ifneq ($(findstring cygwin,$(BR2_GNU_BUILD_SUFFIX)),)
HOST_EXEEXT:=.exe
HOST_LIBEXT:=.lib
HOST_SHREXT:=.dll
HOST_LOADLIBES="-lcurses -lintl"
export HOST_LOADLIBES
endif
ifneq ($(findstring mingw,$(BR2_GNU_BUILD_SUFFIX)),)
HOST_EXEEXT:=.exe
HOST_LIBEXT:=.lib
HOST_SHREXT:=.dll
endif

# The preferred type of libs we build for the target
ifeq ($(BR2_PREFER_STATIC_LIB),y)
LIBTGTEXT=.a
#PREFERRED_LIB_FLAGS:=--disable-shared --enable-static
else
LIBTGTEXT=.so
#PREFERRED_LIB_FLAGS:=--disable-static --enable-shared
endif
PREFERRED_LIB_FLAGS:=--enable-static --enable-shared

##############################################################
#
# The list of stuff to build for the target toolchain
# along with the packages to build for the target.
#
##############################################################
ifeq ($(BR2_TOOLCHAIN_BUILDROOT),y)
BASE_TARGETS:=uclibc-configured binutils cross_compiler uclibc-target-utils kernel-headers
else
BASE_TARGETS:=uclibc
endif
TARGETS:=

# silent mode requested?
QUIET:=$(if $(findstring s,$(MAKEFLAGS)),-q)

# Strip off the annoying quoting
ARCH:=$(call qstrip,$(BR2_ARCH))
ifeq ($(ARCH),xtensa)
ARCH:=$(ARCH)_$(call qstrip,$(BR2_xtensa_core_name))
endif
WGET:=$(call qstrip,$(BR2_WGET)) $(SPIDER) $(QUIET)
SVN_CO:=$(call qstrip,$(BR2_SVN_CO)) $(QUIET)
SVN_UP:=$(call qstrip,$(BR2_SVN_UP)) $(QUIET)
BZR_CO:=$(call qstrip,$(BR2_BZR_CO)) $(QUIET)
BZR_UP:=$(call qstrip,$(BR2_BZR_UP)) $(QUIET)
GIT:=$(call qstrip,$(BR2_GIT)) $(QUIET)
ZCAT:=$(call qstrip,$(BR2_ZCAT))
BZCAT:=$(call qstrip,$(BR2_BZCAT))
TAR_OPTIONS=$(call qstrip,$(BR2_TAR_OPTIONS)) -xf

ifneq ("$(origin O)", "command line")
O:=output
else
# other packages might also support Linux-style out of tree builds
# with the O=<dir> syntax (E.G. Busybox does). As make automatically
# forwards command line variable definitions those packages get very
# confused. Fix this by telling make to not do so
MAKEOVERRIDES =
endif

# bash prints the name of the directory on 'cd <dir>' if CDPATH is
# set, so unset it here to not cause problems. Notice that the export
# line doesn't affect the environment of $(shell ..) calls, so
# explictly throw away any output from 'cd' here.
export CDPATH:=
BASE_DIR := $(shell mkdir -p $(O) && cd $(O) >/dev/null && pwd)
$(if $(BASE_DIR),, $(error output directory "$(O)" does not exist))

DL_DIR=$(call qstrip,$(BR2_DL_DIR))
ifeq ($(DL_DIR),)
DL_DIR:=$(TOPDIR)/dl
endif

BUILD_DIR:=$(BASE_DIR)/build

GNU_TARGET_SUFFIX:=-$(call qstrip,$(BR2_GNU_TARGET_SUFFIX))

STAGING_DIR:=$(call qstrip,$(BR2_STAGING_DIR))

# packages compiled for the host goes here
HOST_DIR:=$(BASE_DIR)/host

# stamp (dependency) files go here
STAMP_DIR:=$(BASE_DIR)/stamps

BINARIES_DIR:=$(BASE_DIR)/images
TARGET_DIR:=$(BASE_DIR)/target

# define values for prepatched source trees for toolchains
VENDOR_SITE:=$(call qstrip,$(BR2_VENDOR_SITE))
VENDOR_BINUTILS_RELEASE:=$(call qstrip,$(BR2_VENDOR_BINUTILS_RELEASE))
VENDOR_GCC_RELEASE:=$(call qstrip,$(BR2_VENDOR_GCC_RELEASE))
VENDOR_UCLIBC_RELEASE:=$(call qstrip,$(BR2_VENDOR_UCLIBC_RELEASE))
VENDOR_PATCH_DIR:=$(call qstrip,$(BR2_VENDOR_PATCH_DIR))

BR2_DEPENDS_DIR=$(BUILD_DIR)/buildroot-config

include toolchain/Makefile.in
include package/Makefile.in

#############################################################
#
# You should probably leave this stuff alone unless you know
# what you are doing.
#
#############################################################

all: world

# In this section, we need .config
include .config.cmd

# We also need the various per-package makefiles, which also add
# each selected package to TARGETS if that package was selected
# in the .config file.
ifeq ($(BR2_TOOLCHAIN_BUILDROOT),y)
# avoid pulling in external toolchain which is broken for toplvl parallel builds
# Explicit ordering:
include toolchain/dependencies/dependencies.mk
include toolchain/binutils/binutils.mk
include toolchain/ccache/ccache.mk
include toolchain/elf2flt/elf2flt.mk
include toolchain/gcc/gcc-uclibc-3.x.mk
include toolchain/gcc/gcc-uclibc-4.x.mk
include toolchain/gdb/gdb.mk
include toolchain/kernel-headers/kernel-headers.mk
include toolchain/mklibs/mklibs.mk
include toolchain/sstrip/sstrip.mk
include toolchain/uClibc/uclibc.mk
include toolchain/ipkg-utils/ipkg-utils.mk
else
include toolchain/*/*.mk
endif

ifeq ($(BR2_PACKAGE_LINUX),y)
TARGETS+=linux26-modules
endif

include package/*/*.mk

TARGETS+=target-finalize

ifeq ($(BR2_ENABLE_LOCALE_PURGE),y)
TARGETS+=target-purgelocales
endif

# target stuff is last so it can override anything else
include target/Makefile.in

TARGETS+=erase-fakeroots

TARGETS_CLEAN:=$(patsubst %,%-clean,$(TARGETS))
TARGETS_SOURCE:=$(patsubst %,%-source,$(TARGETS) $(BASE_TARGETS))
TARGETS_DIRCLEAN:=$(patsubst %,%-dirclean,$(TARGETS))
TARGETS_ALL:=$(patsubst %,__real_tgt_%,$(TARGETS))
# all targets depend on the crosscompiler and it's prerequisites
$(TARGETS_ALL): __real_tgt_%: $(BASE_TARGETS) %

$(BR2_DEPENDS_DIR): .config
	rm -rf $@
	mkdir -p $(@D)
	cp -dpRf $(CONFIG)/buildroot-config $@

dirs: $(DL_DIR) $(TOOLCHAIN_DIR) $(BUILD_DIR) $(STAGING_DIR) $(TARGET_DIR) \
	$(HOST_DIR) $(BR2_DEPENDS_DIR) $(BINARIES_DIR) $(STAMP_DIR)

$(BASE_TARGETS): dirs

world: dependencies dirs $(BASE_TARGETS) $(TARGETS_ALL)


.PHONY: all world dirs clean distclean source \
	$(BASE_TARGETS) $(TARGETS) $(TARGETS_ALL) \
	$(TARGETS_CLEAN) $(TARGETS_DIRCLEAN) $(TARGETS_SOURCE) \
	$(DL_DIR) $(TOOLCHAIN_DIR) $(BUILD_DIR) $(STAGING_DIR) $(TARGET_DIR) \
	$(HOST_DIR) $(BR2_DEPENDS_DIR) $(BINARIES_DIR) $(STAMP_DIR)

#############################################################
#
# staging and target directories do NOT list these as
# dependencies anywhere else
#
#############################################################
$(DL_DIR) $(TOOLCHAIN_DIR) $(BUILD_DIR) $(HOST_DIR) $(BINARIES_DIR) $(STAMP_DIR):
	@mkdir -p $@

$(STAGING_DIR):
	@mkdir -p $(STAGING_DIR)/bin
	@mkdir -p $(STAGING_DIR)/lib
ifeq ($(BR2_TOOLCHAIN_SYSROOT),y)
	@mkdir -p $(STAGING_DIR)/usr/lib
else
ifneq ($(BR2_TOOLCHAIN_EXTERNAL),y)
	@ln -snf . $(STAGING_DIR)/usr
	@mkdir -p $(STAGING_DIR)/usr/$(REAL_GNU_TARGET_NAME)
	@ln -snf ../lib $(STAGING_DIR)/usr/lib
	@ln -snf ../lib $(STAGING_DIR)/usr/$(REAL_GNU_TARGET_NAME)/lib
endif
endif
	@mkdir -p $(STAGING_DIR)/usr/include
	@mkdir -p $(STAGING_DIR)/usr/bin

$(BUILD_DIR)/.root:
	mkdir -p $(TARGET_DIR)
	if ! [ -d "$(TARGET_DIR)/bin" ]; then \
		if [ -d "$(TARGET_SKELETON)" ]; then \
			cp -fa $(TARGET_SKELETON)/* $(TARGET_DIR)/; \
		fi; \
		if [ -d "$(TARGET_SKELETON_PATCH)" ]; then \
			toolchain/patch-kernel.sh $(TARGET_DIR) $(TARGET_SKELETON_PATCH)/ \*patch\*; \
		fi; \
		touch $(STAGING_DIR)/.fakeroot.00000; \
	fi
	-find $(TARGET_DIR) -type d -name CVS -print0 -o -name .svn -print0 | xargs -0 rm -rf
	-find $(TARGET_DIR) -type f \( -name .empty -o -name '*~' \) -print0 | xargs -0 rm -rf
	touch $@

$(TARGET_DIR): $(BUILD_DIR)/.root

erase-fakeroots:
	rm -f $(BUILD_DIR)/.fakeroot*

target-finalize:
ifeq ($(BR2_HAVE_DEVFILES),y)
	( scripts/copy.sh $(STAGING_DIR) $(TARGET_DIR) )
else
	rm -rf $(TARGET_DIR)/usr/include $(TARGET_DIR)/usr/lib/pkgconfig
	find $(TARGET_DIR)/lib \( -name '*.a' -o -name '*.la' \) -print0 | xargs -0 rm -f
	find $(TARGET_DIR)/usr/lib \( -name '*.a' -o -name '*.la' \) -print0 | xargs -0 rm -f
endif
ifneq ($(BR2_HAVE_MANPAGES),y)
	rm -rf $(TARGET_DIR)/usr/man $(TARGET_DIR)/usr/share/man
endif
ifneq ($(BR2_HAVE_INFOPAGES),y)
	rm -rf $(TARGET_DIR)/usr/info $(TARGET_DIR)/usr/share/info
endif
	find $(TARGET_DIR) -type f -perm +111 | xargs $(STRIPCMD) 2>/dev/null || true
	$(TARGET_LDCONFIG) -r $(TARGET_DIR) 2>/dev/null

	mkdir -p $(TARGET_DIR)/etc
	echo $(BR2_VERSION)$(shell $(TOPDIR)/scripts/setlocalversion) > \
		$(TARGET_DIR)/etc/br-version

ifneq ($(BR2_ROOTFS_POST_BUILD_SCRIPT),"")
	$(BR2_ROOTFS_POST_BUILD_SCRIPT) $(TARGET_DIR)
endif

ifeq ($(BR2_ENABLE_LOCALE_PURGE),y)
LOCALE_WHITELIST=$(BUILD_DIR)/locales.nopurge
LOCALE_NOPURGE=$(call qstrip,$(BR2_ENABLE_LOCALE_WHITELIST))

target-purgelocales:
	rm -f $(LOCALE_WHITELIST)
	for i in $(LOCALE_NOPURGE); do echo $$i >> $(LOCALE_WHITELIST); done

	for dir in $(wildcard $(addprefix $(TARGET_DIR),/usr/share/locale /usr/share/X11/locale /usr/man /usr/share/man)); \
	do \
		for lang in $$(cd $$dir; ls .|grep -v man); \
		do \
			grep -qx $$lang $(LOCALE_WHITELIST) || rm -rf $$dir/$$lang; \
		done; \
	done
endif

source: $(TARGETS_SOURCE) $(HOST_SOURCE)

_source-check:
	$(MAKE) SPIDER=--spider source

external-deps:
	@$(MAKE) -Bs BR2_WGET=$(TOPDIR)/toolchain/wget-show-external-deps.sh \
		SPIDER=--spider source

ifeq ($(BR2_CONFIG_CACHE),y)
# drop configure cache if configuration is changed
$(BUILD_DIR)/tgt-config.cache: .config
	rm -f $@
	touch $@

$(BASE_TARGETS): | $(BUILD_DIR)/tgt-config.cache
endif

else # ifeq ($(BR2_HAVE_DOT_CONFIG),y)

all: menuconfig

# configuration
# ---------------------------------------------------------------------------

HOSTCFLAGS=$(CFLAGS_FOR_BUILD)
export HOSTCFLAGS

$(CONFIG)/conf:
	@mkdir -p $(CONFIG)/buildroot-config
	$(MAKE) CC="$(HOSTCC)" -C $(CONFIG) conf
	-@if [ ! -f .config ]; then \
		cp $(CONFIG_DEFCONFIG) .config; \
	fi

$(CONFIG)/mconf:
	@mkdir -p $(CONFIG)/buildroot-config
	$(MAKE) CC="$(HOSTCC)" -C $(CONFIG) mconf
	-@if [ ! -f .config ]; then \
		cp $(CONFIG_DEFCONFIG) .config; \
	fi

$(CONFIG)/qconf:
	@mkdir -p $(CONFIG)/buildroot-config
	$(MAKE) CC="$(HOSTCC)" -C $(CONFIG) qconf
	-@if [ ! -f .config ]; then \
		cp $(CONFIG_DEFCONFIG) .config; \
	fi

xconfig: $(CONFIG)/qconf
	@mkdir -p $(CONFIG)/buildroot-config
	@if ! KCONFIG_AUTOCONFIG=$(CONFIG)/buildroot-config/auto.conf \
		KCONFIG_AUTOHEADER=$(CONFIG)/buildroot-config/autoconf.h \
		$(CONFIG)/qconf $(CONFIG_CONFIG_IN); then \
		test -f .config.cmd || rm -f .config; \
	fi

menuconfig: $(CONFIG)/mconf
	@mkdir -p $(CONFIG)/buildroot-config
	@if ! KCONFIG_AUTOCONFIG=$(CONFIG)/buildroot-config/auto.conf \
		KCONFIG_AUTOHEADER=$(CONFIG)/buildroot-config/autoconf.h \
		$(CONFIG)/mconf $(CONFIG_CONFIG_IN); then \
		test -f .config.cmd || rm -f .config; \
	fi

config: $(CONFIG)/conf
	@mkdir -p $(CONFIG)/buildroot-config
	@KCONFIG_AUTOCONFIG=$(CONFIG)/buildroot-config/auto.conf \
		KCONFIG_AUTOHEADER=$(CONFIG)/buildroot-config/autoconf.h \
		$(CONFIG)/conf $(CONFIG_CONFIG_IN)

oldconfig: $(CONFIG)/conf
	@mkdir -p $(CONFIG)/buildroot-config
	@KCONFIG_AUTOCONFIG=$(CONFIG)/buildroot-config/auto.conf \
		KCONFIG_AUTOHEADER=$(CONFIG)/buildroot-config/autoconf.h \
		$(CONFIG)/conf -o $(CONFIG_CONFIG_IN)

randconfig: $(CONFIG)/conf
	@mkdir -p $(CONFIG)/buildroot-config
	@KCONFIG_AUTOCONFIG=$(CONFIG)/buildroot-config/auto.conf \
		KCONFIG_AUTOHEADER=$(CONFIG)/buildroot-config/autoconf.h \
		$(CONFIG)/conf -r $(CONFIG_CONFIG_IN)

allyesconfig: $(CONFIG)/conf
	cat $(CONFIG_DEFCONFIG) > .config
	@mkdir -p $(CONFIG)/buildroot-config
	@KCONFIG_AUTOCONFIG=$(CONFIG)/buildroot-config/auto.conf \
		KCONFIG_AUTOHEADER=$(CONFIG)/buildroot-config/autoconf.h \
		$(CONFIG)/conf -y $(CONFIG_CONFIG_IN)

allnoconfig: $(CONFIG)/conf
	@mkdir -p $(CONFIG)/buildroot-config
	@KCONFIG_AUTOCONFIG=$(CONFIG)/buildroot-config/auto.conf \
		KCONFIG_AUTOHEADER=$(CONFIG)/buildroot-config/autoconf.h \
		$(CONFIG)/conf -n $(CONFIG_CONFIG_IN)

randpackageconfig: $(CONFIG)/conf
	@mkdir -p $(CONFIG)/buildroot-config
	@grep -v BR2_PACKAGE_ .config > .config.nopkg
	@KCONFIG_AUTOCONFIG=$(CONFIG)/buildroot-config/auto.conf \
		KCONFIG_AUTOHEADER=$(CONFIG)/buildroot-config/autoconf.h \
		KCONFIG_ALLCONFIG=.config.nopkg \
		$(CONFIG)/conf -r $(CONFIG_CONFIG_IN)
	@rm -f .config.nopkg

allyespackageconfig: $(CONFIG)/conf
	@mkdir -p $(CONFIG)/buildroot-config
	@grep -v BR2_PACKAGE_ .config > .config.nopkg
	@KCONFIG_AUTOCONFIG=$(CONFIG)/buildroot-config/auto.conf \
		KCONFIG_AUTOHEADER=$(CONFIG)/buildroot-config/autoconf.h \
		KCONFIG_ALLCONFIG=.config.nopkg \
		$(CONFIG)/conf -y $(CONFIG_CONFIG_IN)
	@rm -f .config.nopkg

allnopackageconfig: $(CONFIG)/conf
	@mkdir -p $(CONFIG)/buildroot-config
	@grep -v BR2_PACKAGE_ .config > .config.nopkg
	@KCONFIG_AUTOCONFIG=$(CONFIG)/buildroot-config/auto.conf \
		KCONFIG_AUTOHEADER=$(CONFIG)/buildroot-config/autoconf.h \
		KCONFIG_ALLCONFIG=.config.nopkg \
		$(CONFIG)/conf -n $(CONFIG_CONFIG_IN)
	@rm -f .config.nopkg

defconfig: $(CONFIG)/conf
	@mkdir -p $(CONFIG)/buildroot-config
	@KCONFIG_AUTOCONFIG=$(CONFIG)/buildroot-config/auto.conf \
		KCONFIG_AUTOHEADER=$(CONFIG)/buildroot-config/autoconf.h \
		$(CONFIG)/conf -d $(CONFIG_CONFIG_IN)

# check if download URLs are outdated
source-check: allyesconfig
	$(MAKE) _source-check

endif # ifeq ($(BR2_HAVE_DOT_CONFIG),y)

#############################################################
#
# Cleanup and misc junk
#
#############################################################
clean:
	rm -rf $(STAGING_DIR) $(TARGET_DIR) $(BINARIES_DIR) $(HOST_DIR) \
		$(STAMP_DIR) $(BUILD_DIR) $(TOOLCHAIN_DIR)

distclean: clean
ifeq ($(DL_DIR),$(TOPDIR)/dl)
	rm -rf $(DL_DIR)
endif
ifeq ($(O),output)
	rm -rf $(O)
endif
	rm -rf .config .config.old .config.cmd .auto.deps
	-$(MAKE) -C $(CONFIG) clean

flush:
	rm -f $(BUILD_DIR)/tgt-config.cache

%_defconfig: $(TOPDIR)/configs/%_defconfig
	cp $^ .config
	@$(MAKE) oldconfig

configured: dirs host-sed kernel-headers uclibc-config busybox-config linux26-config

prepatch:	gcc-patched binutils-patched gdb-patched uclibc-patched

cross: $(BASE_TARGETS)

help:
	@echo 'Cleaning:'
	@echo '  clean                  - delete all files created by build'
	@echo '  distclean              - delete all non-source files (including .config)'
	@echo
	@echo 'Build:'
	@echo '  all                    - make world'
	@echo
	@echo 'Configuration:'
	@echo '  menuconfig             - interactive curses-based configurator'
	@echo '  xconfig                - interactive Qt-based configurator'
	@echo '  oldconfig              - resolve any unresolved symbols in .config'
	@echo '  randconfig             - New config with random answer to all options'
	@echo '  defconfig              - New config with default answer to all options'
	@echo '  allyesconfig           - New config where all options are accepted with yes'
	@echo '  allnoconfig            - New config where all options are answered with no'
	@echo '  randpackageconfig      - New config with random answer to package options'
	@echo '  allyespackageconfig    - New config where pkg options are accepted with yes'
	@echo '  allnopackageconfig     - New config where package options are answered with no'
	@echo '  configured             - make {uclibc/busybox/linux26}-config'
	@echo
	@echo 'Miscellaneous:'
	@echo '  source                 - download all sources needed for offline-build'
	@echo '  source-check           - check all packages for valid download URLs'
	@echo '  external-deps          - list external packages used'
	@echo '  flush                  - flush configuration cache'
	@echo
	@$(foreach b, $(notdir $(wildcard $(TOPDIR)/configs/*_defconfig)), \
	  printf "  %-35s - Build for %s\\n" $(b) $(b:_defconfig=);)
	@echo
	@echo 'See docs/README and docs/buildroot.html for further details'
	@echo

release:
	OUT=buildroot-$$(grep -A2 BR2_VERSION $(CONFIG_CONFIG_IN)|grep default|cut -f2 -d\"); \
	git archive --format=tar --prefix=$$OUT/ master|gzip -9 >$$OUT.tar.gz

.PHONY: $(noconfig_targets)

