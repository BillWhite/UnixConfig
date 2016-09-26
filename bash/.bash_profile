#!/bin/bash
. "$HOME/.bash_functions"
echo start bash_profile on $(date) &>> "$HOME/.startup.log"
read_bash_init_files "$HOME/.bash_profile.d" -x &>> "$HOME/.startup.log"
echo end bash_profile on $(date) &>> "$HOME/.startup.log"
