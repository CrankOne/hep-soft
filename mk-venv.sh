#!/bin/sh

# This script will deploy virtual environment in the dir ./.venv, activate it
# and install "bob" prerequisites.

# for fedora:27
VENV="python3 -m venv"
VENV_PIP=pip
GIT=git
MAKE=make

${VENV} ./.venv
. ./.venv/bin/activate
${VENV_PIP} install --upgrade pip
${VENV_PIP} install schema PyYAML pyparsing

${GIT} clone https://github.com/BobBuildTool/bob.git ./.bob-src
pushd ./.bob-src
${MAKE}
${MAKE} install DESTDIR=$(realpath ../.bob)
popd

ln -s ../../.bob/bin/bob .venv/bin/bob

#echo -n "Bob has been installed to $(realpath .bob)."
#echo -n " Run it as $(realpath .bob)/bin/bob or"
#echo    " add the $(realpath .bob) to your system PATH."


