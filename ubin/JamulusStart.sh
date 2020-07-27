#!/bin/bash

now() {
  echo "$(date "+%s")"
}

log() {
  echo "$@"
}

sessionName() {
  echo "$TAG $(date --iso=seconds | sed 's/:/-/g')"
}

TEMPLATE=JamulusTemplate
TAG="8AJ"
LOGDIR="$HOME/2/tmp"
JACK_LOG_FILE="/dev/null"
BUILT_LOG_FILE="/dev/null"
SABRENT_LOG_FILE="/dev/null"
JAMULUS_LOG_FILE="/dev/null"
ARDOUR_LOG_FILE="/dev/null"
MIDI_LOG_FILE="/dev/null"

while [ -n "$1" ] ; do
  case "$1" in
  --template|-T)
    shift
    TEMPLATE="$1"
    shift
    ;;
  --simple|-S)
    shift
    TEMPLATE='SimpleJamulusTemplate'
    shift
    ;;
  --tag|-G)
    shift
    TAG="$1"
    shift
    ;;
  --log)
    JACK_LOG_FILE="$LOGDIR/jack.log"
    BUILTIN_LOG_FILE="$LOGDIR/builtin_in.log"
    SABRENT_LOG_FILE="$LOGDIR/sabrent_in.log"
    JAMULUS_LOG_FILE="$LOGDIR/jamulus.log"
    ARDOUR_LOG_FILE="$LOGDIR/ardour.log"
    MIDI_LOG_FILE="$LOGDIR/midi.log"
    shift
    ;;
  *)
    echo "$0: Unknown command line parameter \"$1\""
    exit 1
    ;;
  esac
done

lookForPort() {
  local PN="$1"
  P="$(jack_lsp "$PN" 2> /dev/null)"
  if [ -n "$P" ] ; then
    return 0
  else
    return 1
  fi
}

portWait() {
  local TIMEOUT="$1"
  local PORT="$2"
  local NOW="$(now)"
  local FAILTIME="$(( "$NOW" + "$TIMEOUT"))"
  while test "$NOW" -lt "$FAILTIME"; do
    if lookForPort "$PORT"; then
      return 0
    fi
    NOW="$(now)"
    # echo "$NOW:$FAILTIME"
  done
  echo "Timeout waiting for port $PORT"
  return 1
}

isRunning() {
  lookForPort system || \
	lookForPort Jamulus || \
	lookForPort builtin || \
	lookForPort sabrent || \
	return 1
  return 0
}

if isRunning ; then
  echo "$0: Is Jamulus running already?"
  exit 1
fi

log -n "Starting qjackctl..."
(qjackctl --start --preset FastTrack &) >& "$JACK_LOG_FILE"
portWait 3 system:capture || exit 1
log done.

jack_disconnect 'PulseAudio JACK Sink:front-left' 'system:playback_1'
jack_disconnect 'PulseAudio JACK Sink:front-right' 'system:playback_2'
jack_disconnect 'system:capture_1' 'PulseAudio JACK Source:front-left'
jack_disconnect 'system:capture_2' 'PulseAudio JACK Source:front-right'

log -n "Starting Jamulus..."
(Jamulus --nojackconnect &) >& "$JAMULUS_LOG_FILE"
portWait 3 Jamulus || exit 1
log done.

log "Exposing builtin HW..."
(alsa_in -j builtin -dhw:0 &) >& "BUILTIN_LOG_FILE"
portWait 3 builtin || exit 1

(alsa_in -j sabrent -dhw:2 &) >& "$SABRENT_LOG_FILE"
portWait 3 sabrent || exit 1
log done.

log "Exposing midi controllers..."
(a2jmidid -e &) > "$MIDI_LOG_FILE"
portWait 3 a2j:EWI || log "Connect midi controller."
log done.

log "Starting Ardour6..."
(Ardour6 --template "$TEMPLATE" --new "$(sessionName)" &) >& "$ARDOUR_LOG_FILE"
log done.

exec alsamixer -c Track -V all
