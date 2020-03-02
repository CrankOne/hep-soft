#!/bin/sh
# This scenario initializes a boilerplate environment for further deployment of
# relevant packages.
# Accepts one mandatory argument to be "opt" or "dbg" indicating major
# configuration of the build.
# Optionally accepts second argument indicating the profile
# to use.
# Assumes to be ran from within the directory with `make.conf' file.

set -e

# Set locale (need to decrease the size of /usr/lib64/locale/locale-archive
# blob)
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen

# This temporarily disables CAPS support for pam to get rid of circular
# dependency of sys-libs/pam vs. sys-libs/libcap
echo 'sys-libs/pam -filecaps' > /etc/portage/package.use/pam-workaround
# Rebuild everything
#revdep-rebuild
emerge -guDN @world
rm /etc/portage/package.use/pam-workaround
emerge -guDN @world
emerge -guDN @hf-base
emerge --depclean
revdep-rebuild
emerge -guDN @world

# Forcefully generate all packages
#quickpkg --include-config=y "*/*"

# Clear caches
rm -rf /usr/portage/distfiles/*

# Add the user `collector'
useradd -d /var/src -c "Default user for package building routines." collector
echo -e "collector\tALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

