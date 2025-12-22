#!/bin/bash

KNOWN_DEVICES=$(iw dev wlan0 scan | jq -r '.devices[] | .bssid' | sort -u | grep -v "Probe Response")

while true; do
  for DEV in $(iw dev wlan0 scan | jq -r '.devices[] | .bssid' | sort -u); do
    if ! grep -qw "$DEV" /var/log/eww/radar.db; then
      echo "$DEV|$(date +'%Y-%m-%d %H:%M:%S.%3N')" >> /var/log/eww/radar.db
      eww showmsg -t "DEVICE DETECTED" "New device detected: $DEV"
    fi
  done
  sleep 60
done
