
# Try to delete all Docker containers
alias nukec='docker rm $(docker ps -a -q)'
# Try to delete all images
alias nukei='docker rmi $(docker images -q)'

# Show special indicators after each type of file
alias ls='ls -F'

# Multiple terminals in the same TTY, switch with Ctrl-O
alias scr="screen -D -R -e^Oo"

# Prune local merged branches
cat <(git branch --merged | egrep -e '^\(feature|bug|chore\)') | xargs git branch -d
