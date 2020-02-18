# This makefile prepares the archives with configuration files for further
# deployment on the container environment

# TODO: new task for dockerfile init scripts:
# 	$ find /etc/portage -type f -name *.binfarm@patch -print0 | sort -z | xargs -t -0 -n 1 patch -p0 -i

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

# Remote location with binary packages
PORTAGE_BINHOST="http://hep-soft.crank.qcrypt.org/$(PORTAGE_TAG)-$(BINFARM_TYPE)/"

# Docker command to use. By default expects user named `collector' to exist
# in the system.
DOCKER=sudo -u collector docker
# Options for creating an archive of root filesystem additions.
ARCHIVE_OPTS=--exclude=.keep --exclude=*.sw?

all: base-packages.$(BINFARM_TYPE).$(PORTAGE_TAG).tar

# virtual target -- alias for base binfarm image
binfarm-image: binfarm-image.$(BINFARM_TYPE).$(PORTAGE_TAG).txt

# TODO: make archive from dir?
packages.$(BINFARM_TYPE).$(PORTAGE_TAG).tar: binfarm-image.$(BINFARM_TYPE).$(PORTAGE_TAG).txt hepfarm-pkgs-set.txt
	$(DOCKER) run --rm \
		-v $(PWD)/packages.$(BINFARM_TYPE).$(PORTAGE_TAG):/var/cache/binpkgs \
		-v $(PWD)/hepfarm-pkgs-set.txt:/etc/portage/sets/hepfarm \
		$(shell cat $<) \
		/vin/bash -c 'sudo emerge @hepfarm; sudo quickpkg --include-config=y "*/*"'

hepfarm-image.$(BINFARM_TYPE).$(PORTAGE_TAG).txt: context.01.d/root.d.tar.gz context.01.d/Dockerfile
	$(DOCKER) build -t hepfarm-$(BINFARM_TYPE):$(PORTAGE_TAG) \
				--iidfile $@ \
				--build-arg BASE_IMG=$(shell cat binfarm-image.$(BINFARM_TYPE).$(PORTAGE_TAG).txt) \
		   		context.01.d

binfarm-image.$(BINFARM_TYPE).$(PORTAGE_TAG).txt: context.00.d/root.d.tar.gz context.00.d/Dockerfile
	$(DOCKER) build -t binfarm-base-$(BINFARM_TYPE):$(PORTAGE_TAG) \
				--iidfile $@ \
				--build-arg PORTAGE_TAG=$(PORTAGE_TAG) \
				--build-arg PLATFORM=$(PLATFORM) \
				--build-arg STAGE3_TAG=$(STAGE3_TAG) \
				--build-arg BINFARM_TYPE=$(BINFARM_TYPE) \
				--build-arg BINFARM_PROFILE=$(BINFARM_PROFILE) \
		   		context.00.d

context.00.d/root.d.tar.gz: $(shell find root.00.d -type f -print) \
						  	root.00.d/etc/portage/make.conf
	tar czvf $@ $(ARCHIVE_OPTS) -C root.00.d .

context.01.d/root.d.tar.gz: $(shell find root.01.d -type f -print) \
							root.01.d/etc/portage/sets/hepfarm
	tar czvf $@ $(ARCHIVE_OPTS) -C root.01.d .

root.01.d/etc/portage/sets/hepfarm: presets/pkgs2build.txt
	grep -v '^#' $< | sed '/^$$/d' | sort | uniq > $@

root.00.d/etc/portage/make.conf: presets/make.conf.common presets/make.conf.$(BINFARM_TYPE)
	cp $< $@
	cat presets/make.conf.$(BINFARM_TYPE) >> $@

clean:
	rm -f context.*.d/root.d.tar.gz

.PHONY: all clean
