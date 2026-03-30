#!/bin/bash
# Outputs RX_KBPS TX_KBPS
# Uses /proc/net/dev. Device auto-detected: prefers wlan0 then eth0 then first non-lo device.

# find iface
iface=$(ip -o link show | awk -F': ' '$2!="lo" {print $2}' | head -n1)
if [[ -z "$iface" ]]; then
  echo "0 0"
  exit 0
fi

state_file="/tmp/eww_net_${iface}.state"

read_stats() {
  awk -v dev="$iface" '$0 ~ dev":" {print $2, $10}' /proc/net/dev
}

read -r rx1 tx1 < <(read_stats)
now=$(date +%s)

if [[ -f "$state_file" ]]; then
  read -r rx0 tx0 t0 < "$state_file"
  dt=$((now - t0))
  if [[ $dt -gt 0 ]]; then
    rx_kbps=$(( ( (rx1 - rx0) / 1024 ) / dt ))
    tx_kbps=$(( ( (tx1 - tx0) / 1024 ) / dt ))
    echo "$rx_kbps $tx_kbps"
  else
    echo "0 0"
  fi
else
  echo "0 0"
fi

# save current
printf "%s %s %s" "$rx1" "$tx1" "$now" > "$state_file"
