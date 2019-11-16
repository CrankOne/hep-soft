#!/bin/sh
# This scenario initializes a boilerplate environment for further deployment of
# relevant packages.
# Accepts one mandatory argument to be "opt" or "dbg" indicating major
# configuration of the build.
# Optionally accepts second argument indicating the profile
# to use.
# Assumes to be ran from within the directory with `make.conf' file.

# Make base system-wide build assets
mkdir -p /etc/portage/env/
if [ "dbg" == $1 ] ; then
    echo 'CFLAGS="${CFLAGS} -ggdb"' > /etc/portage/env/debugsyms \
    echo 'CXXFLAGS="${CXXFLAGS} -ggdb"' >> /etc/portage/env/debugsyms \
    echo 'FEATURES="${FEATURES} splitdebug compressdebug -nostrip"' >> /etc/portage/env/debugsyms \
    echo 'USE="debug"' >> /etc/portage/env/debugsyms \
    echo 'FEATURES="${FEATURES} installsources"' > /etc/portage/env/installsources
fi
cp make.conf /etc/portage/make.conf

# Set profile, if given
if [ ! -z "$2" ] ; then
    eselect profile set $2
fi
# Rebuild everything
emerge -uDN @world
# Build some additional packages
emerge sys-fs/squashfs-tools \
       app-portage/gentoolkit \
       dev-util/debugedit \
       sys-devel/gdb \
       sci-physics/cernlib-2006-r5 \
       app-admin/sudo

# Forcefully generate all packages
quickpkg --include-config=y "*/*"
# Clear caches
#rm -rf /usr/portage/distfiles
# Make output binary packages available for everybody
chmod -R a+rw /var/cache/binpkgs
