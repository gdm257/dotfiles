[ ! -n $(command -v ugrep) ] || alias grep="ugrep"
[ ! -n $(command -v ugrep) ] || alias egrep="ugrep"
alias sed="$(which sed) -E" # ERE for LLM and human

[ ! -f "$HOME/.x-cmd.root/X" ] || . "$HOME/.x-cmd.root/X" # boot up x-cmd.

[ ! -n $(command -v mise) ] || eval "$(mise activate bash --shims)" # --shims: equivalent to prepend PATH
# [[ "$OSTYPE" =~ ^(msys|cygwin|mingw) ]] && export PATH="$HOME/AppData/Local/mise/shims:$PATH"

# ======== Interactive Shell ========
[[ $- != *i* ]] && return


set -o vi
