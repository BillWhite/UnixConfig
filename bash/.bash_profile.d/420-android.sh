DIRS="/opt /usr/opt /home2/opt"
for d in $DIRS; do
    BD="$d/android-studio/bin"
    if [ -x "$BD" ] ; then
        prepend_to_path "$BD"
    fi
done
export ANDROID_SDK_ROOT=/home2/poppa/Android/Sdk
append_to_path "$ANDROID_SDK_ROOT/emulator"
append_to_path "$ANDROID_SDK_ROOT/platform-tools"
