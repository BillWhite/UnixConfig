#!/bin/bash 
. "$HOME/.bash_functions"
to_startup_log echo "start bashrc on $(date)"
to_startup_log read_bash_init_files "$HOME/.bashrc.d"
to_startup_log echo "end bashrc on $(date)"

# tabtab source for electron-forge package
# uninstall by removing these lines or running `tabtab uninstall electron-forge`
[ -f /usr/lib/node_modules/electron-forge/node_modules/tabtab/.completions/electron-forge.bash ] && . /usr/lib/node_modules/electron-forge/node_modules/tabtab/.completions/electron-forge.bash