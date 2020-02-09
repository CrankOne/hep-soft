# XXX, run snippet:
#   hep-soft/scratch $ docker build -t gentoo-test .
# name the portage image
FROM gentoo/portage:latest as portage
# image is based on stage3-amd64
FROM gentoo/stage3-amd64:latest
# copy portages to container
# NOTE: avoid making it volume! Counterintuitive, but since Docker makes the
# copy of all the numerous ebuilds, it will lead to significant performance
# loss during container startup. See:
#   https://forums.docker.com/t/docker-run-weirdly-slow-with-volumes-containing-many-files/13456/3
COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo
COPY make.conf.common /etc/portage/make.conf
COPY init-binfarm.sh init.sh

ENV BINFARM_TYPE=dbg \
    BINFARM_PROFILE=default/linux/amd64/17.1

RUN /bin/sh init.sh 
