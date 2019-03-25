#!/bin/sh

mkdir -p /etc/portage/env /hepfarm/dist /hepfarm/pkg

emerge -uDN @world

echo "sci-physics/root" >> /etc/portage/package.keywords/root
echo "sci-physics/rootdavix fftw graphviz http pythia6 pythia8 root7 sqlite xrootd xinetd" >> /etc/portage/package.use/root
echo "media-libs/libafterimage png tiff gif jpeg" >> /etc/portage/package.use/libafterimage

emerge app-portage/gentoolkit \
       dev-util/debugedit \
       sys-devel/gdb \
       sci-physics/cernlib-2006-r5

emerge sci-physics/root-6.12.06

