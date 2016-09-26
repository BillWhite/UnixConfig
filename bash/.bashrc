#!/bin/bash 
touch $HOME/.startup.log
. "$HOME/.bash_functions"
echo start bashrc on $(date) &>> "$HOME/.startup.log"
read_bash_init_files "$HOME/.bashrc.d" "-x" &>> "$HOME/.startup.log"
echo end bashrc on $(date) &>> "$HOME/.startup.log"
