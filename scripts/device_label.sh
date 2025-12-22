#!/bin/bash
MAC="$1"
LABEL="$2"
FILE="$HOME/.config/eww/data/known_devices"

if [[ -z "$MAC" || -z "$LABEL" ]]; then
    echo "Usage: $0 <MAC> <LABEL>"
    exit 1
fi

# Remove existing entry
grep -v "^$MAC=" "$FILE" 2>/dev/null > "$FILE.tmp"
# Add new entry
echo "$MAC=$LABEL" >> "$FILE.tmp"
mv "$FILE.tmp" "$FILE"
echo "Label updated"
