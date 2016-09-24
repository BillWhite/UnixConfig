#!/bin/bash 

read_bash_init_files() {
    local CONFIG_HOME="$1"
    local CONFIG_ECHO="$2"

    if [ -z "$CONFIG_ECHO" ] ; then
        CONFIG_ECHO=+x
    fi
    if [ -d "$CONFIG_HOME" ] ; then
        for file in $CONFIG_HOME/[0-9][0-9][0-9]*.sh; do
	    if [ -x "$file" ] ; then
	        (set "$CONFIG_ECHO" ; . "$file")
	    fi
        done
    fi
}

      
