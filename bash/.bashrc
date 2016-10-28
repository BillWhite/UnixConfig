#!/bin/bash 
. "$HOME/.bash_functions"
to_startup_log echo "start bashrc on $(date)"
to_startup_log read_bash_init_files "$HOME/.bashrc.d"
to_startup_log echo "end bashrc on $(date)"
