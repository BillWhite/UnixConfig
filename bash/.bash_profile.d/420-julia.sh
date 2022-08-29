DIRS="$HOME/2/share"
for d in $DIRS; do
    BD="$d/julia/bin"
    if [ -x "$BD" ] ; then
        prepend_to_path "$BD"
    fi
done
