## Environmental Variable Setup

# Gradle Setup
# GRADLE="/opt/gradle/gradle-7.5.1/bin:"

# Nessus Setup 
# NESSUS="/opt/nessus:"

# Ruby Gem Setup
# export GEM_BIN="$HOME/.local/share/gem/ruby/3.0.0/bin"
# export GEM_HOME="$HOME/.gems/"
# export GEM_BIN="$HOME/.gems/bin"
# source /usr/share/rvm/scripts/rvm
RBENV_PATH="$HOME/.rbenv/shims/"
# eval "$(rbenv init -)"

# GoLang Setup 
# export GOROOT="/opt/go"
# export GO_USER="$HOME/go/bin/"
GO_ALL=""
# GO_BIN="/opt/go/bin/bin"
# export GOPATH="/opt/go/bin/"
# GO_ALL="$GOPATH:$GO_BIN"

# Node Setup
# NODE="$HOME/.nvm/versions/node/v16.17.0/bin:"

# Set all system related paths
export SYSTEM_BINS="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/lib64/ccache:/var/lib/snapd/snap/bin"

# Set all home related paths
export HOME_BINS="$HOME/bin:$HOME/.local/bin"
export XDG_CONFIG_HOME="$HOME/.config/"

# Set Spicetify path
SPICETIFY="$HOME/.spicetify"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# export PATH="$PATH:$SYSTEM_BINS:$HOME_BINS:$XDG_CONFIG_HOME:$SPICETIFY:$RBENV_PATH:$GO_ALL"
# export PATH="$PATH:$SYSTEM_BINS:$HOME_BINS:$XDG_CONFIG_HOME:$SPICETIFY"
export PATH="$PATH:$HOME_BINS:$XDG_CONFIG_HOME:$SPICETIFY"

