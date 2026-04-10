#!/usr/bin/env bash
# rf_clr_new.sh — mark all currently scanned devices as known, clearing new-device indicators
KNOWN="$HOME/.config/eww/data/known_devices"
mkdir -p "$(dirname "$KNOWN")"

added=0

# mark all ARP/BT keys from live rf scan
python3 -c "
import json, sys
try:
    data = json.load(open('/tmp/eww_rf_devices.json'))
    for d in data:
        k = d.get('key', '')
        if k: print(k)
except: pass
" 2>/dev/null | while IFS= read -r key; do
    grep -qF "$key" "$KNOWN" 2>/dev/null || { echo "$key" >> "$KNOWN"; (( added++ )); }
done

# mark all wifi BSSIDs
python3 -c "
import json, sys
try:
    data = json.load(open('/tmp/eww_wifi_scan.json'))
    for d in data:
        k = d.get('bssid', '')
        if k: print(k)
except: pass
" 2>/dev/null | while IFS= read -r key; do
    grep -qF "$key" "$KNOWN" 2>/dev/null || { echo "$key" >> "$KNOWN"; (( added++ )); }
done

notify-send -t 2000 "rf clear new" "all visible devices marked known" 2>/dev/null || true
