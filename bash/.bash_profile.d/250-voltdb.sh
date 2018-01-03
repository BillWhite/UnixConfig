export W="$b/workspaces/workspace.vdb"
export R="$b/repro"
if [ -d "$HOME/cbin" ] ; then
    prepend_to_path "$HOME/cbin"
fi
if [ -d "$HOME/vbin" ] ; then
    prepend_to_path "$HOME/vbin"
fi
