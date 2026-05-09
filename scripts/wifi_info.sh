#!/usr/bin/env bash
# wifi_info.sh — current connection: signal, tx/rx rate, frequency
# compact single-line output for eww sidebar

iface=$(iw dev 2>/dev/null | awk '/Interface/{print $2; exit}')
[[ -z "$iface" ]] && echo "no iface" && exit

link=$(iw dev "$iface" link 2>/dev/null)
[[ -z "$link" || "$link" == "Not connected." ]] && echo "disconnected" && exit

signal=$(awk '/signal:/{print $2}' <<< "$link")
txrate=$(awk '/tx bitrate:/{printf "%s %s",$3,$4; exit}' <<< "$link")
freq=$(awk   '/freq:/{print $2; exit}' <<< "$link")
[[ -n "$freq" ]] && band=$(awk -v f="$freq" 'BEGIN{print (f+0>=5000?"5G":"2.4G")}')

printf "%sdBm tx:%s %s\n" \
    "${signal:--?}" \
    "${txrate:-?}" \
    "${band:-?}"
