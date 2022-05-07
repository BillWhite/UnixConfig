RUSTLOCS="$HOME/2/.cargo $HOME/.cargo"
for rloc in $RUSTLOCS; do
    if [ -x "$rloc/env" ] ; then
        . $rloc/env
	break
    fi
done
