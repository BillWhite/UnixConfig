if [ -n "$ARCHITECTURE" ]; then
	PSARCH=": $ARCHITECTURE"
else
	PSARCH=""
fi
export PROMPT_DIRTRIM=5
export PS1=':----------:\n\u@\H: \D{%Y-%m-%d}T\t hist: \! cmd: \#'$PSARCH' \n\w\n:----------:\n> '
unset PSARCH
