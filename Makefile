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
PORTAGE_TAG=20200623
# Possible choices are: x86, x86-hardened, amd64, amd64-nomultilib,
# amd64-hardened, amd64-hardened-nomultilib. See:
# 	https://hub.docker.com/u/gentoo
PLATFORM=amd64
# For variants see e.g.:
#   https://hub.docker.com/r/gentoo/stage3-amd64/tags
STAGE3_TAG=20200618
# Possible choices are: opt, dbg -- assumed to coincide with one of the custom
# profile
BINFARM_TYPE=opt
# Gentoo profile to be set
GENTOO_PROFILE=q-crypt-hep:binfarm/$(BINFARM_TYPE)

#
# UTILITY VARIABLES
#
# Docker command to use. By default expects user named `collector' to exist
# in the system.
DOCKER=sudo -u collector docker
# Python executable
PYTHON=python3
# Options for creating an archive of root filesystem additions.
ARCHIVE_OPTS=--exclude=.keep --exclude=*.sw? --exclude=.git
# Directory for temporary output of root filesystem subtrees
TMP_DIR=/tmp/hep-soft
# Base directory where output packages will be written
# Note: for SELinux do not forget to run
# 	$ chcon -Rt svirt_sandbox_file_t /var/hepfarm/pkgs
PKGS_LOCAL_DIR=/var/hepfarm/pkgs
# This options will be provided to docker command during packages build stage,
# in addition to required ones. User may provide some customization (e.g. mount
# a dedicated volume for package build).
PKGBUILD_DOCKER_OPTS=
#PKGBUILD_DOCKER_OPTS="--mount='type=volume,dst=/var/tmp/portage-ondisk,volume-driver=local,volume-opt=type=ext4,volume-opt=device=/dev/vdb'"

#
# REMOTE PUBLISHING
#
# Remote host to publish packages (rsync used)
REMOTE_HOST=crank.qcrypt.org
# Directory on remote host for packages to be published (rsync used)
REMOTE_DIR=/var/www/15-hepsoft-pkgs/

#     ___________________
# __/ Inferred Variables \_____________________________________________________

# Common suffix identifying the build (like amd64.opt.20200214)
SUFFIX=$(PLATFORM).$(BINFARM_TYPE).$(PORTAGE_TAG)
# Local directory where this build's packages will be stored
PKGS_LOCAL_CURRENT_DIR=$(PKGS_LOCAL_DIR)/$(SUFFIX)
# All package sets in hepfarm
ALL_SETS=$(shell $(PYTHON) exec/gen_subtree.py -l -c presets/spec-hepsoft.yaml)
# Full build version variable
HEPSOFT_VERSION=$(SUFFIX).$(shell git rev-parse --short HEAD)
# Number of processes for building the stuff
BUILD_NPROC=$(shell nproc)
# user/name:tag of release image (need for publishing)
RELEASE_IMAGE_NAME=crankone/hepfarm-$(PLATFORM)-$(BINFARM_TYPE):$(STAGE3_TAG)

# GUARD is a function which calculates md5 sum for its
# argument variable name. Note, that both cut and md5sum are
# members of coreutils package so they should be available on
# nearly all systems.
# see: https://stackoverflow.com/questions/11647859/make-targets-depend-on-variables
GUARD = .cache/$(1)_GUARD_$(shell echo $($(1)) | md5sum | cut -d ' ' -f 1)

#     ________________
# __/ Virtual Targets \________________________________________________________

all: pkgs

clean:
	rm -f context.*.d/root.d.tar
	rm -rf .cache

# TODO:
# clean-images:
# 	...

# virtual target -- alias for base binfarm image
binfarm: .cache/image-binfarm-$(SUFFIX).txt

# virtual target -- "all included" binfarm image
hepfarm: .cache/image-hepsoft-$(SUFFIX).txt

# virtual target for publishing packages on remote host
# TODO: these instructions on the remote:
# 		find $(REMOTE_DIR) -type d -exec chmod a+x {} \;
# 	    find $(REMOTE_DIR) -type f -exec chmod a+r {} \;
# may be imposed into rsync invokation with command like proposed here:
#	https://stackoverflow.com/questions/9177135/rsync-deploy-and-file-directories-permissions
# i.g.:
# 	$ --chmod=Du=rwx,Dg=rx,Do=rx,Fu=rw,Fg=r,Fo=r
publish-pkgs:
	rsync -av --info=progress2 --chmod=F644,D2775 \
		$(PKGS_LOCAL_CURRENT_DIR) crank@$(REMOTE_HOST):$(REMOTE_DIR)

