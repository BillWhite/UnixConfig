#!/bin/sh
DEBUG="--#"
set -x
status_session.sh --host Localhost $DEBUG; sleep 2
status_session.sh --host Helmsdeep $DEBUG; sleep 2
status_session.sh --host Ranger    $DEBUG; sleep 2
status_session.sh --host Argonath  $DEBUG; sleep 2

xfce4-terminal -T Localhost -e "byobu-tmux attach -t \"Localhost Status\"" \
      --tab    -T Helmsdeep -e "byobu-tmux attach -t \"Helmsdeep Status\"" \
      --tab    -T Ranger    -e "byobu-tmux attach -t \"Ranger Status\"" \
      --tab    -T Argonath  -e "byobu-tmux attach -t \"Argonath Status\""
