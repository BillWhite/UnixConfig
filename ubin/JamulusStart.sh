#!/bin/bash

now() {
  echo "$(date "+%s")"
}

log() {
  echo "$@"
}

sessionName() {
  echo "$TAG--$(date --iso=seconds)"
}

TEMPLATE=JamulusTemplate
TAG="8AJ"
LOGDIR="$HOME/2/tmp/JamulusStart.sh"
JACK_LOG_FILE="/dev/null"
BUILTIN_LOG_FILE="/dev/null"
SABRENT_LOG_FILE="/dev/null"
JAMULUS_LOG_FILE="/dev/null"
ARDOUR_LOG_FILE="/dev/null"
MIDI_LOG_FILE="/dev/null"

rm -rf "$LOGDIR"

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

declare -A PIDS
declare -A PRIOS
declare -A NAMES
declare ALLPRIOS

launch() {
  local LOGFILE
  local NAME
  local PRIO
  local ERRORS
  local P
  while [ -n "$1" ] ; do
    case "$1" in
      "--log")
        shift
        LOGFILE="$1"
        shift
	;;
      "--name")
        shift
	NAME="$1"
        shift
        ;;
      "--prio")
        shift
	PRIO="$1"
        shift
        ;;
      --)
	shift
        break
	;;
      --*)
        echo "Unknown launch parameter \"$1\""
	exit 100
	;;
      *)
	break
	;;
    esac
  done
  if [ true ] ; then
    log "Launch \"$NAME\""
    log "  PRIO: \"$PRIO\""
    log "  CMD: \"$@\""
  fi
  if [ -z "$LOGFILE" ] ; then
    log "launch: Need a log file name for a launch."
    ERRORS=YES
  fi
  if [ -z "$NAME" ] ; then
    log "launch: Need a name for a launch."
    ERRORS=YES
  elif [ -n "${NAMES["$NAME"]}" ] ; then
    log "launch: launch \"$NAME\" is multiply defined."
    ERRORS=YES
  else
    NAMES["$NAME"]=1
  fi
  if [ -z "$PRIO" ] ; then
    log "launch: Need a priority for a launch."
    ERRORS=YES
  elif [ -n "${ALLPRIOS["$PRIO"]}" ] ; then
    log "launch: Priority conflict for \"${ALLPRIOS["$PRIO"]}\" and \"$NAME\"."  
    ERRORS=YES
  else
    PRIOS[$NAME]="$PRIO"
    ALLPRIOS[$PRIO]="$NAME"
  fi
  if [ -n "$ERRORS" ] ; then
    exit 100
  fi
  set -x
  P=$(P=$("$@" >& "$LOGFILE" & echo $!); echo $P &)
  set +x
  PIDS["$NAME"]=$P
}

killLaunches() {
  log Launches
  for NAME in ${ALLPRIOS[*]}; do
    kill ${PIDS[$NAME]}
  done
  jack_control exit
}

printLaunches() {
  log Launches
  for NAME in ${ALLPRIOS[*]}; do
    log "Launch : $NAME"
    log " PID: ${PIDS[$NAME]}"
    log " PRIO: ${PRIOS[$NAME]}"
  done
}

if isRunning ; then
  log "$0: Is Jamulus running already?"
  exit 1
fi

#log -n "Starting jackd..."
#launch --name jackd --log "$JACK_LOG_FILE" --prio 1000 -- \
#        /usr/bin/jackd -P10 -p64 -dalsa -r48000 -p256 -n2 -Xseq -D -Chw:Track -Phw:PCH
#portWait 3 system:capture || exit 1
#log done

# Don't really know why this is different.
# log -n "Starting qjackctl..."
# (qjackctl &)
jack_control start

jack_disconnect 'PulseAudio JACK Sink:front-left' 'system:playback_1'
jack_disconnect 'PulseAudio JACK Sink:front-right' 'system:playback_2'
jack_disconnect 'system:capture_1' 'PulseAudio JACK Source:front-left'
jack_disconnect 'system:capture_2' 'PulseAudio JACK Source:front-right'

log -n "Starting Jamulus..."
launch --name Jamulus --log "$JAMULUS_LOG_FILE" --prio 500 -- \
	Jamulus --nojackconnect 
portWait 3 Jamulus || exit 1
log done.

log "Exposing builtin HW..."
launch --name "builtin" --log "$BUILTIN_LOG_FILE" --prio 250 -- \
	alsa_in -j builtin -dhw:0 
portWait 3 builtin || exit 1
log done.

log "Exposing Sabrent USB Device."
launch --name "sabrent" --log "$SABRENT_LOG_FILE" --prio 251 -- \
	alsa_in -j sabrent -dhw:Device 
# Don't wait exit. It may not be there.
log done.

log "Exposing midi controllers..."
launch --name "midi" --log "$MIDI_LOG_FILE" --prio 252 -- \
	a2jmidid -e > "$MIDI_LOG_FILE"
portWait 3 a2j:EWI
log "Connect midi controller."
log done.

log "Starting Ardour6..."
launch --name Ardour --log "$ARDOUR_LOG_FILE" --prio 0 -- \
	Ardour6 --template "$TEMPLATE" --new "$(sessionName)"
log done.

printLaunches

alsamixer -c Track -V all

killLaunches

