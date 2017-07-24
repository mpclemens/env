# Mac OS X
if [ -f $(brew --prefix)/etc/bash_completion ]; then
. $(brew --prefix)/etc/bash_completion
fi

# pretty prompt
BLACK="\[$(tput setaf 0)\]"
RED="\[$(tput setaf 1)\]"
BLUE="\[$(tput setaf 4)\]"

BOLD="\[$(tput bold)\]"
RESET="\[$(tput sgr0)\]"

export PS1="${RED}\u@\h${BLACK}:${BOLD}${BLUE}\w${RESET}> "

export EDITOR=`/usr/bin/which emacs`

# Show special indicators after each type of file
alias ls='ls -F'

# Pop my SSH key into the current session to keep from having to re-enter password
/usr/bin/ssh-add ~/.ssh/pslmpc_rsa

# Multiple terminals in the same TTY, switch with Ctrl-O
alias scr="screen -D -R -e^Oo"



