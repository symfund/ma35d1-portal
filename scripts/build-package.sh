#!/bin/sh

# -------> A clever way to rebuild packages in Buildroot <----------

usage()
{
echo -e "
=============================== USAGE ======================================

Usage: $ source /path/to/build-package.sh pkg <rebuild | clean | none>
Usage:
	pkg     -- the package name. Special packages are 'rootfs' and 'all'
	rebuild -- rebuild package without clean
	clean   -- clean then build package
	none    -- the same as clean 

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

if [[ "$1" == "rootfs" ]]; then
	if [[ "$2" == "clean" ]] || test -z "$2"; then
        	rm -Rf output/target
		find output/build -name ".stamp_target_installed" | xargs rm -Rf
		make host-gcc-final-rebuild
		make ; return
	fi

	if [[ "$2" == "rebuild" ]]; then
		make ; return
	fi

	echo "method '$2' not support"
	return
fi

if [[ "$1" == "all" ]]; then
        if [[ "$2" == "clean" ]] || test -z "$2"; then
                rm -Rf output/target
                find output/build -name ".stamp_target_installed" | xargs rm -Rf
		make uboot-dirclean arm-trusted-firmware-dirclean host-uboot-tools-dirclean linux-dirclean optee-os-dirclean
		make host-gcc-final-rebuild
                make ; return
        fi

        if [[ "$2" == "rebuild" ]]; then
		echo "rebuild all is not safe, do nothing"
                return
        fi

        echo "method '$2' not support"
        return
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
