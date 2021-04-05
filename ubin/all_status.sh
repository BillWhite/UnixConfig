#!/bin/sh

while [ -z "$DONE" ] ; do
  case "$1" in
    --#)
      DEBUG="--#"
      set -x
      shift
      ;;
    "")
      DONE=YUP
      ;;
    *)
      echo "$0: Unknown command line parameter \"$1\""
      exit 100
  esac
done

status_session.sh --host Localhost $DEBUG
status_session.sh --host Helmsdeep $DEBUG
status_session.sh --host Ranger    $DEBUG
status_session.sh --host Argonath  $DEBUG

xfce4-terminal -T Localhost -e "byobu-tmux attach -t \"Localhost Status\"" \
      --tab    -T Helmsdeep -e "byobu-tmux attach -t \"Helmsdeep Status\"" \
      --tab    -T Ranger    -e "byobu-tmux attach -t \"Ranger Status\"" \
      --tab    -T Argonath  -e "byobu-tmux attach -t \"Argonath Status\""
