# Return 1 if $1 is on the current path.
is_on_path() {
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
        if is_on_path "$DIR" ; then
            export PATH="$PATH:$DIR"
        fi
    fi
}

prepend_to_path() {
    local DIR="$1"
    if [ -d "$DIR" ] ; then
        if is_on_path "$DIR"; then
            export PATH="$DIR:$PATH"
        fi
    fi
}

prepend_to_path "$HOME/ubin"
prepend_to_path "$HOME/vbin"
prepend_to_path "$HOME/.local/bin"
prepend_to_path "/opt/bin"
append_to_path "$ba/bin"

LD_LIBRARY_PATH="/usr/local/lib:/opt/lib:$ba/lib"

export PATH
export LD_LIBRARY_PATH

export PKG_CONFIG_PATH=$ba/lib/pkgconfig

