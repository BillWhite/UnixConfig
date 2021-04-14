if [ -n "$ARCHITECTURE" ]; then
	PSARCH=": $ARCHITECTURE"
else
	PSARCH=""
fi
export PROMPT_DIRTRIM=5

function virtualenv_info(){
    # Get Virtual Env
    if [[ -n "$VIRTUAL_ENV" ]]; then
        # Strip out the path and just leave the env name
        venv="${VIRTUAL_ENV##*/}"
        venv="${venv%%-*}"
    else
        # In case you don't have one activated
        venv=''
    fi
    [[ -n "$venv" ]] && echo '<<'" $venv "'>>'
}

# disable the default virtualenv prompt change
export VIRTUAL_ENV_DISABLE_PROMPT=1

VENV="\$(virtualenv_info)";
# the '...' are for irrelevant i

export PS1=':-----'"${VENV}"'-----:\n\u@\H: \D{%Y-%m-%d}T\t hist: \! cmd: \#'$PSARCH' \n\w\n:-----'"${VENV}"'-----:\n> '
unset PSARCH
