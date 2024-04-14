PREFIX ?= /usr
DATADIR ?= $(CURDIR)/debian
BUILDDIR ?= $(DATADIR)/build
DISTFILES ?= $(DATADIR)/third_party

ifeq ($(shell uname -m),aarch64)
  ARCH ?= arm64
else
  ARCH ?= x86_64
endif
TARGET_ARCH ?= $(ARCH)

export LOCALBASE = /usr
export NON_LOCAL_DEPS = $(shell cat $(DATADIR)/non_local_deps)
export SOURCE_DATE_EPOCH = $(shell dpkg-parsechangelog -STimestamp)
export VERSION_EXTRA_SUFFIX = $(shell cat $(DATADIR)/git_version_suffix)
export INCLUDE_PATH = $(BUILDDIR)/include
export PKG_CONFIG_PATH = $(BUILDDIR)/pkgconfig

CFLAGS += -I$(INCLUDE_PATH)
CXXFLAGS += -I$(INCLUDE_PATH)

define JUST_BUILD_CONF
{ "TOOLCHAIN_CONFIG": {"FAMILY": "gnu"}
, "ARCH": "$(ARCH)"
, "TARGET_ARCH": "$(TARGET_ARCH)"
, "SOURCE_DATE_EPOCH": $(SOURCE_DATE_EPOCH)
, "VERSION_EXTRA_SUFFIX": "$(VERSION_EXTRA_SUFFIX)"
, "ADD_CFLAGS": [$(shell printf '"%s"\n' $(CFLAGS) | paste -sd,)]
, "ADD_CXXFLAGS": [$(shell printf '"%s"\n' $(CXXFLAGS) | paste -sd,)]
}
endef
export JUST_BUILD_CONF

# set dummy proxy to prevent _any_ downloads from happening during bootstrap
export http_proxy = http://8.8.8.8:3128
export https_proxy = http://8.8.8.8:3128


all: mustbuild

$(INCLUDE_PATH):
	@mkdir -p $@
	if [ -d $(DATADIR)/include ]; then \
	  cp -r $(DATADIR)/include/. $@; \
	fi

$(PKG_CONFIG_PATH):
	@mkdir -p $@
	if [ -d $(DATADIR)/pkgconfig ]; then \
	  cp -r $(DATADIR)/pkgconfig/. $@; \
	  find $@ -type f -exec sed 's|GEN_INCLUDES|'$(INCLUDE_PATH)'|g' -i {} \;; \
	fi

$(BUILDDIR)/out/bin/must: $(PKG_CONFIG_PATH) $(INCLUDE_PATH)
	env PACKAGE=YES BOOTSTRAP_TARGET=ALL python3 ./bin/bootstrap.py . $(BUILDDIR) $(DISTFILES)
	@touch $@

mustbuild: $(BUILDDIR)/out/bin/must

install: mustbuild
	mkdir -p $(DESTDIR)/$(PREFIX)
	cp -ra $(BUILDDIR)/out/. $(DESTDIR)/$(PREFIX)/.

clean:
	rm -rf $(BUILDDIR)/*

distclean: clean
	rm -rf $(BUILDDIR)

.PHONY: all mustbuild install clean distclean
