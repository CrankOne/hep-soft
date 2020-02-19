#!/bin/sh
# This scenario initializes a boilerplate environment for further deployment of
# relevant packages.
# Accepts one mandatory argument to be "opt" or "dbg" indicating major
# configuration of the build.
# Optionally accepts second argument indicating the profile
# to use.
# Assumes to be ran from within the directory with `make.conf' file.

set -e

BINFARM_TYPE=$1
BINFARM_PROFILE=$2

# Make base system-wide build assets
mkdir -p /etc/portage/env/
if [ "dbg" == ${BINFARM_TYPE} ] ; then
    echo "[init-binfarm.sh] image type is set to DEBUG (dbg)"
    cat <<-EOF >> /etc/portage/env/debugsyms
	CFLAGS="${CFLAGS} -ggdb"
	CXXFLAGS="${CXXFLAGS} -ggdb"
	FEATURES="${FEATURES} splitdebug compressdebug -nostrip buildpkg"
	USE="debug sqlite"
	EOF
    echo 'FEATURES="${FEATURES} installsources"' > /etc/portage/env/installsources
    echo 'USE="${USE} debug"' >> /etc/portage/make.conf
elif [ "opt" == ${BINFARM_TYPE} ] ; then
    echo "[init-binfarm.sh] image type is set to PRODUCTION (opt)"
    echo 'FEATURES="${FEATURES} buildpkg"' >> /etc/portage/make.conf
else
    (>2 echo "Unknown binfarm configuration provided: \"${BINFARM_TYPE}\". Aborted." )
fi

# Set profile, if given
if [ ! -z "${BINFARM_PROFILE}" ] ; then
    eselect profile set ${BINFARM_PROFILE}
fi

# Set locale (need to decrease the size of /usr/lib64/locale/locale-archive
# blob)
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen

# This temporarily disables CAPS support for pam to get rid of circular
# dependency of sys-libs/pam vs. sys-libs/libcap
echo 'sys-libs/pam -filecaps' > /etc/portage/package.use/pam-workaround

# Rebuild everything
emerge -guDN @world
rm /etc/portage/package.use/pam-workaround
emerge -guDN @world
emerge --depclean
revdep-rebuild

# Forcefully generate all packages
#quickpkg --include-config=y "*/*"

# Clear caches
rm -rf /usr/portage/distfiles/*

# Add the user `collector'
useradd -d /var/src -c "Default user for package building routines." collector
echo -e "collector\tALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

