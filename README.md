# Rationale

Key point of this initiative is to gain customization freedom offered by Gentoo
distirbution by the price of binary package-based distro. 

**This** repository provides a set of recipes for building a **basic** building
environment layer for pre-compiled packages production. This base image should
be then considered as a factory or "farm" (this is where "binfarm" word
came from). The _binfarm_ image effectively is just a customized
Gentoo `stage3` image. Once the basic environment is clamped by particular
_binfarm_ release, the _binary packages_ may be then built and published for
the purpose of fast assembling a Docker image for particular purpose.

This way we tend to follow the Docker idea of making layered images. Like with
classic binary package-based distro like RHEL, Debian, etc. the new image
can be constructed from base image and bundle of binary packages in reasonable
time. However, making the base layer (_binfarm_) we still leave as much of
customization opportunities as original Gentoo distirbution can offer.

# Subject area: software environment for HEP

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
3. Provide deterministic environment.

By "deterministic" we mean that one have to maintain the linux-from-scratch
system providing the building procedures for every package
installed. Many of the software components used in modern HEP require
expensive dependencies such as Qt, making this activity unaffordable for
individual researches.

We hope, however, that involving a specialized tool makes "determinism" to
become a feasible quality for collaborative group of interested scientific
programmers and system administrators.

# System prerequisites

Besides the docker service this scripts are currently relying on FUSE mount
of `squashfs` (see "Notes" section for the reason) from userspace to provide
image with portages volume. Therefore the "filesyste in userspace" has to be
enabled in host kernel, and the `squashfuse` utility has to be available as
a shell command.

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

Preferred method of usage is Python3 virtual environment with `BobBuildtool`
being installed within. Cheatsheet:

    $ python3 -m venv .venv
    $ source .venv/bin/activate
    $ pip install BobBuildTool

This will leave you with functional Bob copy.

Note: if you're operating on behalf of dedicated user (e.g. `collector` created
as described infra) and experience `Permission denied` error from `virtualenv`,
consider either to move the project directory to some reachable location, or
check directory-browsing privileges to some of the parent directories (e.g.,
`/home/user` dir sometimes protected from browsing by members of group `user`).

## Building the Base Image

Base "binary farm" image may be then built by:

    $ bob dev gentoo-binfarm

Note, that one might have to provide the `-DDOCKER_CMD='sudo docker'` argument
to `bob dev` invokation above to handle the environment where user has no
direct permission to `docker` group.

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

