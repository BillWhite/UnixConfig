#!/bin/sh

N=1
echo -n mv
for arg in "$@"; do
    echo -n " <$arg>"
    N=$(($N+1))
done
echo
