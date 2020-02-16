# HEP-Soft

This repository contains a Makefile and set of Gentoo assets assisting small
scientific groups in the creation of their own subject-specific Linux
"micro-distirbution" in a way pretty close to LFS, but with means and benefits
of Gentoo Portage system.

## Rationale

The goal of this initiative is to gain customization freedom offered by Gentoo
distirbution by the price of binary package-based distro. 

This repository provides:

1. A recipes for building a building environment layer for pre-compiled
packages production. This base image should be then considered as a factory or
"farm" (this is where "binfarm" word
came from). The _binfarm_ image effectively is just a customized
Gentoo `stage3` image. Once the basic environment is clamped by particular
_binfarm_ release, the _binary packages_ may be then built and published for
the purpose of fast assembling a Docker image for particular purpose;
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

               +----------------+
               |  binfarm-image |
               |   (root.00.d)  |
               +----------------+
                        ^
                        |
                 +-------------+
                 |   hepfarm   |
                 | (root.01.d) |  >--- builds packages for --->  +----------+
                 |  not saved  |                                 |  Binary  |
                 +-------------+                                 | packages |
                   ^    ^    ^                                   |   repo   |
                   |    |    |    <- retrieves packages from -<  +----------+
        +---+ +---+  ...    ...  +--------+
        | Particular experiment's images  |
        |     (made with Dockerfile,      |
        |   singularity, shifter, direct  |
        |            commits, etc.)       |
        +---+ +---+  ...    ...  +--------+

(TODO: incorrect, reflect interim layer b/w binfarm and hepfarm).

where:

1. `binfarm` is a bootrstrap image for subsequent builds.
2. `hepfarm` is a customized image producing the binary packages. Defines
set of use flags for all the pre-built packages located on public repo. It is
not supposed to be published on any registry.

## Building the Base Image and Parameters

Base "binary farm" image may be then built by:

    $ make binfarm-image.opt.20200214.txt

... todo: more info to be added here

# Notes

Gentoo is a perfect Linux distribution for building deterministic environments.
The most prominent drawbacks one can realize about running it in Docker
environment is portages tree that produces extreme amount of tiny files that
makes Docker containers run very slow. We do overcome this issue by holding
the official portages tree on squashfs. Other things have to be noticed,
however.

