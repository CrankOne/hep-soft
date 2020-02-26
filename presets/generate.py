import os
import sys
import re
import yaml

# Regular expression for the package atom entry
rxsPortageAtom = r'^(?P<verQuantify>[<>]?[=])?(?P<pkgGroup>[\w\-]+)/(?P<pkgName>[\w\-]+\w)(?:-(?P<pkgVer>[\d.]+))?$'

class PersistentFile(object):

    def __init__(self, filename, mode='r'):
        self._fName = filename
        self._fOpenMode = mode

    def __enter__(self):
        os.makedirs( os.path.dirname( self._fName ), exist_ok=True )
        self._f = open(self._fName, self._fOpenMode)
        return self._f

    def __exit__(self, exc_type, exc_value, excTraceback):
        self._f.close()
        self._f = None

def main( specFileName, baseDir='2rem' ):
    """
    Main entry point, deploys file tree.
    """
    # Parse specification
    with open(specFileName, 'r') as f:
        try:
            spec = yaml.safe_load(f)
        except yaml.YAMLError as exc:
            sys.stderr.write(exc)
            sys.exit(1)
    # Generate environment tree
    for setName in sorted(spec.keys()):
        setFileName = os.path.join( baseDir, 'etc/portage/sets', setName )
        pkgNames = sorted(spec[setName].keys())
        # Write set file
        with PersistentFile( setFileName, 'w' ) as setFile:
            setFile.write('\n'.join(pkgNames))
        # Write useflags files (taking deps' use into account)
        # ...
        # Write keywords files (taking deps' use into account)
        # ...
        # TODO: append (?) env file
        # ...

if "__main__" == __name__:
    sys.exit(main( sys.argv[1], sys.argv[2] ))

