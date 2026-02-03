set -o vi

[ ! -f "$HOME/.x-cmd.root/X" ] || . "$HOME/.x-cmd.root/X" # boot up x-cmd.
[ ! -n $(command -v mise) ] || eval "$(mise activate bash)"

export OPENCODE_EXPERIMENTAL=true
export OPENCODE_EXPERIMENTAL_MARKDOWN=true
export OPENCODE_EXPERIMENTAL_LSP_TOOL=true
