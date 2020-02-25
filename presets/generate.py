import os
import sys
import re
import yaml

rxsPortageAtom = r'^(?P<verQuantify>[<>]?[=])?(?P<pkgGroup>[\w\-]+)/(?P<pkgName>[\w\-]+\w)(?:-(?P<pkgVer>[\d.]+))?$'


def main( specFileName, baseDir='2rem' ):
    # Parse specification
    with open(sys.argv[1], 'r') as f:
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
        os.makedirs( os.path.dirname( setFileName ), exist_ok=True )
        with open( setFileName, 'w' ) as setFile:
            setFile.write('\n'.join(pkgNames))
        # Write useflags files (taking deps' use into account)
        # ...
        # Write keywords files (taking deps' use into account)
        # ...
        # TODO: append (?) env file
        # ...

if "__main__" == __name__:
    sys.exit(main( sys.argv[1], sys.argv[2] ))

