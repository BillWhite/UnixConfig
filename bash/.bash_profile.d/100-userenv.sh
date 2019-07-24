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
export gd="$b/googledrive"
#
# Now try specific versions by OS.
#
case $UNAME_KERNEL_NAME in
Linux)
    export VISUAL=vi
	;;
Darwin)
	;;
esac

#
# Finally, override by host name.
#
case $UNAME_HOST_NAME in
radagast)
	# Use the defaults
	;;
bills-u14|bills-ubuntu)
	b=$HOME
	d=$HOME/Dropbox
	;;
bills-mbp)
	b=$HOME
	d=$HOME/Dropbox
	;;
*)
	;;
esac
#
# Set some things that depend on the above.
#
export ba="$b/arch/glnxa64"
