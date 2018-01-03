#
# Set b to some ephemeral space.
# Set d to the dropbox location.
#
# First, defaults, and make sure they
# are exported.
#
export b=/home2/poppa
export d="$b/Dropbox"

#
# Now try specific versions by OS.
#
case $UNAME_KERNEL_NAME in
Linux)
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
