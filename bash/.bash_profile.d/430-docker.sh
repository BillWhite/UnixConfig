if [ -n "$IN_DOCKER" ] ; then
    case "$ARCHITECTURE" in
    CENTOS6)
	echo 'C6 Docker'
        source scl_source enable python27
	;;
    esac
fi
