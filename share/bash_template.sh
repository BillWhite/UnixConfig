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
if ! options=$(getopt -u -o "$SHORT_OPTS" -l "$LONG_OPTS" -- "$@")
then
    # something went wrong, getopt will put out an error message for us
    exit 1
fi

set -- $options

# Set state variables here.

while [ $# -gt 0 ]
do
  case $1 in
    (--)                 shift; break;;
    (-*) echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
    (*) break;;
    esac
    shift
done
