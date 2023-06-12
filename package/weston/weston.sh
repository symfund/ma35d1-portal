#!/bin/sh

if test -z "${XDG_RUNTIME_DIR}" ; then
	export XDG_RUNTIME_DIR=/tmp/xdg
	if ! test -d "${XDG_RUNTIME_DIR}" ; then
		mkdir -p "${XDG_RUNTIME_DIR}"
		chmod 0700 "${XDG_RUNTIME_DIR}"
	fi
fi

weston_pid=$(pidof weston)

if [[ -z "${weston_pid}" ]] ; then
	weston --tty=1 --config=/etc/xdg/weston.ini &
fi

# weston 9.0.0, display_id=0
# weston 10.0.0, display_id=1
display_id=0

export WAYLAND_DISPLAY=wayland-${display_id}

if ! test -f "/etc/udev/rules.d/libinput.rules" ; then
	sleep 1
	weston-touch-calibrator /sys/devices/platform/40420000.adc/input/input0/event0
fi
