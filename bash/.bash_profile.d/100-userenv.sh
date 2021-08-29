#
# Set b to some ephemeral space.
# Set d to the dropbox location.
#
# First, defaults, and make sure they
# are exported.
#
if [ -d "/home2/poppa" ] ; then
    export b=/home2/poppa
else
    export b="$HOME"
fi
export d="$b/Dropbox"
#
# Now try specific versions by OS.
#
case $UNAME_KERNEL_NAME in
Linux)
    export VISUAL=vi
    export EDITOR=vi
	;;
Darwin)
	;;
esac

#
# Finally, override by host name.
#
case $UNAME_HOST_NAME in
*)
	;;
esac
#
# Set some things that depend on the above.
#
