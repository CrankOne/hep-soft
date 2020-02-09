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
if [ "dbg" == ${BINFARM_TYPE} ] ; then
    cat <<-EOF >> /etc/portage/env/debugsyms
	CFLAGS="${CFLAGS} -ggdb"
	CXXFLAGS="${CXXFLAGS} -ggdb"
	FEATURES="${FEATURES} splitdebug compressdebug -nostrip buildpkg"
	USE="debug sqlite"
	EOF
    echo 'FEATURES+="installsources"' > /etc/portage/env/installsources
else
    echo 'FEATURES="buildpkg"' >> /etc/portage/make.conf
    echo 'USE="debug sqlite"' >> /etc/portage/make.conf
fi

# Set profile, if given
if [ ! -z "${BINFARM_PROFILE}" ] ; then
    eselect profile set ${BINFARM_PROFILE}
fi
# Rebuild everything
emerge -uDN @world
# Build some additional packages
emerge sys-fs/squashfs-tools \
       app-portage/gentoolkit
       app-admin/sudo
       dev-util/debugedit
       sys-devel/gdb

#       sci-physics/cernlib
       

# Forcefully generate all packages
quickpkg --include-config=y "*/*"
# Clear caches
rm -rf /usr/portage/distfiles/*
# Make output binary packages available for everybody
#chmod -R a+rw /var/cache/binpkgs

