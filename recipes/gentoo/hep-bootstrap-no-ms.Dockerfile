# For ms docker:
#ARG BOOTSTRAP
#FROM ${BOOTSTRAP:-alpine:3.7} as builder
FROM alpine:3.7

WORKDIR /gentoo

ARG ARCH=amd64
ARG MICROARCH=amd64
ARG SUFFIX
ARG TAG
ARG DIST="https://ftp-osl.osuosl.org/pub/gentoo/releases/${ARCH}/autobuilds"
ARG SIGNING_KEY="0xBB572E0E2D182910"

RUN echo "Building Gentoo Container image for ${ARCH} ${SUFFIX} fetching from ${DIST}" \
 && apk --no-cache add gnupg tar wget xz \
 && STAGE3PATH="${TAG}/stage3-${ARCH}-${SUFFIX}${SUFFIX:+-}${TAG}.tar.xz" \
 && echo "STAGE3PATH:" $STAGE3PATH \
 && STAGE3="$(basename ${STAGE3PATH})" \
 && wget -q "${DIST}/${STAGE3PATH}" "${DIST}/${STAGE3PATH}.CONTENTS" "${DIST}/${STAGE3PATH}.DIGESTS.asc" \
 && gpg --list-keys \
 && echo "standard-resolver" >> ~/.gnupg/dirmngr.conf \
 && echo "honor-http-proxy" >> ~/.gnupg/dirmngr.conf \
 && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf \
 && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys ${SIGNING_KEY} \
 && gpg --verify "${STAGE3}.DIGESTS.asc" \
 && awk '/# SHA512 HASH/{getline; print}' ${STAGE3}.DIGESTS.asc | sha512sum -c \
 && tar xpf "${STAGE3}" --xattrs --numeric-owner \
 && sed -i -e 's/#rc_sys=""/rc_sys="docker"/g' etc/rc.conf \
 && echo 'UTC' > etc/timezone \
 && rm ${STAGE3}.DIGESTS.asc ${STAGE3}.CONTENTS ${STAGE3}

# for no-ms docker:
RUN tar -C /gentoo -cf /hep-stage3.tar .

# for ms docker:
#FROM scratch
#
#WORKDIR /
#COPY --from=builder /gentoo/ /
#CMD ["/bin/bash"]

