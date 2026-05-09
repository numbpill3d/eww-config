#!/usr/bin/env bash
# wardrive_status.sh <bssid> <status>
# status: unknown | known | watched | flagged
# also calls wardrive_db focus to refresh /tmp/eww_wardrive_focus
BSSID="$1"
STATUS="$2"
[[ -z "$BSSID" || -z "$STATUS" ]] && exit 1
python3 ~/.config/eww/scripts/wardrive_db.py setstatus "$BSSID" "$STATUS"
python3 ~/.config/eww/scripts/wardrive_db.py focus     "$BSSID"
