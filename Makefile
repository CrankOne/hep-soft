# This makefile prepares the archives with configuration files for further
# deployment on the container environment

# For variants see e.g.:
#   https://hub.docker.com/r/gentoo/portage/tags
PORTAGE_TAG=20200214
# Possible choices are: x86, x86-hardened, amd64, amd64-nomultilib,
# amd64-hardened, amd64-hardened-nomultilib. See:
# 	https://hub.docker.com/u/gentoo
PLATFORM=amd64
# For variants see e.g.:
#   https://hub.docker.com/r/gentoo/stage3-amd64/tags
STAGE3_TAG=20200214
# Possible choices are: opt, dbg
BINFARM_TYPE=opt
# Gentoo profile to set
BINFARM_PROFILE=default/linux/amd64/17.1
# Base directory where output packages will be written
# Note: for SELinux do not forget to make chcon -Rt svirt_sandbox_file_t /var/hepfarm/pkgs
PKGS_OUT_DIR=/var/hepfarm/pkgs

# Docker command to use. By default expects user named `collector' to exist
# in the system.
DOCKER=sudo -u collector docker
# Options for creating an archive of root filesystem additions.
ARCHIVE_OPTS=--exclude=.keep --exclude=*.sw?

all: pkgs

# virtual target -- alias for base binfarm image
binfarm: binfarm-$(PLATFORM).$(BINFARM_TYPE).$(PORTAGE_TAG).txt
# virtual target -- "all included" binfarm image
hepfarm: hepfarm-$(PLATFORM).$(BINFARM_TYPE).$(PORTAGE_TAG).txt

# virtual target -- produces packages (long-running task!)
# TODO: make archive from dir?
# TODO: some changes are not tested
pkgs: hepfarm-$(PLATFORM).$(BINFARM_TYPE).$(PORTAGE_TAG).txt
	sudo -u collector mkdir -p $(PKGS_OUT_DIR)/$(PLATFORM).$(BINFARM_TYPE).$(PORTAGE_TAG)
	$(DOCKER) run --rm \
		-v $(PKGS_OUT_DIR)/$(PLATFORM).$(BINFARM_TYPE).$(PORTAGE_TAG):/var/cache/binpkgs:z \
		$(shell cat $<) \
		/bin/bash -c 'sudo emerge -g @hepfarm ;  sudo quickpkg --include-config=y "*/*"'

hepfarm-$(PLATFORM).$(BINFARM_TYPE).$(PORTAGE_TAG).txt: context.01.d/root.d.tar context.01.d/Dockerfile \
														binfarm-$(PLATFORM).$(BINFARM_TYPE).$(PORTAGE_TAG).txt
	$(DOCKER) build -t hepfarm-$(PLATFORM)-$(BINFARM_TYPE):$(PORTAGE_TAG) \
				--iidfile $@ \
				--build-arg BASE_IMG=$(shell cat binfarm-$(PLATFORM).$(BINFARM_TYPE).$(PORTAGE_TAG).txt) \
		   		context.01.d

binfarm-$(PLATFORM).$(BINFARM_TYPE).$(PORTAGE_TAG).txt: context.00.d/root.d.tar context.00.d/Dockerfile
	$(DOCKER) build -t binfarm-$(PLATFORM)-$(BINFARM_TYPE):$(PORTAGE_TAG) \
				--iidfile $@ \
				--build-arg PORTAGE_TAG=$(PORTAGE_TAG) \
				--build-arg PLATFORM=$(PLATFORM) \
				--build-arg STAGE3_TAG=$(STAGE3_TAG) \
				--build-arg BINFARM_TYPE=$(BINFARM_TYPE) \
				--build-arg BINFARM_PROFILE=$(BINFARM_PROFILE) \
		   		context.00.d

context.01.d/root.d.tar: $(shell find root.01.d -type f -print) \
						root.01.d/etc/portage/sets/hepfarm
	tar cvf $@ $(ARCHIVE_OPTS) -C root.01.d .

#
# Base layer (binfarm) context
context.00.d/root.d.tar: $(shell find root.00.d -type f -print) \
						  	root.00.d/etc/portage/make.conf
	tar cvf $@ $(ARCHIVE_OPTS) -C root.00.d .


root.01.d/etc/portage/sets/hepfarm: presets/pkgs2build.txt
	grep -v '^#' $< | sed '/^$$/d' | sort | uniq > $@

root.00.d/etc/portage/make.conf: presets/make.conf.common presets/make.conf.$(BINFARM_TYPE)
	cp $< $@
	cat presets/make.conf.$(BINFARM_TYPE) >> $@

clean:
	rm -f context.*.d/root.d.tar

.PHONY: all clean binfarm hepfarm pkgs
