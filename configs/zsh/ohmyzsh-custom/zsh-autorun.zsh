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
# RBENV_PATH="$HOME/.rbenv/shims/"
# eval "$(rbenv init -)"

# GoLang Setup 
# export GOROOT="$(go env GOROOT)"
# export GOPATH="$(go env GOPATH)"
export GOROOT="$(go env GOROOT)"
export GOPATH="$HOME/go/"
export GO_BIN="$GOPATH/bin/"
GO_ALL="$GOPATH:$GO_BIN"

# Node Setup
# NODE="$HOME/.nvm/versions/node/v16.17.0/bin:"

# Bun bin setup
BUN_BIN="$HOME/.cache/.bun/bin/"

# volta
export VOLTA_PATH="$HOME/.volta/bin/"
case ":$PATH:" in
  *":$VOLTA_PATH:"*) VOLTA_HOME="" ;;
  *) VOLTA_HOME="$VOLTA_PATH" ;;
esac
# volta end

# Rust Setup
CARGO_HOME="$HOME/.cargo/bin"

# Set Spicetify path
SPICETIFY="$HOME/.spicetify"

# Set all system related paths
export SYSTEM_BINS="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/lib64/ccache:/var/lib/snapd/snap/bin"

# Set all home related paths
export HOME_BINS="$HOME/bin:$HOME/.local/bin"
export XDG_CONFIG_HOME="$HOME/.config/"
BINS="$HOME_BINS:$GO_ALL:$CARGO_HOME:$VOLTA_HOME:$BUN_BIN"

# export PATH="$PATH:$SYSTEM_BINS:$HOME_BINS:$XDG_CONFIG_HOME:$SPICETIFY:$RBENV_PATH:$GO_ALL"
# export PATH="$PATH:$SYSTEM_BINS:$HOME_BINS:$XDG_CONFIG_HOME:$SPICETIFY"
export PATH="$PATH:$BINS:$XDG_CONFIG_HOME:$SPICETIFY"