# Produces packages (long-running task!)
# TODO: directory for emerge's logs (--quiet-build=y)
pkgs: .cache/image-hepsoft-$(SUFFIX).txt | $(PKGS_LOCAL_CURRENT_DIR)
	$(DOCKER) run --rm \
		-v $(PKGS_LOCAL_CURRENT_DIR):/var/cache/binpkgs:z \
		$(PKGBUILD_DOCKER_OPTS) \
		$(shell cat $<) \
		/bin/bash -c 'sudo emerge --keep-going=y $(ALL_SETS) ; sudo quickpkg --include-config=y "*/*"'

$(call GUARD,HEPSOFT_VERSION): | .cache
	rm -rf ./.cache/HEPSOFT_VERSION*
	touch $@

#     ______________________
# __/ Docker Images Targets \__________________________________________________

# TODO: find a way to use a dedicated user, as now it requires root access
publish-image: .cache/image-hepsoft-$(SUFFIX).txt
	docker tag $(shell cat $<) $(RELEASE_IMAGE_NAME)
	docker push $(RELEASE_IMAGE_NAME)

# Produces image ready for building packages
.cache/image-hepsoft-$(SUFFIX).txt: .cache/image-binfarm-$(SUFFIX).txt \
									context.hepsoft.d/root.d.tar \
									context.hepsoft.d/Dockerfile
	$(DOCKER) build -t hepsoft-$(PLATFORM)-$(BINFARM_TYPE):$(PORTAGE_TAG) \
				--iidfile $@ \
				--build-arg BASE_IMG=$(shell cat $<) \
		   		context.hepsoft.d

# Produces bootstrapping image
.cache/image-binfarm-$(SUFFIX).txt: context.binfarm.d/root.d.tar \
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
# 						$(call GUARD,PORTAGE_BINHOST)
#						$(call GUARD,BUILD_NPROC)
.SECONDEXPANSION:
context.%.d/root.d.tar: $$(shell find root.%.d -type f -print) \
                        presets/spec-%.yaml \
						$(call GUARD,HEPSOFT_VERSION) \
                      | $(TMP_DIR)
	rm -rf $(TMP_DIR)/root.$*.d
	cp -r root.$*.d $(TMP_DIR)
	$(PYTHON) exec/gen_subtree.py -c presets/spec-$*.yaml -d $(TMP_DIR)/root.$*.d
	sh exec/hepsoft.sh -m -j$(BUILD_NPROC) \
		$(if $(PORTAGE_BINHOST),-b$(PORTAGE_BINHOST),) > $(TMP_DIR)/root.$*.d/etc/portage/make.conf
	mkdir -p $(TMP_DIR)/root.$*.d/etc
	echo $(HEPSOFT_VERSION) > $(TMP_DIR)/root.$*.d/etc/hepsoft-version.txt
	tar cf $@ $(ARCHIVE_OPTS) -C $(TMP_DIR)/root.$*.d .

# Temp dir for rendering the root filesystems
$(TMP_DIR):
	mkdir -p $@

.cache:
	mkdir -p $@
	chmod a+rw $@

$(PKGS_LOCAL_CURRENT_DIR):
	sudo -u collector mkdir -p $(PKGS_LOCAL_CURRENT_DIR)

#     ____________
# __/ Aux targets \____________________________________________________________

srv-start: .cache/pkg-srv.txt

# runs local packages file server
# WARNING: must be stopped manually, with ctrl+C. Or with `docker stop ...',
# when ran with -d.
.cache/pkg-srv.txt:
	$(DOCKER) run --rm -dti \
				--cidfile $@ \
				--volume /var/hepfarm/pkgs:/var/www/localhost/htdocs \
				--volume $(shell readlink -f srv/lighttpd.conf):/etc/lighttpd/lighttpd.conf \
				-p 8789:80 sebp/lighttpd
# Use this to stop background file server container
srv-stop:
	$(DOCKER) stop $(shell cat .cache/pkg-srv.txt)


.PHONY: all clean binfarm hepfarm pkgs publish-pkgs publish-image srv-start srv-stop
