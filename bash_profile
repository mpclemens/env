# Mac OS X
if [ -f $(brew --prefix)/etc/bash_completion ]; then
. $(brew --prefix)/etc/bash_completion
fi

# Add the ssh key if it's not already in place
# if [ -z "$(ssh-add -L | grep mclemens)" ]; then
#   ssh-add ~/.ssh/britco_rsa
# fi

# pretty prompt
BLACK="\[$(tput setaf 0)\]"
RED="\[$(tput setaf 1)\]"
BLUE="\[$(tput setaf 4)\]"

BOLD="\[$(tput bold)\]"
RESET="\[$(tput sgr0)\]"

export PS1="${RED}\u@\h${BLACK}:${BOLD}${BLUE}\w${RESET}> "

export EDITOR=`/usr/bin/which atom`
if [ -z "$EDITOR" ]; then
    export EDITOR=`/usr/bin/which emacs`
fi

# shamlessly borrowed from the web
function urldecode() {
        echo -ne $(echo -n "$1" | sed -E "s/%/\\\\x/g")
}

export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go

# Autocomplete git happiness

# curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash

if [ -f ~/.git-completion.bash ]; then
  . ~/.git-completion.bash
fi

#

source ${HOME}/.bash_aliases
