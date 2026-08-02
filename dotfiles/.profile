# Keep POSIX sh syntax ONLY

export LANG="en_US.UTF-8"
PROXY="http://127.0.0.1:7890"
NO_PROXY="localhost,127.0.0.1,::1,.local,192.168.0.0/16,10.0.0.0/8"
export http_proxy="$PROXY"   https_proxy="$PROXY"   all_proxy="$PROXY"   no_proxy="$NO_PROXY"
export HTTP_PROXY="$PROXY"   HTTPS_PROXY="$PROXY"   ALL_PROXY="$PROXY"   NO_PROXY="$NO_PROXY"

[ -n "$BASH_VERSION" ] && [ -e "$HOME/.bashrc" ] && . "$HOME/.bashrc"
[ -n "$ZSH_VERSION" ] && [ -e "$HOME/.zshrc" ] && . "$HOME/.zshrc"
