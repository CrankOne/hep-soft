# Software environment for HEP

The purpose of this repository is to provide robust and modern environment for
analysis and simulation task of High-Energy Physics (HEP). It is quite common
effort (see, e.g. [FairSoft](https://github.com/FairRootGroup/FairSoft)),
however we are aiming a slightly different priorities.

## Rationale

This bundle is built on top of Gentoo Linux distributive providing following
benefits:
1. The environment itself is extremely flexible and easy to re-configure from
the very base system layer due to Gentoo package-management system ("portages"
offer a single yet flexible way to configure variety of system packages).
2. Tracking new versions of front-end software (like Geant4 or CERN ROOT) as
soon as wide and mature community tests new versions of the software.
2. Provide deterministic environment.

By "deterministic" we mean that one have to maintain the linux-from-scratch
system providing the building procedures for every package
installed in it. Many of the software components used in modern HEP require
expensive and heavy dependencies such as Qt, making this activity unaffordable
for individual researches.

We hope, however, that involving a specialized tool makes "determinism" to
become a feasible quality for collaborative group of interested scientific
programmers and system administrators.

One may think of the `binfarm-hep` as if it is a classic binary-package-based
repo (RHEL, Debian) of certain version, but driven by `emerge` instead of
`yum`/`dnf`/`apt`. Benefits:

* Some set of pre-built packages is available to speed-up the initial
deployment; one can easily customize and deploy bootstrapping distro image
for specific needs together with own overlays/binary package repositories.
* From-source builds are available as well, by the elaborated means of portage
EAPI.

Drawbacks:

* To customize the images one need to know basics of Gentoo system
administration
* To establish own souce code overlays with their own ebuilds one have to
be familiar with Portage's ebuilds.

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
you and `collector` user to write there. It is useful because the Bob Build
Tool usually uses current directory extensively:

        # gpasswd -a ${USER} collector
        # adduser collector ${USER}
        # gpasswd collector ${USER}
        $ newgrp collector
        $ chown ${USER}:collector .

Note: you probably would like to re-login to restore your primary group after
`newgrp` that switches your current primary group.

## Deploying the Tools

There is a short script for quick start in this repo: `mk-venv.sh`, well tested
on Fedora 27-29 distro. In case you're using another Linux distributive, this
still can be considered as a useful snippet. What it does:

* Creates Python-3 virtual environment in cwd
* Fetches Bob sources at `.bob-src`, installs it at `.bob` for further usage

Usage:

        $ sh mk-venv.sh

This will leave you with functional Bob copy.

Note: if you're operating on behalf of dedicated user (e.g. `collector` created
as described infra) and experience `Permission denied` error from `virtualenv`,
consider either to move the project directory to some reachable location, or
check directory-browsing privileges to some of the parent directories (e.g.,
`/home/user` dir sometimes protected from browsing by members of group `user`).

## Images Hierarchy

Although the Gentoo community maintains Docker image for their `stage3` archive
[being built automatically](https://github.com/gentoo/gentoo-docker-images),
we do need an additional layer over the `stage3` with some kludge to circumvent
native Dockerfile restrictions (`SYS_PTRACE`, extended SELinux attributes, etc).
Also, the portages snapshot on the docker volume was noticed to introduce a
significant performance drop on some systems (see notes section of this readme).

To implement this we introduce the `gentoo-binfarm` image is derived from
Gentoo's stage3 tarball with some minor system-wide customization applied.
This is a base layer to build the concrete experiment's images
with `Dockerfile`.

             +----------------------+
             |    gentoo-binfarm    |
             | (made by Bob recipe) |
             +----------------------+
                        ^
                        |
                 +-------------+
                 | binfarm-hep |
                 | (made with  |  >--- builds packages for --->  +----------+
                 | Dockerfile) |                                 |  Binary  |
                 +-------------+                                 | packages |
                   ^    ^    ^                                   |   repo   |
                   |    |    |    <- retrieves packages from -<  +----------+
        +---+ +---+  ...    ...  +--------+
        | Particular experiment's images  |
        |     (made with Dockerfile,      |
        |   singularity, shifter, direct  |
        |            commits, etc.)       |
        +---+ +---+  ...    ...  +--------+

where:

1. `gentoo-binfarm` is a bootrstrap image for subsequent builds.
2. `binfarm-hep` is a customized image producing the binary packages. Defines
set of use flags for all the pre-built packages located on public repo.

Most recent `gentoo-binfarm` image is usually
[available at dockerhub](https://hub.docker.com/r/crankone/hepfarm). Recipes at
this repo is used to generate these images.

## Building the Base Image and Parameters

Base "binary farm" image may be then built by:

    $ bob dev binfarm-base

In case when no `GENTOO_STG3_TAG` is provided, the latest one will be taken
from current `GENTOO_DISTFILES_MIRROR`. In this case, among the other `bob`
output the following line will be printed:

        Gentoo stage3 version tag has been automatically resolved to 20190320T214501Z.

This Gentoo version tag has to be taken then and specified manually for
identification of particular base image for `binfarm-hep` image.

# Notes

Gentoo is a perfect Linux distribution for building deterministic environments.
The most prominent drawbacks one can realize about running it in Docker
environment is portages tree that produces extreme amount of tiny files that
makes Docker containers run very slow. We do overcome this issue by holding
the official portages tree on squashfs. Other things have to be noticed,
however.

