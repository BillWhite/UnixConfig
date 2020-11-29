#!/bin/sh
set -x
status_session.sh --host Localhost ; sleep 2
status_session.sh --host Helmsdeep ; sleep 2
status_session.sh --host Ranger ; sleep 2
status_session.sh --host Argonath ; sleep 2

xfce4-terminal -T Localhost -e "byobu-tmux attach -t \"Localhost Status\"" \
      --tab    -T Helmsdeep -e "byobu-tmux attach -t \"Helmsdeep Status\"" \
      --tab    -T Ranger    -e "byobu-tmux attach -t \"Ranger Status\"" \
      --tab    -T Argonath  -e "byobu-tmux attach -t \"Argonath Status\""
