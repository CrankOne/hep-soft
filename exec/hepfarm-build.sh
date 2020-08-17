#!/bin/bash

#sudo chown collector:collector /var/src/

# For debug build type, re-merge glibc since portage does not track changed
# FEATURES for it
# TODO: apparently, glibc is not the only package we have to reemerge?
sudo emerge --getbinpkg=n sys-libs/glibc

# Emerge hepfarm set
sudo emerge --keep-going=y $@

# Prepare the binary packages from what was built
# (sometimes, it is not everything we want, but resulting binary packages are
# still quite useful)
sudo quickpkg --include-config=y "*/*"

# Grant outside context an access to the prepared packages
sudo chmod a+r /var/cache/binpkgs -R 
sudo find /var/cache/binpkgs -type d -exec chmod a+x {} \;
