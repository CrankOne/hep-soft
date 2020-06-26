"""
Generate Gentoo Portage environment files environment.
Accepts a .yaml document (specification) describing packages (atoms) to be
installed, generates a set of package.[use|license|keyword] files to be
consumed by Gentoo Portage system.
"""
from __future__ import unicode_literals

import os
import sys
import re
import yaml
import io
import argparse

# Regular expression for the package atom entry
rxPortageAtom = re.compile(r'^(?P<quantify>[<>]?=?)?(?P<group>[\w\-]+)/(?P<name>[\w\-]+\w)(?:-(?P<ver>[\d.]+))?(?:(?P<patch>.+)?)$')

def get_atom_dict( atomStrExpr ):
    """
    Applies regular expression to Gentoo Portage's package atom string
    veryfying match result and returning groups dictionary.
    """
    m = rxPortageAtom.match(atomStrExpr)
    if not m:
        raise RuntimeError("Exprssion \"%s\" does not seem to be a valid package atom.")
    return dict(m.groupdict())

class AtomRef(object):
    """
    Configuration entry referencing Gentoo Portages atom together with
    subsidiary information: keywords, useflags, licences, etc.
    """
    def __init__(self, name, payload=None, partOfSet=None):
        """
        Initializes the instance with given portage package atom expression
        and subsidiary payload.
        """
        self.name = name
        self._d = get_atom_dict(name)
        self._payload = payload if payload else dict()
        self.deps = [ AtomRef(*item) for item in self._payload['deps'].items() ] \
                     if 'deps' in self._payload else []
        self._partOfSet = partOfSet

    @property
    def cfgFileNamePat(self):
        toks = [ self._d[n] for n in ('group', 'name', 'ver', 'patch') if self._d[n] ]
        if self._partOfSet:
            toks = [self._partOfSet,] + toks
        return '-'.join(toks)

    def write_props_to(self, propName, f):
        if propName in self._payload:
            f.write( '%s %s\n'%( self.name, ' '.join(self._payload[propName]) ) )
        for depAtom in self.deps:
            depAtom.write_props_to(propName, f)

class SmartConfig(object):
    """
    A "smart" file entity. Provides two features:
        * creates file only if there were some writing in it, on "file" close
        * recursively creates directories within the path of the file
    """
    def __init__(self, filename, mode='w'):
        self._fName = filename
        self._fOpenMode = mode

    def __enter__(self):
        self._io = io.StringIO()
        return self._io

    def __exit__(self, exc_type, exc_value, excTraceback):
        if self._io.getvalue():
            os.makedirs( os.path.dirname( self._fName ), exist_ok=True )
            with open(self._fName, self._fOpenMode) as f:
                f.write( self._io.getvalue() )
        self._io.close()


def main( config, root_dir='/tmp', list_sets=False ):
    """
    Main entry point, deploys file tree.
    """
    if not list_sets and not root_dir:
        raise RuntimeError( 'root directory parameter is not set' )
    # Parse specification
    with open(config, 'r') as f:
        try:
            spec = yaml.safe_load(f)
        except yaml.YAMLError as exc:
            sys.stderr.write(exc)
            sys.exit(1)
    # Generate environment tree
    for setName in sorted(spec.keys()):
        if list_sets:
            sys.stdout.write('@%s '%setName)
            continue
        setFileName = os.path.join( root_dir, 'etc/portage/sets', setName )
        pkgNames = sorted(spec[setName].keys())
        # Write set file
        with SmartConfig( setFileName ) as setFile:
            setFile.write('\n'.join(pkgNames))
        prevEnvFileContent = None
        for pkgName, pkgSpec in spec[setName].items():
            pkg = AtomRef(pkgName, pkgSpec, setName)
            for prop in ( 'keywords', 'license', 'mask', 'use', 'env' ):
                pt = os.path.join( root_dir, 'etc/portage/package.%s'%prop, pkg.cfgFileNamePat )
                with SmartConfig(pt, 'w') as f:
                    pkg.write_props_to(prop, f)
    if list_sets:
        sys.stdout.write('\n')

if "__main__" == __name__:
    p = argparse.ArgumentParser( description=__doc__
            , epilog="Typical use case is to generate additions for docker"
            " images to be consumed by Dockerfile via ADD command." )
    p.add_argument('-d', '--root-dir', help='Base directory for filesystem deployment.')
    p.add_argument('-c', '--config', help='Configuration file.')
    p.add_argument('-l', '--list-sets'
            , help='When given causes the script to print list of sets'
            ' from given configuration file, without generating the'
            ' filesystem subtree.'
            , action='store_true' )
    sys.exit(main(**vars(p.parse_args())))

