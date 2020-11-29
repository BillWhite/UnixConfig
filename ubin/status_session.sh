#!/bin/sh

HOST=Localhost

while [ -z "$DONE" ] ; do
  case "$1" in
    --#)
      set -x
      shift
      ;;
    --host|-H)
      shift
      HOST="$1"
      shift
      ;;
    "")
      DONE=YUP
      ;;
    *)
      echo "$0: Unknown command line parameter \"$1\""
      exit 1
      ;;
  esac
done

HOST_SESSION_NAME="$HOST Status"
HOST_NAME="$(echo $HOST | tr [A-Z] [a-z])"

if ! tmux ls 2> /dev/null | grep --quiet "^${HOST_SESSION_NAME}" ; then
    byobu-tmux new-session -d -s "$HOST_SESSION_NAME" -A -n "General" ssh -t "$HOST_NAME" htop
    byobu-tmux split-window -v ssh -t $HOST_NAME NMON=C nmon
    byobu-tmux split-window -h ssh -t $HOST_NAME NMON=jJ nmon

    byobu-tmux new-window -t "$HOST_SESSION_NAME" -d -n CPUS ssh -t "$HOST_NAME" NMON=C nmon

    byobu-tmux new-window -t "$HOST_SESSION_NAME" -d -n "File Systems" ssh -t "$HOST_NAME" NMON=jJ nmon
fi
