#!/usr/bin/env bash
# rf_color_focused.sh <#rrggbb|"">
# Reads scan_focused_key from eww state at runtime (same pattern as
# rf_nick_focused.sh), then writes to device_colors data file.
COLOR="$1"
KEY=$(WAYLAND_DISPLAY=wayland-1 eww get scan_focused_key 2>/dev/null)
[[ -z "$KEY" ]] && exit 0
exec ~/.config/eww/scripts/rf_color.sh "$KEY" "$COLOR"
