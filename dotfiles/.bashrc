set -o vi

[ ! -f "$HOME/.x-cmd.root/X" ] || . "$HOME/.x-cmd.root/X" # boot up x-cmd.
[ ! -n $(command -v mise) ] || eval "$(mise activate bash)"
