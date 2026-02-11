#!/bin/bash
mkdir -p /var/log/eww
touch /var/log/eww/radar.db

while true; do
    # Scan network
    DEVICES=$(iw dev wlan0 scan | awk '/SSID:/{getline; print $0; getline; print "")')
    
    # Process devices
    for DEVICE in $(echo "$DEVICES" | grep -i "SSID\|signal" | sed 'N;s/\n/|/'); do
        [[ "$DEVICE" == *"Probe response"* ]] && continue
        IFS='|' read MAC SSID SIGNAL <<< "$DEVICE"
        
        if grep -q "$MAC" /var/log/eww/radar.db; then
            TIMESTAMP=$(date +%s)
            echo "$MAC|$SSID|$TIMESTAMP" >> /var/log/eww/radar.db
        fi
    done
    
    eww scrollup radar
    sleep 5
done
