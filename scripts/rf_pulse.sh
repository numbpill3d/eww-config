#!/usr/bin/env bash
# rf_pulse.sh — spinning scan indicator, called every 500ms by eww defpoll
# cycles |/-\ to give a live "scanning" feel in the RF header
STATE=/tmp/eww_rf_pulse
n=$(cat "$STATE" 2>/dev/null || echo "0")
n=$(( (n + 1) % 4 ))
printf '%d\n' "$n" > "$STATE"
case $n in
  0) echo "|"  ;;
  1) echo "/"  ;;
  2) echo "-"  ;;
  3) echo "\\" ;;
esac
