#!/bin/bash

# Find the wireless interface
WIRELESS_IF=$(iw dev | grep interface | awk '{print $2}')

while true; do
  DATA=$(iw dev "$WIRELESS_IF" scan | jq -r '
    .devices[] | [
      .bssid,
      .signal_strength,
      .channel
    ] | @tsv'
  )

  while read -r BSSID SIGNAL CHANNEL; do
    # Skip probe responses
    grep -wFq "Probe Response" - <<< "$SIGNAL" && continue

    # Look for known devices
    if ! grep -q "$BSSID" /var/log/eww/radar.db; then
      echo "$BSSID|$(date +'%Y-%m-%d %H:%M:%S.%3N')" >> /var/log/eww/radar.db
      echo "NEW DEVICE $BSSID" >> /var/log/eww/new_devices.log
    fi
  done <<< "$DATA"

  sleep 5
done
