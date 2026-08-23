### SHELL ALIASES  ###

# Hibernate Aliases

alias 'hibernate'='sudo systemctl hibernate'
alias 'pm-hib'='sudo pm-hibernate'

# Information and Movement Aliases

alias 'lsx'='exa --color=auto --icons=auto'
alias 'ls'='ls --color=auto'
alias 'lss'='exa -lahg --color=auto --icons=auto'
alias 'la'='exa -lahg --color=auto --git --icons=auto'
# alias 'cat'='bat'
alias '..'='cd ..'
alias '.1'='cd ..'
alias '.2'='cd ../..'
alias '.3'='cd ../../..'
alias '.4'='cd ../../../..'
alias '.d'='cd ~/Desktop/.desktopstuff'
alias '.Dk'='~/Desktop/'
alias '.Dw'='~/Downloads/'
alias '.Dp'='~/Downloads/packages/'
alias '..d'='~/.dotfiles'
alias '..c'='~/.config'
# alias '.CS'='~/Downloads/packages/CyberSecurity/'

# Cloudflare VPN aliases

# alias 'cf-on'='warp-cli connect && ping 8.8.8.8 -c 5'
# alias 'cf-off'='warp-cli disconnect'
# alias 'cf-on'='wg-quick up cloudflare && ping 8.8.8.8 -c 5'
# alias 'cf-off'='wg-quick down cloudflare'

## Git Aliases
alias 'uncommit'='git reset --soft HEAD~1'

# Confirmations

## File manipulation
# alias 'mv'='mv -i'
# alias 'cp'='cp -i'
# alias 'rm'='rm -i'
#alias 'rip'='rip -i'
alias 'rem'='rip -i'
# alias 'ln'='ln -i'
alias 'ip'='ip -c'

## pkill
alias 'pkill'='pkill -e'

# Diff 
alias 'vdiff'="diff --color -EZy"

diff_so_fancy() { 
  diff -u $1 $2 | diff-so-fancy
}
alias 'dsf'='diff_so_fancy'

# Creating directories

alias 'mkalldir'='mkdir -p -v'
alias 'md'='mkdir -p -v'

# Clipboard

alias 'clipC'='xclip -sel clip'
alias 'clipP'='xclip -sel clip -o'
alias 'xC'='xsel -ib'
alias 'xP'='xsel -ob'
alias 'wlC'='wl-copy'
alias 'wlP'='wl-paste'
alias 'wlCp'='wl-copy -p'
alias 'wlPp'='wl-paste -p'
alias 'cliphist-remove'='cliphist list | rofi -dmenu -no-custom -p "[Enter] repeat; [ESC] exit" | cliphist delete'

# Grep 
alias 'egrep'='grep -iE'

# Picom

# alias 'effects'='picom --experimental-backends -b'

# Rofi

# alias 'menu'='rofi -show run'
# alias 'menu'='rofi -combi-modi window,drun,ssh -theme Arc-Dark -font "hack 12" -show combi 2>&1 /dev/null &'

# Brightness

# alias 'brightness'='xrandr --brightness'

# Weather Report

alias 'weather'='curl wttr.in'

# Spotify TUI

alias 'sptui'='spotifyd --no-daemon &> /dev/null &; spt'

# Export all aliases 
alias 'export-aliases'='alias | sed -E "s/([^=]*)=(.*)/alias '\1'=\2/; p" > aliases.zsh'

# Zed Editor
alias 'zed'='zeditor'

# Obsidian MainVault Alias
alias 'OMV'="~/obsidian-MainVault/"

# Logging into NotEC2 VPS

# alias 'NotEC2'='ssh azureuser@20.219.12.205 -i ~/.ssh/NotEC2_key.pem'

#user="azureuser"
#ip="20.219.12.205"
#key="~/.ssh/NotEC2_key.pem"
#alias 'NotEC2'="ssh $user@$ip -i $key"

# CyberSec Lists Shortcuts

## SecLists Shortcut
## KaliLists Shortcut
## Auto_Wordlists Shortcut

# CyberSec Tools Aliases

## Metasploit Alias
## Ghidra Alias
## ZAP Alias
## IDA Free Alias
## John The Ripper Alias 
## Gobuster Alias
## Nessus Alias

# Other Tool Aliases
## Postman Alias

