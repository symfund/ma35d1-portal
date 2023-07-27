#!/bin/sh

params="$(getopt -o d:l:o:s:hv -l directory:,label:,out:,size:,help,verbose --name "$(basename "$0")" -- "$@")"

if [ $? -ne 0 ]
then
	echo "no argument present"
fi

eval set -- "$params"
unset params

while true
do
	case $1 in
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
echo "curdir=${curdir}, HOST_DIR=${HOST_DIR}"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
echo "SCRIPT_DIR=${SCRIPT_DIR}"

PATH=${HOST_DIR}/bin:${HOST_DIR}/sbin:$PATH FAKEROOTDONTTRYCHOWN=1 ${HOST_DIR}/bin/fakeroot -- ${SCRIPT_DIR}/make-ext4.sh --directory $directory --label $label --out $out --size $size
