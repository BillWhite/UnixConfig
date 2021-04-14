#!/bin/bash

TEMPLATE=JamulusTemplate
TAG="8AJ"
LOGDIR="$HOME/2/tmp/JamulusStart.sh"
. AudioFunctions.sh

if isRunning ; then
    log "$0: Is Jamulus running already?"
    exit 1
fi

JACK_PRESET=FastTrack

log -n "Start qjackctl."
start_jackd --preset FastTrack --disconnect-pulseaudio

log -n "Starting Jamulus..."
launch --name Jamulus --prio 500 -- \
	   Jamulus --nojackconnect 
portWait 3 Jamulus || exit 1
log done.

log "Exposing builtin HW..."
launch --name "builtin" --prio 250 -- \
	   alsa_in -j builtin -dhw:0 
portWait 3 builtin || exit 1
log done.

log "Launching zita monitoring tool"
launch --name zita --prio 253 -- \
	   zita-mu1
portWait 3 zita-mu1:in_1.L
#
# The zita outputs don't get set up by Ardour, since
# Ardour doesn't know anything about them.
#
jack_connect zita-mu1:mon_out1.L system:playback_1
jack_connect zita-mu1:mon_out1.R system:playback_2
log "done"

log "Launching qas mixer."
launch --name qasmixer --prio 254 -- \
	   qasmixer > "$LOG_FILE" 2>&1
log done

SESSION_NAME="$(sessionName)"
log "Starting Ardour6 Session <$SESSION_NAME>..."
launch --name Ardour --prio 0 -- \
	   Ardour6 --template "$TEMPLATE" --new "$SESSION_NAME"
log done.

printLaunches

waitForEnd

killLaunches

