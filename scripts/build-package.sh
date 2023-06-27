#!/bin/sh

# -------> A clever way to rebuild packages in Buildroot <----------

usage()
{
echo -e "
=============================== USAGE ================================

Usage: $ source /path/to/build-package.sh pkg <rebuild | clean | none>
Usage:
	pkg     -- the package name
	rebuild -- rebuild package without clean
	clean   -- clean then build package
	none    -- the same as clean, build package with no arguments 

Usage: ex 1 (none)
	$ source /path/to/build-package.sh uboot

Usage: ex 2 (rebuild)
	$ source /path/to/build-package.sh uboot rebuild

Usage: ex 3 (clean)
	$ source /path/to/build-package.sh uboot clean
"
}

if test -z "$1" ; then
	echo "ERROR: missing package name"
	usage
	return 1
fi

echo "-----> The following packages depends on $1 <-----"
dependChains=$(make $1-show-recursive-rdepends)
make $1-show-recursive-rdepends
echo

for pkg in ${dependChains[@]}
do
	make $pkg-dirclean
done

if [[ "$2" == "clean" ]] || test -z "$2" ; then
	make $1-dirclean
fi

make $1-rebuild ; make
