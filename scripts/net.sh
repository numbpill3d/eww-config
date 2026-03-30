#!/usr/bin/env bash
IFACE=$(ip route get 1 2>/dev/null | awk '{print $5; exit}')
[[ -z "$IFACE" ]] && echo "0" && exit

R1=$(cat /sys/class/net/$IFACE/statistics/${1:-down}_bytes 2>/dev/null || echo 0)
sleep 1
R2=$(cat /sys/class/net/$IFACE/statistics/${1:-down}_bytes 2>/dev/null || echo 0)
DIFF=$(( (R2 - R1) / 1024 ))
echo "${DIFF}K/s"
