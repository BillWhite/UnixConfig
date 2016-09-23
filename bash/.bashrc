#!/bin/bash

BASH_CONFIG_HOME=$HOME/.bashrc.d
if [ -d "$BASH_CONFIG_HOME" ] ; then
    for file in "$BASH_CONFIG_HOME/[0-9][0-9][0-9]*.sh"; do
	if [ -x "$file" ] ; then
	    . "$file"
	fi
    done
fi

      
