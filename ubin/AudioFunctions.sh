LOG_FILE="/dev/null"

log() {
    echo "$@"
}

if [ -z "$TAG" ] ; then
    log "$0: Expected TAG to be set."
    exit 100
fi
if [ -z "$TEMPLATE" ] ; then
    log "$0: Expected TEMPLATE to be set."
    exit 100
fi

now() {
    echo "$(date "+%s")"
}

sessionName() {
    echo "$TAG $(date '+%Y-%m-%dT%H-%M-%SZUT%z')"
}

waitForEnd() {
    alsamixer -c Track -V all
}

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
            LOG_FILE="$LOGDIR/log.txt"
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
  	lookForPort system || return 1
    return 0
}

declare -A PIDS
declare -A PRIOS
declare -A NAMES
declare ALLPRIOS

launch() {
    local NAME
    local PRIO
    local ERRORS
    local P
    while [ -n "$1" ] ; do
        case "$1" in
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
    P=$(P=$("$@" >& "$LOG_FILE" & true ; echo $!); echo $P &)
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

start_jackd() {
    # Don't really know why this is different.
    # log -n "Starting qjackctl..."
    local PRESET
    local DONE=""
    local DISCONNECT_PULSEAUDIO=""
    while [ -n "$1" ] ; do
        case "$1" in
             "--preset")
                 shift
                 PRESET="$1"
                 shift
                 ;;
             "--disconnect-pulseaudio")
                 DISCONNECT_PULSEAUDIO=YES
                 shift
                 ;;
             "")
                 DONE=YES
                 ;;
             *)
                 log "$0: Unknown argument to start_jackd: $1"
                 exit 100
                 ;;
        esac
    done
    launch --name jackd --prio 1000 -- \
	       qjackctl --start --preset "$PRESET"
    portWait 3 system:playback_1

    if [ -n "$DISCONNECT_PULSEAUDIO" ] ; then
        jack_disconnect 'PulseAudio JACK Sink:front-left' 'system:playback_1'
        jack_disconnect 'PulseAudio JACK Sink:front-right' 'system:playback_2'
        jack_disconnect 'system:capture_1' 'PulseAudio JACK Source:front-left'
        jack_disconnect 'system:capture_2' 'PulseAudio JACK Source:front-right'
    fi
}
