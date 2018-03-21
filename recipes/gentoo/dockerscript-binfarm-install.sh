#!/bin/bash

eselect profile set default/linux/amd64/17.0

echo "=sys-devel/gcc-7.2.0 ~amd64" >> /etc/portage/package.keywords/gcc-7.2.0
emerge -a =sys-devel/gcc-7.2.0
emerge -uDN @world

emerge =app-portage/gentoolkit-0.4.0::gentoo \
       =dev-util/debugedit-5.3.5-r1::gentoo \
       =sys-devel/gdb-7.12.1::gentoo \
       =sci-physics/cernlib-2006-r5

echo "=sci-physics/root-6.12.06 ~amd64" >> /etc/portage/package.keywords/root
echo "=sci-physics/root-6.12.06 davix fftw graphviz http pythia6 pythia8 root7 sqlite xrootd xinetd" >> /etc/portage/package.use/root
echo ">=media-libs/libafterimage-1.20-r2 png tiff gif jpeg" >> /etc/portage/package.use/libafterimage
emerge =sci-physics/root-6.12.06

