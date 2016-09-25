if [ -z "$LOGIN_PATH" ] ; then
    export LOGIN_PATH="$PATH"
fi

PATH="$LOGIN_PATH"

prepend_to_path "$HOME/bin"
append_to_path "$HOME/.local/bin"
append_to_path "$ba/bin"

LD_LIBRARY_PATH="/usr/local/lib:$ba/lib"

export PATH
export LD_LIBRARY_PATH

export PKG_CONFIG_PATH=$ba/lib/pkgconfig

