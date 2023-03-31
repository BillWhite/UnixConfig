#!/bin/bash

DISPLAY=:1
export LC_ALL=C

while [ -z "$DONE" ] ; do
  case "$1" in
  --display|-d)
    shift
    DISPLAY="$1"
    shift
    ;;
  :[0-9]*)
    DISPLAY="$1"
    shift
    ;;
  --kill|-k)
    KILL=YES
    shift
    ;;
  "")
    DONE=YES
    ;;
  *)
    echo $0: Unknown command line parameter \"$1\"
    exit 100
    ;;
  esac
done

if [ -n "$KILL" ] ; then
    vncserver -kill "$DISPLAY" &> /dev/null
elif ! xset -display "$DISPLAY" -q &> /dev/null ; then
    exec vncserver -geometry 1800x1000 -depth 16 -dpi 120 -autokill -localhost no "$DISPLAY" >& /dev/null
fi
