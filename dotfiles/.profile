# Keep POSIX sh syntax ONLY

export LANG="en_US.UTF-8"

[ -n "$BASH_VERSION" ] && [ -e "$HOME/.bashrc" ] && . "$HOME/.bashrc"
[ -n "$ZSH_VERSION" ] && [ -e "$HOME/.zshrc" ] && . "$HOME/.zshrc"
