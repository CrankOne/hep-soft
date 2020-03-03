# This makefile prepares the archives with configuration files for further
# deployment on the container environment

# For variants see e.g.:
#   https://hub.docker.com/r/gentoo/portage/tags
PORTAGE_TAG=20200222
# Possible choices are: x86, x86-hardened, amd64, amd64-nomultilib,
# amd64-hardened, amd64-hardened-nomultilib. See:
# 	https://hub.docker.com/u/gentoo
PLATFORM=amd64
# For variants see e.g.:
#   https://hub.docker.com/r/gentoo/stage3-amd64/tags
STAGE3_TAG=20200301
# Possible choices are: opt, dbg -- assumed to coincide with one of the custom
# profile (see
BINFARM_TYPE=opt
# Gentoo profile to be set
GENTOO_PROFILE=q-crypt-hep:binfarm/$(BINFARM_TYPE)
# Base directory where output packages will be written
# Note: for SELinux do not forget to make chcon -Rt svirt_sandbox_file_t /var/hepfarm/pkgs
PKGS_LOCAL_DIR=/var/hepfarm/pkgs

# Docker command to use. By default expects user named `collector' to exist
# in the system.
DOCKER=sudo -u collector docker
# Python executable
PYTHON=python
# Options for creating an archive of root filesystem additions.
ARCHIVE_OPTS=--exclude=.keep --exclude=*.sw? --exclude=.git
# Directory for temporary output of root filesystem subtrees
TMP_DIR=/tmp/hep-soft

PKGS_LOCAL_CURRENT_DIR=$(PKGS_LOCAL_DIR)/$(PLATFORM).$(BINFARM_TYPE).$(PORTAGE_TAG)

ALL_SETS=$(shell $(PYTHON) gst.py -l -c presets/spec-hepsoft.yaml)

all: pkgs

# virtual target -- alias for base binfarm image
binfarm: image-binfarm-$(PLATFORM).$(BINFARM_TYPE).$(PORTAGE_TAG).txt
# virtual target -- "all included" binfarm image
hepfarm: image-hepsoft-$(PLATFORM).$(BINFARM_TYPE).$(PORTAGE_TAG).txt

# virtual target -- produces packages (long-running task!)
# TODO: make archive from dir?
# TODO: directory for emerge's logs (--quiet-build=y)
pkgs: image-hepsoft-$(PLATFORM).$(BINFARM_TYPE).$(PORTAGE_TAG).txt
	sudo -u collector mkdir -p $(PKGS_LOCAL_CURRENT_DIR)
	$(DOCKER) run --rm \
		-v $(PKGS_LOCAL_CURRENT_DIR):/var/cache/binpkgs:z \
		$(shell cat $<) \
		/bin/bash -c 'sudo emerge -g --keep-going=y --quiet-build=y $(ALL_SETS) ; sudo quickpkg --include-config=y "*/*"'

# Packages output directory
$(PKGS_LOCAL_DIR)/$(PLATFORM).$(BINFARM_TYPE).$(PORTAGE_TAG):
	sudo -u collector mkdir -p $(shell dirname $@)
	sudo -u collector touch $@

image-hepsoft-$(PLATFORM).$(BINFARM_TYPE).$(PORTAGE_TAG).txt: context.hepsoft.d/root.d.tar \
														context.hepsoft.d/Dockerfile \
														image-binfarm-$(PLATFORM).$(BINFARM_TYPE).$(PORTAGE_TAG).txt
	$(DOCKER) build -t hepsoft-$(PLATFORM)-$(BINFARM_TYPE):$(PORTAGE_TAG) \
				--iidfile $@ \
				--build-arg BASE_IMG=$(shell cat image-binfarm-$(PLATFORM).$(BINFARM_TYPE).$(PORTAGE_TAG).txt) \
		   		context.hepsoft.d
#
# Produces bootstrapping image
image-binfarm-$(PLATFORM).$(BINFARM_TYPE).$(PORTAGE_TAG).txt: context.binfarm.d/root.d.tar \
                                                              context.binfarm.d/Dockerfile
	$(DOCKER) build -t binfarm-$(PLATFORM)-$(BINFARM_TYPE):$(PORTAGE_TAG) \
				--iidfile $@ \
				--build-arg PORTAGE_TAG=$(PORTAGE_TAG) \
				--build-arg PLATFORM=$(PLATFORM) \
				--build-arg STAGE3_TAG=$(STAGE3_TAG) \
				--build-arg GENTOO_PROFILE=$(GENTOO_PROFILE) \
		context.binfarm.d

# Complete subtree for image
.SECONDEXPANSION:
context.%.d/root.d.tar: $$(shell find root.%.d -type f -print) \
                        presets/spec-%.yaml \
                      | $(TMP_DIR)
	rm -rf $(TMP_DIR)/*
	cp -r root.$*.d $(TMP_DIR)
	$(PYTHON) gst.py -c presets/spec-$*.yaml -d $(TMP_DIR)/root.$*.d
	echo "MAKEOPTS=\"-j$(shell nproc)\"" > $(TMP_DIR)/root.$*.d/etc/portage/make.conf
	tar cf $@ $(ARCHIVE_OPTS) -C $(TMP_DIR)/root.$*.d .

# Temp dir for rendering the root filesystems
$(TMP_DIR):
	mkdir -p $@

clean:
	rm -f context.*.d/root.d.tar

# runs local packages file server
# WARNING: must be stopped manually, with ctrl+C. Or with `docker stop ...',
# when ran with -d.
pkg-srv.txt:
	$(DOCKER) run --rm -ti \
				--cidfile $@ \
				--volume /var/hepfarm/pkgs:/var/www/localhost/htdocs \
				--volume $(shell readlink -f srv/lighttpd.conf):/etc/lighttpd/lighttpd.conf \
				-p 8789:80 sebp/lighttpd

.PHONY: all clean binfarm hepfarm pkgs
