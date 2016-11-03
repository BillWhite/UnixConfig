#!/bin/sh

CMD=--enable

while [ -z "$DONE" ] ; do
  case "$1" in
  --#)
	ECHO=echo
	shift
	;;
  --enable)
	CMD=--enable
	shift
	;;
  --disable)
	CMD=--disable
	shift
	;;
  "")
	DONE=YES
	;;
  *)
	echo "$0: Unknown CLI parameter \"$1\""
	exit 100
  esac
done
ID=$(xinput --list --id-only 'SynPS/2 Synaptics TouchPad')
$ECHO xinput $CMD $ID

