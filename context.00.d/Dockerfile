ARG PORTAGE_TAG=latest
ARG PLATFORM=amd64
ARG STAGE3_TAG=latest

# XXX, run snippet:
#   hep-soft/scratch $ docker build -t gentoo-test .
# name the portage image
FROM gentoo/portage:$PORTAGE_TAG as portage
# image is based on stage3-amd64
FROM gentoo/stage3-$PLATFORM:$STAGE3_TAG

# copy portages to container
# NOTE: avoid making it volume! Counterintuitive, but since Docker makes the
# copy of all the numerous ebuilds, it will lead to significant performance
# loss during container startup. See:
#   https://forums.docker.com/t/docker-run-weirdly-slow-with-volumes-containing-many-files/13456/3
COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo

# Copy the binfarm-initialization archive
#COPY make.conf.common /etc/portage/make.conf
#COPY init-binfarm.sh init.sh
ADD root.d.tar /

ARG BINFARM_TYPE=dbg
ARG BINFARM_PROFILE=default/linux/amd64/17.1

RUN /bin/sh /opt/hepfarm/bin/init-binfarm.sh $BINFARM_TYPE $BINFARM_PROFILE
VOLUME /var/cache/binpkgs
# Set default user to collector (created by init-binfar,sh)
USER collector:collector
WORKDIR /var/src
VOLUME /var/src

RUN /bin/bash /opt/hepfarm/bin/apply-patches.sh
