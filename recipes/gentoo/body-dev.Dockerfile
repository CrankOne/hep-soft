# ^^^ the FROM instruction is to be added here by Bob recipe.

COPY make.conf-dev /etc/portage/make.conf

RUN mkdir -p /etc/portage/env \
 && echo 'CFLAGS="${CFLAGS} -ggdb"' > /etc/portage/env/debugsyms \
 && echo 'CXXFLAGS="${CXXFLAGS} -ggdb"' >> /etc/portage/env/debugsyms \
 && echo 'FEATURES="${FEATURES} splitdebug compressdebug -nostrip"' >> /etc/portage/env/debugsyms \
 && echo 'USE="debug"' >> /etc/portage/env/debugsyms \
 \
 && echo 'FEATURES="${FEATURES} installsources"' > /etc/portage/env/installsources

