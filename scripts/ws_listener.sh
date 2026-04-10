#!/usr/bin/env bash
# ws_listener.sh — streams focused workspace name for eww deflisten
# outputs current workspace first, then streams changes

# emit current workspace immediately so eww has an initial value
swaymsg -t get_workspaces | jq -r '.[] | select(.focused) | .name'

# stream workspace focus changes
exec swaymsg -m -t subscribe '["workspace"]' \
  | jq --unbuffered -r 'select(.change=="focus") | .current.name'
