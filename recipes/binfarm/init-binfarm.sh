#!/bin/sh
# This scenario initializes a boilerplate environment for further deployment of
# relevant packages. Optionally accepts single argument indicating the profile
# to use
if [ ! -z "$1" ] ; then
    eselect profile set $1
fi
emerge -uDN @world
emerge app-portage/gentoolkit \
       dev-util/debugedit \
       sys-devel/gdb \
       sci-physics/cernlib-2006-r5 \
       app-admin/sudo \

