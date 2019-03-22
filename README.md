# Software environment for HEP

The purpose of this repository is to provide robust and modern environment for
analysis and simulation task of High-Energy Physics (HEP). It is quite common
effort (see, e.g. [FairSoft](https://github.com/FairRootGroup/FairSoft)),
however we are aiming a slightly different priorities:
   1. Tracking new versions of front-end software (like Geant4 or CERN ROOT) as
      fast as possible.
   2. Fully deterministic environment (1).

"Fully deterministic" means that one have to maintain the
linux-from-scratch system providing the building procedures for every package
installed in it. Many of the software components used in modern HEP require
quite expensive dependencies such as Qt, making this activity unaffordable for
individual researches.

We hope, however, that involving a specialized tool may make this task feasible
for collaborative group of interested scientific programmers and system
administrators.

(1) This is a long-term goal that will remain unreached for, may be, couple of
years, depending on community support.

# Deploying the Tools

There is a short script for quick start in this repo: `mk-venv.sh`, well tested
on Fedora 27-29 distro. In case you're using another Linux distributive, this
still can be considered as a useful snippet. What it does:

* Creates Python-3 virtual environment in cwd
* Fetches Bob sources at `.bob-src`, installs it at `.bob` for further usage

Usage:

    $ sh mk-venv.sh

This will leave you with functional bob copy.

# Image hierarchy

The `binfarm-base` image is derived directly from Gentoo's stage3 tarball. We
keep its packages in binary repository as a backup for subsequent usage before
any customization takes place.

    +--------------+    +-------------+ <- ...
    | binfarm-base |<---| binfarm-hep | <- Particular experiment's images
    +--------------+    +-------------+ <- ...

On top of the `binfarm-base` the `binfarm-hep` image is built. It introduces
all the basic customization for default Gentoo stage3 image, including the
compiler switch, `make.conf` overriding, etc. It clamps all the basic system
configuration for software builds that further composes images specific for
particular experiments.

## Building the Base Image

Base "binary farm" image may be then built by:

    $ ( . ./.venv/bin/activate ; ./.bob/bin/bob dev binfarm-base )

Note, that one might have to provide the `-DDOCKER_CMD='sudo docker'` argument
to `bob dev` invokation above to handle the environment where user has no
direct permission to `docker` group.

In case when no `GENTOO_STG3_TAG` is provided, the latest one will be taken
from current `GENTOO_DISTFILES_MIRROR`. In this case, among the other `bob`
output the following line will be printed:

    Gentoo stage3 version tag has been automatically resolved to 20190320T214501Z.

This gentoo version tag has to be taken then and specified manually for
identification of particular base image for `binfarm-hep` image.

## Building the "Binary farm for HEP" image

# Notes

Gentoo is a perfect Linux distribution for building deterministic environments.
The most prominent drawbacks one can realize about running it in Docker
environment is portages tree that produces extreme amount of tiny files that
makes Docker containers run very slow. We do overcome this issue by holding
the official portages tree on squashfs in userspace.

