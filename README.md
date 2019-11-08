# Software environment for HEP

The purpose of this repository is to provide robust and modern environment for
analysis and simulation task of High-Energy Physics (HEP). It is quite common
effort (see, e.g. [FairSoft](https://github.com/FairRootGroup/FairSoft)),
however we are aiming a slightly different priorities.

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

# Security Dispositions: Creation of a Dedicated User

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

# Deploying the Tools

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

# Image Hierarchy

The `binfarm-base` image is derived directly from Gentoo's stage3 tarball. We
keep its packages in binary repository as a backup for subsequent usage before
any customization takes place.

        +--------------+    +-------------+ <- ...
        | binfarm-base |<---| binfarm-hep | <- Particular experiment's images
        +--------------+    +-------------+ <- ...

where:

1. `binfarm-base` is a bootrstrap image for subsequent builds. Does not
introduce any customization to default Gentoo stage3 tarball except for
SquashFS tools. Binary package directory is usually composed of the name
of architecture plus `-bootstrap`, like `amd64-bootstrap`. Parameters:
    * `GENTOO_ARCH` architecture of binfarm (host)
2. `binfarm-hep` is a customized image for producing the packages.
Parameters:
    * `HEPFARM_CFG` may be one of: `debug`, `production`, `splitdebug`

## Building the Base Image

Base "binary farm" image may be then built by:

    $ bob dev binfarm-base

Note, that one might have to provide the `-DDOCKER_CMD='sudo docker'` argument
to `bob dev` invokation above to handle the environment where user has no
direct permission to `docker` group.

In case when no `GENTOO_STG3_TAG` is provided, the latest one will be taken
from current `GENTOO_DISTFILES_MIRROR`. In this case, among the other `bob`
output the following line will be printed:

        Gentoo stage3 version tag has been automatically resolved to 20190320T214501Z.

This Gentoo version tag has to be taken then and specified manually for
identification of particular base image for `binfarm-hep` image.

## Building the "Binary farm for HEP" image

# Notes

Gentoo is a perfect Linux distribution for building deterministic environments.
The most prominent drawbacks one can realize about running it in Docker
environment is portages tree that produces extreme amount of tiny files that
makes Docker containers run very slow. We do overcome this issue by holding
the official portages tree on squashfs. Other things have to be noticed,
however.

