#!/bin/sh
ECHO=
# options may be followed by one colon to indicate they have a required argument
# SHORT_OPTS here has u, h, d and e which take no arguments, and
#            D, t and f which take one argument.
# LONG_OPTS  lists the long options, with two dashes. This example takes
#            user, host, debug and echo which take no arguments, and
#            domain-list, cipher and outfile which all take one argument.
# SHORT_OPTS="uhdeD:t:f:"
# LONG_OPTS=" user,host,debug,echo,domain-list:,cipher:,outfile:
SHORT_OPTS="deHLS:B:"
LONG_OPTS="debug,echo,low,high,sample-rate:,buffer-size:"
if ! options=$(getopt -u -o "$SHORT_OPTS" -l "$LONG_OPTS" -- "$@")
then
    # something went wrong, getopt will put out an error message for us
    exit 1
fi

set -- $options

# Set state variables here.
HIGH_BUFFER_SIZE=1024
LOW_BUFFER_SIZE=128
HIGH_SAMPLE_RATE=48000
CD_SAMPLE_RATE=41000
LOW_SAMPLE_RATE="${CD_SAMPLE_RATE}"
BUFFER_SIZE="${HIGH_BUFFER_SIZE}"
SAMPLE_RATE="${LOW_SAMPLE_RATE}"

while [ $# -gt 0 ]
do
  case "$1" in
    -d|--debug)          
	    set -v
	    ;;
    -e|--echo)
	    ECHO=echo
	    ;;
    -L|--low)
	    SAMPLE_RATE="$HIGH_SAMPLE_RATE"
	    BUFFER_SIZE="$LOW_BUFFER_SIZE"
	    ;;
    -S|--sample-rate)
	    shift; SAMPLE_RATE="$1"
	    ;;
    -B|--buffer-size)
	    shift; BUFFER_SIZE="$1"
	    ;;
    -H|--high)
	    SAMPLE_RATE="$LOW_SAMPLE_RATE"
	    BUFFER_SIZE="$HIGH_BUFFER_SIZE"
	    ;;
    (--)    shift; break;;
    (-*)    echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
    (*)     break;;
    esac
    shift
done

$ECHO env PIPEWIRE_LATENCY="${BUFFER_SIZE}/${SAMPLE_RATE}" "$@"
