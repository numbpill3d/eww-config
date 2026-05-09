#!/usr/bin/env bash
# sensors.sh — ThinkPad: CPU temp, fan speed, load avg
# fallback to /sys/class/thermal if lm-sensors absent

cpu_temp=""
fan_rpm=""

if command -v sensors &>/dev/null; then
    # ThinkPad adapter labeled "thinkpad-isa-*"
    read cpu_temp fan_rpm < <(sensors 2>/dev/null | awk '
        /thinkpad/ { in_tp = 1 }
        in_tp && /^CPU:/ {
            match($0, /\+([0-9.]+)/, a)
            cpu = int(a[1]+0)
        }
        in_tp && /^fan1:/ { fan = $2 }
        END { print cpu+0, fan+0 }
    ')
fi

# fallback thermal
if [[ -z "$cpu_temp" || "$cpu_temp" == "0" ]]; then
    for f in /sys/class/thermal/thermal_zone*/temp; do
        [[ -r "$f" ]] || continue
        v=$(< "$f")
        (( v > 20000 && v < 110000 )) && { cpu_temp=$(( v / 1000 )); break; }
    done
fi

load=$(awk '{printf "%.1f",$1}' /proc/loadavg)

out=""
[[ -n "$cpu_temp" && "$cpu_temp" != "0" ]] && out="${cpu_temp}°"
[[ -n "$fan_rpm"  && "$fan_rpm"  != "0" ]] && out="${out:+$out }f:${fan_rpm}"
printf "%s ld:%s\n" "${out:-tmp:?}" "$load"
