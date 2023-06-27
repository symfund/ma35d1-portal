#!/bin/sh

export TSLIB_TSDEVICE=/dev/input/event0
export TSLIB_CALIBFILE=/etc/pointercal

if [[ ! -f "$TSLIB_CALIBFILE" ]]; then
	ts_calibrate
fi
