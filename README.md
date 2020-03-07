# HEP-Soft

This repository contains a Makefile and set of Gentoo assets assisting small
scientific groups in the creation of their own subject-specific Linux
"micro-distirbution" in a way pretty close to LFS, but with means and benefits
of Gentoo Portage system.

## Status

Although our scientific group currently using the images produced by these
scripts, some settings/scenarios here are hardcoded (see TODO at the end of
this note). So far it should be considered as a boilerplate by side user rather
then a generic-purpose distro.

## Rationale

The goal of this initiative is to gain customization freedom offered by Gentoo
distirbution by the price of binary package-based distro. 

This repository provides:

1. A recipes for building a building environment layer for pre-compiled
packages production. This base image should be then considered as a factory or
"farm" (this is where "binfarm" came from). The _binfarm_ image effectively is
just a customized Gentoo `stage3` image. Once the basic environment is clamped
by particular _binfarm_ release, the _binary packages_ may be then built and
published for the purpose of fast assembling a Docker image for particular
purpose;
2. A boilerplate recipe(s) for building a number of packages. Once built, these
packages can be then exploited for assembling a subject-specific docker images.

This way we tend to follow the Docker idea of making layered images. Like with
classic binary package-based distro like RHEL, Debian, etc. the new image
can be constructed from base image and bundle of binary packages in reasonable
time. However, making the base layer (_binfarm_) we still leave as much of
customization opportunities as original Gentoo distirbution can offer.

One may think of the `binfarm` as if it is a classic binary-package-based
repo (RHEL, Debian) of certain version, but driven by `emerge` instead of
`yum`/`dnf`/`apt`. Benefits:

* Some set of pre-built packages is available to speed-up the initial
deployment; one can easily customize and deploy bootstrapping distro image
for specific needs together with own overlays/binary package repositories.
* From-source builds are available as well, by the elaborated means of portage
EAPI.

Drawbacks:

* To customize the images one need to know basics of Gentoo system
administration.
* To establish own souce code overlays with their own ebuilds one have to
be familiar with Portage's ebuilds.

To get started, one have to imagine a list of packages relevant to their
subject area, provide the corresponding Gentoo packages configuration.

## Exemplar Subject Area: Software Environment for HEP

