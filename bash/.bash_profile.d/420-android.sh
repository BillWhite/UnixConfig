DIRS="/opt /usr/opt /home2/opt"
for d in $DIRS; do
    BD="$d/android-studio/bin"
    if [ -x "$BD" ] ; then
        prepend_to_path "$BD"
    fi
done
