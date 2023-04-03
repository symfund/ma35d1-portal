#!/bin/sh

echo "MDEV=$1 : ACTION=$2 : SUBSYSTEM=$SUBSYSTEM : DEVPATH=$DEVPATH : DEVNAME=$DEVNAME" >> /dev/console

destdir=/mnt

autoumount()
{
	if grep -qs "^/dev/${MDEV}" /proc/mounts; then
		umount "${destdir}/${MDEV}";
	fi

	[ -d "${destdir}/${MDEV}" ] && rmdir "${destdir}/${MDEV}"
}

automount()
{
	mkdir -p "${destdir}/${MDEV}" || exit 1

	if ! mount -t auto -O sync "/dev/${MDEV}" "${destdir}/${MDEV}"; then
		rmdir "${destdir}/${MDEV}"
		exit 1
	fi
}

case "${ACTION}" in
add | "")
	autoumount ${MDEV}
	automount ${MDEV}
	;;

remove)
	autoumount ${MDEV}
	;;

esac

