if [ -n "$DISPLAY" ] && [ -f "$HOME/.Xmodmap" ] ; then
    xmodmap $HOME/.Xmodmap
fi
