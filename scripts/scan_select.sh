#!/usr/bin/env bash
# scan_select.sh <proto> <key>
# click handler for scan panel rows: runs focus lookup then updates focused key defvar
PROTO="$1"
KEY="$2"
[[ -z "$PROTO" || -z "$KEY" ]] && exit 1
~/.config/eww/scripts/scan_focus.sh "$PROTO" "$KEY"
eww update "scan_focused_key=${KEY}"
