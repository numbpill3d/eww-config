#!/usr/bin/env bash
# wifi_quality_log.sh — log wifi signal/latency every 5m via cron
# cron: */5 * * * * ~/.config/eww/scripts/wifi_quality_log.sh

LOG="$HOME/.local/share/wifi-quality.csv"
mkdir -p "$(dirname "$LOG")"

if [[ ! -f "$LOG" ]]; then
    echo "timestamp,signal_dbm,link_quality,tx_rate_mbps,power_save,ping_gw_ms,freq_ghz" > "$LOG"
fi

iface=$(iw dev 2>/dev/null | awk '/Interface/{print $2; exit}')
[[ -z "$iface" ]] && exit 0

link=$(iw dev "$iface" link 2>/dev/null)
[[ -z "$link" || "$link" == "Not connected." ]] && exit 0

signal=$(awk '/signal:/{print $2}' <<< "$link")
txrate=$(awk '/tx bitrate:/{print $3; exit}' <<< "$link")
freq=$(awk '/freq:/{printf "%.3f", $2/1000; exit}' <<< "$link")
lq=$(iwconfig "$iface" 2>/dev/null | awk -F'[=/]' '/Link Quality/{print $2}')
ps=$(iw dev "$iface" get power_save 2>/dev/null | awk '{print $NF}')

gw=$(ip route show default 2>/dev/null | awk '/default/{print $3; exit}')
if [[ -n "$gw" ]]; then
    ping_ms=$(ping -c 1 -W 2 "$gw" 2>/dev/null | awk -F'/' '/^rtt/{printf "%d", $5}')
else
    ping_ms=""
fi

echo "$(date -Iseconds),${signal:-?},${lq:-?},${txrate:-?},${ps:-?},${ping_ms:-?},${freq:-?}" >> "$LOG"
