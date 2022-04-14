RUSTLOCS="$HOME/2/.cargo $HOME/.cargo"
set -x
for rloc in $RUSTLOCS; do
    if [ -x "$rloc/env" ] ; then
        . $rloc/env
	break
    fi
done
set +x
