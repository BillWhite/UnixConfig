#!/bin/bash
. "$HOME/.bash_functions"
to_startup_log echo "start bash_profile on $(date)"
to_startup_log read_bash_init_files "$HOME/.bash_profile.d"
to_startup_log echo "end bash_profile on $(date)"
