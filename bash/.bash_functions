#!/bin/bash 

read_bash_init_files() {
    local CONFIG_HOME="$1"
    local INIT_FILES
    local file
    init_startup_log
    if [ -d "$CONFIG_HOME" ] ; then
        INIT_FILES="$CONFIG_HOME/[0-9][0-9][0-9]*.sh"
        for file in $INIT_FILES; do
	    if [ -x "$file" ] ; then
                to_startup_log echo "Reading file $file"
	        . "$file" &>> "$STARTUP_LOG"
	    fi
        done
    fi
}

init_startup_log() {
    if [ -z "$STARTUP_LOG" ] ; then
        export STARTUP_LOG="$HOME/.startup.log"
        cp /dev/null "$HOME/.startup.log"
    fi
}

to_startup_log() {
    init_startup_log
    $@ &>> "$STARTUP_LOG"
}

# set PATH so it includes user's private bin if it exists
clean_path() {
    local DIR="$1"
    local EXPLODED_PATH
    if [ -d "$DIR" ] ; then
        EXPLODED_PATH=$(echo "$PATH" | tr ':' ' ')
        for P in $EXPLODED_PATH ; do
            if [ $P == "$DIR" ]; then
                return 1
            fi
        done
        return 0
    fi
}

append_to_path() {
    local DIR="$1"
    if [ -d "$DIR" ] ; then
        if clean_path "$DIR" ; then
            export PATH="$PATH:$DIR"
        fi
    fi
}

prepend_to_path() {
    local DIR="$1"
    if [ -d "$DIR" ] ; then
        if clean_path "$DIR"; then
            export PATH="$DIR:$PATH"
        fi
    fi
}

