# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#-----------------------------------------------------------------------------------------------------------

# Set the directory we want to store zinit, plugins, and custom scripts
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}}/.config/zinit"
ZINIT_CUSTOM="${XDG_DATA_HOME:-${HOME}}/.config/ohmyzsh-custom"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

## Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

#-----------------------------------------------------------------------------------------------------------

## Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

## Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light akash329d/zsh-alias-finder

## Add in snippets
# OMZ plugins
# source "$ZINIT_CUSTOM/plugins/plugins.zsh"
plugins="common-aliases git asdf aliases archlinux colored-man-pages colorize ssh-agent timer"
for plugin in $(echo "$plugins"); do 
  zinit snippet OMZP::${plugin}
done
zinit snippet OMZL::git.zsh

#-----------------------------------------------------------------------------------------------------------

## Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f $HOME/.p10k.zsh ]] || source $HOME/.p10k.zsh

#-----------------------------------------------------------------------------------------------------------

# user configuration - taken from OMZ

# zsh autosuggestions configure
## ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=white'

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR=vim
else
  export EDITOR=nvim
fi
VISUAL="emacs" ; export VISUAL
EDITOR="nvim" ; export EDITOR
ZELLIJ_AUTO_ATTACH="true"; export ZELLIJ_AUTO_ATTACH
ZELLIJ_AUTO_EXIT="true"; export ZELLIJ_AUTO_EXIT

#-----------------------------------------------------------------------------------------------------------

# NVM setup 
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Vagrant Setup
export VAGRANT_DEFAULT_PROVIDER=virtualbox

#-----------------------------------------------------------------------------------------------------------

# GVM Setup 
#[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

# Load Angular CLI autocompletion.
# source <(ng completion script)

#-----------------------------------------------------------------------------------------------------------

## Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# Fixing the Home, End, Insert, Delete, PageUp and PageDown keys
bindkey "${terminfo[khome]}" beginning-of-line
bindkey "${terminfo[kend]}" end-of-line
bindkey "${terminfo[kich1]}" overwrite-mode
bindkey "${terminfo[kdch1]}" delete-char
bindkey "${terminfo[kpp]}" up-line-or-history
bindkey "${terminfo[knp]}" down-line-or-history
# Fixing the Ctrl+[Left Arrow, Right Arrow] keys for navigation
bindkey "${terminfo[kRIT5]}" forward-word # Control sequence : "^[[1;5C"
bindkey "${terminfo[kLFT5]}" backward-word # Control sequence : "^[[1;5D"

# Fixing Ctrl+W to delete word
# Default: WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>'
WORDCHARS='*?_.[]~=&;!#$%^(){}<>'

#-----------------------------------------------------------------------------------------------------------

# History
HISTSIZE=9999
HISTFILE=$HOME/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups
# setopt glob_dots

# # Command correction
# ENABLE_CORRECTION="true"
# setopt correct

## Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:ls:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:nvim:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:bat:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:cat:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:chezmoi:*' fzf-preview 'ls --color $realpath'

# Carapace completions
export CARAPACE_BRIDGES='zsh' # optional
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
# Define the list of command exceptions
CARAPACE_EXCEPTIONS=(nvim ls la exa eza rm rem rip cd mv cp mkdir md vscode)
# Join the list into a regex pattern: (nvim|ls|la|...)
CARAPACE_PATTERN="($(printf '%s|' "${CARAPACE_EXCEPTIONS[@]}" | sed 's/|$//'))"
# Run carapace and apply the regex pattern via sed
source <(carapace _carapace | sed -E "s/(^|\\s)${CARAPACE_PATTERN}(\\s|$)/ /g")
# source <(carapace _carapace | sed -E 's/(^|\s)(nvim|ls|la|rm|rem|cd|vscode)(\s|$)/ /g')
zstyle ':completion:*:git:*' group-order 'main commands' 'alias commands' 'external commands'

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
# eval "$(thefuck --alias)"
eval "$(pay-respects zsh --alias)"
eval "$(atuin init zsh)"
eval "$(zellij setup --generate-auto-start zsh)"

#-----------------------------------------------------------------------------------------------------------

# Aliases and autorun scripts
source "$ZINIT_CUSTOM/zsh-aliases.zsh"
source "$ZINIT_CUSTOM/zsh-autorun.zsh"
source "$ZINIT_CUSTOM/zsh-pastebin.zsh"

#-----------------------------------------------------------------------------------------------------------
