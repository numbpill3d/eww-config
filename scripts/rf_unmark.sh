#!/usr/bin/env bash
# rf_unmark.sh <key> — remove a device from known_devices (makes it "new" again)
KEY="$1"
[[ -z "$KEY" ]] && exit 1
KNOWN_FILE="$HOME/.config/eww/data/known_devices"
[[ ! -f "$KNOWN_FILE" ]] && exit 0
TMP=$(mktemp)
grep -vF "$KEY" "$KNOWN_FILE" > "$TMP"
mv "$TMP" "$KNOWN_FILE"
