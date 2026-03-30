#!/usr/bin/env bash
# rf_mark.sh <key> — mark a device as known (key = IP for ARP, MAC for BT)
key="$1"
[[ -z "$key" ]] && exit 1
# accept IPv4 or MAC
if [[ ! "$key" =~ ^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$ ]] && \
   [[ ! "$key" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
  exit 1
fi
file="$HOME/.config/eww/data/known_devices"
mkdir -p "$(dirname "$file")"
grep -qF "$key" "$file" 2>/dev/null || echo "$key" >> "$file"
