#!/bin/sh

# WARNING: if you would like to avoid setting these variables in make.conf,
# set them to space(s) rather than to empty string.
: "${EMERGE_DEFAULT_OPTS:=--quiet-build=y}"

usage() {
    cat <<EOF
Usage forms:
    $ hepsoft [-m] [-v] [-b binhost] [-j nJobs] [-t binfarmType]
Being ran with \`-v' option, prints the current hepsoft release version.
With \`-m' option, (re-)generates the Portage's \`make.conf' file with
\`PORTAGE_BINHOST' variable optionally provided with \`-b' argument.
Use the \`-j' argument is to add the MAKEOPTS=-j<nJobs> in make.conf.
EOF
}

generate_makeconf() {
    if [ ! -z ${PORTAGE_BINHOST} ] ; then
        echo "PORTAGE_BINHOST=\"${PORTAGE_BINHOST}\""
        EMERGE_DEFAULT_OPTS="$EMERGE_DEFAULT_OPTS --getbinpkg=y"
    fi
    if [ ! -z "${NJOBS// }" ] ; then
        MAKEOPTS="$MAKEOPTS -j${NJOBS}"
    fi
    # Echo makeopts, if any
    if [ ! -z "${MAKEOPTS// }" ] ; then
        echo "MAKEOPTS=\"$MAKEOPTS\""
    fi
    # Echo emerge default opts, if any
    if [ ! -z "${EMERGE_DEFAULT_OPTS// }" ] ; then
        echo "EMERGE_DEFAULT_OPTS=\"$EMERGE_DEFAULT_OPTS\""
    fi
}

if [ $# -lt 1 ] ; then
    (>&2 usage)
    exit 1
fi

while getopts "vmb:j:D:" opt ; do
case $opt in
v) cat /etc/hepsoft-version.txt ;;
m) DO_GENERATE_MAKECONF=yes ;;
b) PORTAGE_BINHOST=$OPTARG ;;
j) NJOBS=$OPTARG ;;
esac
done

if [[ "yes" == ${DO_GENERATE_MAKECONF} ]] ; then
    generate_makeconf $BINFARM_TYPE
fi

