#!/usr/bin/env bash
# rf_nick.sh <key> <nickname>
# sets or clears a nickname for a device (key = IP for ARP, MAC for BT/wifi)
# pass empty string or "-" as nickname to remove it

KEY="$1"
NICK="$2"
[[ -z "$KEY" ]] && exit 1

NICK_FILE="$HOME/.config/eww/data/device_nicknames"
mkdir -p "$(dirname "$NICK_FILE")"
touch "$NICK_FILE"

TMP=$(mktemp)
grep -v "^${KEY} " "$NICK_FILE" > "$TMP" 2>/dev/null
if [[ -n "$NICK" && "$NICK" != "-" ]]; then
    printf '%s %s\n' "$KEY" "$NICK" >> "$TMP"
fi
mv "$TMP" "$NICK_FILE"
