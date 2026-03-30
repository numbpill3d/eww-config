#!/bin/bash

interface="$(ip route | grep default | awk '{print $5}')"

# Fallback if no default interface is found
if [ -z "$interface" ]; then
  interface=$(ip -o link show | awk -F': ' '$2 != "lo" && $2 != "tun0" && $2 != "docker0" {print $2; exit}')
fi

if [ -z "$interface" ]; then
  echo "net: n/a"
  exit 0
fi

TX_FILE="/tmp/eww_net_tx_${interface}"
RX_FILE="/tmp/eww_net_rx_${interface}"

current_rx_bytes=$(cat /sys/class/net/$interface/statistics/rx_bytes)
current_tx_bytes=$(cat /sys/class/net/$interface/statistics/tx_bytes)

last_rx_bytes=0
last_tx_bytes=0

if [ -f "$RX_FILE" ]; then
    last_rx_bytes=$(cat "$RX_FILE")
fi

if [ -f "$TX_FILE" ]; then
    last_tx_bytes=$(cat "$TX_FILE")
fi

# Calculate speeds in KB/s
# Ensure we don't divide by zero if it's the first run
if [ "$last_rx_bytes" -eq 0 ] || [ "$last_tx_bytes" -eq 0 ]; then
    rx_speed_kbps=0
    tx_speed_kbps=0
else
    rx_speed_kbps=$(( (current_rx_bytes - last_rx_bytes) / 1024 / 1 )) # assuming 1 second interval
    tx_speed_kbps=$(( (current_tx_bytes - last_tx_bytes) / 1024 / 1 )) # assuming 1 second interval
fi

# Update last bytes files
echo "$current_rx_bytes" > "$RX_FILE"
echo "$current_tx_bytes" > "$TX_FILE"

# Output format: \u<speed> \d<speed>
printf "\u%sKB/s \d%sKB/s\n" "$rx_speed_kbps" "$tx_speed_kbps"
