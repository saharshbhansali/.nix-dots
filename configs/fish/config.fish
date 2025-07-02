eval $(starship init fish)

# # Install plugins if not already installed
# set -l plugins \
#     IlanCosman/tide@v5 \
#     jorgebucaran/nvm.fish \
#     jorgebucaran/autopair.fish \
#     PatrickF1/fzf.fish
#
# for plugin in $plugins
#     fisher list | grep -q (string split @ $plugin)[1]; or fisher install $plugin
# end

# Environment variables
if set -q SSH_CONNECTION
    set -gx EDITOR vim
else
    set -gx EDITOR nvim
end
set -gx VISUAL emacs
set -gx VAGRANT_DEFAULT_PROVIDER virtualbox

# Fzf 
# fzf --fish | source
fzf_configure_bindings --variables=\e\cv --history=

# Zoxide
zoxide init fish | source

# Atuin
atuin init fish | source

# Carapace completions
set -gx CARAPACE_BRIDGES "zsh,fish,bash,inshellisense"
carapace _carapace | source

# Pay-respects
pay-respects init fish | source

# Keybindings (example)
bind \cp up-or-search
bind \cn down-or-search
# bind to ctrl-r in normal and insert mode, add any other bindings you want here too
bind \cr _atuin_search
bind -M insert \cr _atuin_search

# Load custom aliases and autorun scripts if they exist
for file in ~/.config/fish/conf.d/*.fish
    test -f $file; and source $file
end