Besides of demonstration, the side purpose of this repository is to provide
robust and modern environment for analysis and simulation task of High-Energy
Physics (HEP). It is quite common
effort (see, e.g. [FairSoft](https://github.com/FairRootGroup/FairSoft)),
however we are aiming a slightly different priorities.

Users are encouraged to override the configurations for their specific needs
others than HEP, of course...

# Usage

## Security Dispositions: Creation of a Dedicated User

It is crucial for most of the systems by security reasons to isolate container
management activities. We do solve this by introducing a dedicated no-login
user:

        # useradd -M collector          # create the user named `collector'
        # usermod -L collector          # set this account to be no-login
        # gpasswd -a collector docker   # grant `docker' group privelegies to user

If last command indicates, there is no `docker` group, you probably need to
create it manually and let the docker service know then:

        # groupadd docker
        # service docker restart

If your user and collector have to share the same dir, e.g. when you're making
changes in this repository you may consider adding your account to group
`collector` and changing owning rule for the current directory to allow both,
you and `collector` user, to write there. It will allow you to edit
configuration files from within your user session while `collector` will be
responsible for building the stuff:

        # gpasswd -a ${USER} collector
        # adduser collector ${USER}
        # gpasswd collector ${USER}
        $ newgrp collector
        $ chown ${USER}:collector .

Note: you probably would like to re-login to restore your primary group after
`newgrp` that switches your current primary group.

## Images Hierarchy

Although the Gentoo community maintains Docker image for their `stage3` archive
[being built automatically](https://github.com/gentoo/gentoo-docker-images),
we do need an additional layer over the `stage3` with some possible kludges to
circumvent native Dockerfile restrictions (`SYS_PTRACE`, extended SELinux
attributes, etc). Albeit this is not the case nowadays this place must be
foreseen.

Note, that the portages snapshot on the docker volume was noticed to introduce a
significant performance drop on some systems (see notes section of this readme).

To implement this we introduce the `binfarm` image is derived from
Gentoo's stage3 tarball with some minor system-wide customization applied.
This basic customization acts more like native Gentoo profile (and may turn to
one in the future) and determines major traits of the build: debug information
vs. optimization, static builds, no-multilib, etc.

![Hepfarm structure](/doc/hepfarm-struct.svg)

where:

1. _Binfarm_ is a bootrstrap image for subsequent builds.
2. Subject images are base layers for containers producing the binary packages.
Define use flags for pre-built packages located on public repo. It is not
supposed to be published on any registry.
3. Custom image may be then quickly assembled by user or uploaded to registry,
just like in case of ordinary binary package-based distro... but with much more
impressive customization possibilities!

## Makefile Variables

All these variables have their default values set in Makefile. One may override
them by editing the Makefile or by providing them in command line during `make`
invokation. Below is the list of most important common ones.

* `PORTAGE_TAG` should contain particular portage timestamp tag
(like `20200214`). To see list of available tags, visit
[portages image page](https://hub.docker.com/r/gentoo/portage/tags) on dockerhub.
* `PLATFORM` must correspond to one of the Gentoo's available platforms, like
`x86`, `x86-hardened`, `amd64`, `amd64-nomultilib`, `amd64-hardened`, or
`amd64-hardened-nomultilib` (see images on [dockerhub page](https://hub.docker.com/u/gentoo)).
**WARNING**: currently we do not use platforms other from `amd64`, so setting
it to different values may cause problems.
* `STAGE3_TAG` should contain particular `stage3` timestamp tag
(like `20200214`). To see list of available tags, visit corresponding
`stage3` image page (e.g. [for amd64](https://hub.docker.com/r/gentoo/stage3-amd64/tags).
* `BINFARM_TYPE` refers to one of dynamically-composed build configurations.
Currently only `opt` and `dbg` are supported for optimized and debug versions
of the binary farm environment.
* `GENTOO_PROFILE` should be customized profile provided by your overlay. One
may found our [`q-crypt-hep` overlay](https://github.com/CrankOne/q-crypt-hep-overlay)
being illustrative in that way. For detailed explaination of Gentoo profiles,
see relevant [Gentoo wiki page](https://wiki.gentoo.org/wiki/Profile_(Portage)).
Currently, profile name is deduced from `BINFARM_TYPE` value. One can utilize
one of the system Gentoo profiles as well, of course.
* `PKGS_LOCAL_DIR` shall be the base directory where binary packages for
particularm "farms" to be located (default is `/var/hepfarm/pkgs`).

For the rest of variables, see comments within the Makefile itself. Note the
variable `PORTAGE_BINHOST` -- this might be very useful to keep the
progress of packages already being built during the process of development
your own bundle (see *Workflow* section below).

## Usual Workflow

Conceptually the `make pkgs` should do all the work, but there can be
(and most often *are*) troubles -- packages change, the Gentoo changes,
it is matter of luck to rely on automated builds. So far one have to perform
manual staging with:

    $ make binfarm          # few minutes, initial bootstrapping image
    $ make hepfarm          # few seconds, configure environment for building packages
    $ make pkgs             # few hours, build packages
    $ make publish-pkgs     # few minutes, upload built packages
    $ make publish-image    # few minutes, upload image to the registry

One can, of course, supply their own environment variables appending `KEY=VALUE`
pairs within the `make` command (see *Makefile Variables* section above). In
particular, once (some) packages were build within the `pkgs` target one would
be interested in `PORTAGE_BINHOST` variable that allows to avoid rebuilding of
packages being successfully built.

    $ make pkgs PORTAGE_BINHOST=/var/cache/binpkgs

This way Portage will consume previously built binary packages from shared
location.

# TODO

1. Break the "hepfarm" into pieces for incremental builds: need finer subject
structure: MC, analysis, serving, etc.
2. Clean-up targets: delete images, temporary files, etc.
3. The management of ` $(TMP_DIR)/root.$*.d` within the target
`context.%.d/root.d.tar` sometimes weirdly omits rebuild.
4. Test the `pkg-srv.txt` target and local `PORTAGE_BINHOST` behaviour.
5. More `_GUARD_` files to provide finer dependency tracking over virtual ones.
6. Remove `/var/db/repos/gentoo` portages tree from images uploaded to
the hub/registry to save some size (for users images it might be safely
restored from a portages snapshot).

