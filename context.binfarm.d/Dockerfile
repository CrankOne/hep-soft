ARG PORTAGE_TAG=latest
ARG PLATFORM=amd64
ARG STAGE3_TAG=latest

# XXX, run snippet:
#   hep-soft/scratch $ docker build -t gentoo-test .
# name the portage image
FROM gentoo/portage:$PORTAGE_TAG as portage
# image is based on stage3-amd64
FROM gentoo/stage3-$PLATFORM:$STAGE3_TAG

ARG GENTOO_PROFILE=default/linux/amd64/17.1

# copy portages to container
# NOTE: avoid making it volume! Counterintuitive, but since Docker makes the
# copy of all the numerous ebuilds, it will lead to significant performance
# loss during container startup. See:
#   https://forums.docker.com/t/docker-run-weirdly-slow-with-volumes-containing-many-files/13456/3
COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo

# Copy the binfarm-initialization archive
ADD root.d.tar /

# Set custom profile for containerized build
RUN eselect news read && \
    eselect profile set $GENTOO_PROFILE && \
    /bin/sh /opt/hepfarm/bin/init-binfarm.sh

VOLUME /var/cache/binpkgs
# Set default user to collector (created by init-binfar,sh)
USER collector:collector
WORKDIR /var/src
VOLUME /var/src
