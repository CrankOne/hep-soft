#!/bin/bash
find /opt/binfarm/patches/$1 -type f -name *.binfarm@patch -print0 | sort -z | xargs -t -0 -n 1 patch -p0 -i
# xxx, unused yet
