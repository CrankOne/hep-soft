#!/bin/sh

# This script will deploy virtual environment in the dir ./.venv, activate it
# and install "bob" prerequisites.

# for fedora:27
VENV=virtualenv-3
VENV_PIP=pip
GIT=git
MAKE=make

${VENV} --prompt="@\033[1;32mvenv-3\033[0m\n" ./.venv
. ./.venv/bin/activate
${VENV_PIP} install --upgrade pip
${VENV_PIP} install schema PyYAML pyparsing

${GIT} clone https://github.com/BobBuildTool/bob.git ./.bob-src
cd ./.bob-src
${MAKE}
${MAKE} install DESTDIR=$(realpath ../.bob)
cd ..

echo -n "Bob has been installed to $(realpath .bob)."
echo -n " Run it as $(realpath .bob)/bin/bob or"
echo    " add the $(realpath .bob) to your system PATH."


