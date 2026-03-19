#!/bin/sh

###############
# Cycle windows
# (C) 2022 Natalie Clarius <natalie_clarius@yahoo.de>
# GNU General Public License v3.0
###############

# Repo: https://github.com/nclarius/shell-scripts/tree/main/alt-tab

### Usage:
## > alt_tab.sh  # switch windows in forwards direction
## > alt_tab.sh shift  # switch windows in backwards direction

timer_file="/tmp/gestures-alt_tab_timer.txt"

[ -e "$timer_file" ]; echo "Alt_Tab timer file found" || date +%s%N  | cut -b1-13 > "$timer_file"

if [[ $(( $(date +%s%N | cut -b1-13 ) - $(cat "$timer_file") )) -ge 1000 ]]
then	
	xdotool keydown alt
fi
date +%s%N  | cut -b1-13 > "$timer_file"

case "$@" in
	shift)
		xdotool key Shift+Tab
		;;
	*)
		xdotool key Tab
		;;
esac

sleep 1
if [[ $(( $(date +%s%N | cut -b1-13) - $(cat "$timer_file") )) -ge 1000 ]]
then
	xdotool keyup alt
fi
