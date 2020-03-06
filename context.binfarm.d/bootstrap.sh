#!/bin/sh
# This scenario initializes a boilerplate environment for further deployment of
# relevant packages.
# Use this script for some non-trivial operations rather than Dockerfile, like
# option-dependant operations, administration routines, etc.

# Fail script on command failure
set -e

# Options to be used in emerge
EMERGE_DEFAULT_OPTS="-uDN --quiet-build=y"

# Set locale (need to decrease the size of /usr/lib64/locale/locale-archive
# blob)
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen

echo "Using following make.conf:"
cat /etc/portage/make.conf
echo

# This temporarily disables CAPS support for pam to get rid of circular
# dependency of sys-libs/pam vs. sys-libs/libcap
echo 'sys-libs/pam -filecaps' > /etc/portage/package.use/pam-workaround
# Rebuild everything
#revdep-rebuild
emerge ${EMERGE_DEFAULT_OPTS} @world
rm /etc/portage/package.use/pam-workaround
emerge ${EMERGE_DEFAULT_OPTS} @world
emerge ${EMERGE_DEFAULT_OPTS} @hf-base
emerge --depclean
revdep-rebuild
emerge ${EMERGE_DEFAULT_OPTS} @world

# Forcefully generate all packages
#quickpkg --include-config=y "*/*"

# Add the user `collector'
useradd -d /var/src -c "Default user for package building routines." collector
echo -e "collector\tALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Clear caches
rm -rf /usr/portage/distfiles/*
