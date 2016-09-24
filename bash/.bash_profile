#!/bin/bash

PROFILE_CONFIG_HOME=$HOME/.bash_profile.d
if [ -d "$PROFILE_CONFIG_HOME" ] ; then
    for file in "$PROFILE_CONFIG_HOME/[0-9][0-9][0-9]*.sh"; do
	if [ -x "$file" ] ; then
	    . "$file"
	fi
    done
fi

      
