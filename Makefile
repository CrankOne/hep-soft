# This makefile is targeting on the publishing of docker images together with
# corresponding builds. It defines some convenient targets that correspond to
# image & binary packages preparation stages. Despite it is not fully automated
# (yet), the way it is done now provides nice assistance during build
# preparation routines.
#
# Sections:
#  	* User variables
#  	* Inferred variables
#  	* Virtual targets
#  	* Docker images targets
#  	* Utility targets
#  	* aux targets

#     _______________
# __/ User variables \_________________________________________________________

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
# Note: for SELinux do not forget to run
# 	$ chcon -Rt svirt_sandbox_file_t /var/hepfarm/pkgs
PKGS_LOCAL_DIR=/var/hepfarm/pkgs

# Remote host to publish packages (rsync used)
REMOTE_HOST=crank.qcrypt.org
# Directory on remote host for packages to be published (rsync used)
REMOTE_DIR=/var/www/15-hepsoft-pkgs/

# Docker command to use. By default expects user named `collector' to exist
# in the system.
DOCKER=sudo -u collector docker
# Python executable
PYTHON=python
# Options for creating an archive of root filesystem additions.
ARCHIVE_OPTS=--exclude=.keep --exclude=*.sw? --exclude=.git
# Directory for temporary output of root filesystem subtrees
TMP_DIR=/tmp/hep-soft

#     ___________________
# __/ Inferred Variables \_____________________________________________________

# Common suffix identifying the build (like amd64.opt.20200214)
SUFFIX=$(PLATFORM).$(BINFARM_TYPE).$(PORTAGE_TAG)
# Local directory where this build's packages will be stored
PKGS_LOCAL_CURRENT_DIR=$(PKGS_LOCAL_DIR)/$(SUFFIX)
# All package sets in hepfarm
ALL_SETS=$(shell $(PYTHON) gst.py -l -c presets/spec-hepsoft.yaml)
# Full build version variable
HEPSOFT_VERSION=$(SUFFIX).$(shell git rev-parse --short HEAD)

# GUARD is a function which calculates md5 sum for its
# argument variable name. Note, that both cut and md5sum are
# members of coreutils package so they should be available on
# nearly all systems.
# see: https://stackoverflow.com/questions/11647859/make-targets-depend-on-variables
GUARD = $(1)_GUARD_$(shell echo $($(1)) | md5sum | cut -d ' ' -f 1)

#     ________________
# __/ Virtual Targets \________________________________________________________

all: pkgs

clean:
	rm -f context.*.d/root.d.tar

# TODO:
# clean-images:
# 	...

# virtual target -- alias for base binfarm image
binfarm: image-binfarm-$(SUFFIX).txt

# virtual target -- "all included" binfarm image
hepfarm: image-hepsoft-$(SUFFIX).txt

# virtual target for publishing packages on remote host
publish-pkgs:
	rsync -av --info=progress2 --perms --chmod=a+r \
		$(PKGS_LOCAL_CURRENT_DIR) $(REMOTE_HOST):$(REMOTE_DIR)

# Produces packages (long-running task!)
# TODO: directory for emerge's logs (--quiet-build=y)
pkgs: image-hepsoft-$(SUFFIX).txt | $(PKGS_LOCAL_CURRENT_DIR)
	$(DOCKER) run --rm \
		-v $(PKGS_LOCAL_CURRENT_DIR):/var/cache/binpkgs:z \
		$(shell cat $<) \
		/bin/bash -c 'sudo emerge -g --keep-going=y --quiet-build=y $(ALL_SETS) ; sudo quickpkg --include-config=y "*/*"'

$(call GUARD,HEPSOFT_VERSION):
	rm -rf HEPSOFT_VERSION*
	touch $@

#     ______________________
# __/ Docker Images Targets \__________________________________________________

# TODO
#image-hepsoft-publish:
#	...

# Produces image ready for building packages
image-hepsoft-$(SUFFIX).txt: image-binfarm-$(SUFFIX).txt \
							 context.hepsoft.d/root.d.tar \
							 context.hepsoft.d/Dockerfile
	$(DOCKER) build -t hepsoft-$(PLATFORM)-$(BINFARM_TYPE):$(PORTAGE_TAG) \
				--iidfile $@ \
				--build-arg BASE_IMG=$(shell cat $<) \
		   		context.hepsoft.d

# Produces bootstrapping image
image-binfarm-$(SUFFIX).txt: context.binfarm.d/root.d.tar \
							 context.binfarm.d/Dockerfile
	$(DOCKER) build -t binfarm-$(PLATFORM)-$(BINFARM_TYPE):$(PORTAGE_TAG) \
				--iidfile $@ \
				--build-arg PORTAGE_TAG=$(PORTAGE_TAG) \
				--build-arg PLATFORM=$(PLATFORM) \
				--build-arg STAGE3_TAG=$(STAGE3_TAG) \
				--build-arg GENTOO_PROFILE=$(GENTOO_PROFILE) \
		context.binfarm.d

#     ________________
# __/ Utility Targets \________________________________________________________

# Complete subtree for image (pattern rule)
.SECONDEXPANSION:
context.%.d/root.d.tar: $$(shell find root.%.d -type f -print) \
                        presets/spec-%.yaml \
                      | $(TMP_DIR)
	rm -rf $(TMP_DIR)/*
	cp -r root.$*.d $(TMP_DIR)
	$(PYTHON) gst.py -c presets/spec-$*.yaml -d $(TMP_DIR)/root.$*.d
	echo "MAKEOPTS=\"-j$(shell nproc)\"" > $(TMP_DIR)/root.$*.d/etc/portage/make.conf
	tar cf $@ $(ARCHIVE_OPTS) -C $(TMP_DIR)/root.$*.d .

root.binfarm.d/etc/hepsoft-version.txt: $(call GUARD,HEPSOFT_VERSION)
	echo $(HEPSOFT_VERSION) > $@

# Temp dir for rendering the root filesystems
$(TMP_DIR):
	mkdir -p $@

$(PKGS_LOCAL_CURRENT_DIR):
	sudo -u collector mkdir -p $(PKGS_LOCAL_CURRENT_DIR)

#     ____________
# __/ Aux targets \____________________________________________________________

# runs local packages file server
# WARNING: must be stopped manually, with ctrl+C. Or with `docker stop ...',
# when ran with -d.
pkg-srv.txt:
	$(DOCKER) run --rm -ti \
				--cidfile $@ \
				--volume /var/hepfarm/pkgs:/var/www/localhost/htdocs \
				--volume $(shell readlink -f srv/lighttpd.conf):/etc/lighttpd/lighttpd.conf \
				-p 8789:80 sebp/lighttpd

.PHONY: all clean binfarm hepfarm pkgs publish-pkgs
