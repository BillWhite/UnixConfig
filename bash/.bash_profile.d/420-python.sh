# It may be that $b == $HOME.
export WORKON_HOME="$HOME/share/python_venvs"
export PROJECT_HOME="$HOME/share/python_projects"
. virtualenvwrapper.sh

export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
