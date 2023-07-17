#!/bin/bash

set -e


params="$(getopt -o e:d:l:o:s:hv -l exclude:,directory:,label:,out:,size:,help,verbose --name "$(basename "$0")" -- "$@")"

if [ $? -ne 0 ]
then
	echo "no argument present"
fi

eval set -- "$params"
unset params

while true
do
	case $1 in
		-e|--exclude)
			excludes+=("$2")
			shift 2
			;;
		-d|--directory)
			directory=$2
			shift 2
			;;
		-l|--label)
			label=$2
			shift 2
			;;
		-o|--out)
			out=$2
			shift 2
			;;
		-s|--size)
			size=$2
			shift 2
			;;
		-h|--help)
			echo "Help"
			;;
		-v|--verbose)
			verbose='--verbose'
			shift
			;;
		--)
			shift
			break
			;;
		*)
			echo "Usage"
			;;
	esac
done

echo "--directory=$directory, --label=$label, --out=$out, --size=$size"



curdir=$(pwd)
HOST_DIR=${curdir}/output/host

chown -h -R 0:0 $directory
${HOST_DIR}/sbin/mkfs.ext4 -d $directory -r 1 -N 0 -m 5 -L $label -O ^64bit $out $size

