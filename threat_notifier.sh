#!/bin/bash
KNOWN_DEVICES=$(iw dev wlan0 scan | grep -h 'SSID\|signal')
THRESHOLD=2
for ((i=0; i<=$THRESHOLD; i++)); do
    if ! echo "$KNOWN_DEVICES" | grep -q "Probe response"; then
        eww showmsg $i "ALERT: New device detected: $(jq -n '{}')" logger -t eww
        break
    fi
done
