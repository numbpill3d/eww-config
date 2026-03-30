#!/usr/bin/env bash
BAT=$(ls /sys/class/power_supply/ | grep -i bat | head -1)
[[ -z "$BAT" ]] && echo "AC" && exit
if [[ "$1" == "pct" ]]; then
  cat /sys/class/power_supply/$BAT/capacity 2>/dev/null || echo "?"
elif [[ "$1" == "status" ]]; then
  STATUS=$(cat /sys/class/power_supply/$BAT/status 2>/dev/null)
  case "$STATUS" in
    Charging)    echo "CHR" ;;
    Discharging) echo "DIS" ;;
    Full)        echo "FUL" ;;
    *)           echo "$STATUS" ;;
  esac
fi
