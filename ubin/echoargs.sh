#!/bin/sh

echo "$1"
N=1
shift
for arg in "$@"; do
    echo "    $N: <$arg>"
    N=$(($N+1))
done
echo
