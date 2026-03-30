#!/usr/bin/env bash
# rf_nick_focused.sh <nickname>
# Reads the currently focused device key from eww state at runtime,
# then delegates to rf_nick.sh.  This avoids the render-time interpolation
# bug where scan_focused_key was baked into onaccept when the input widget
# was first drawn rather than at the moment the user pressed Enter.

NICK="$1"
KEY=$(WAYLAND_DISPLAY=wayland-1 eww get scan_focused_key 2>/dev/null)
[[ -z "$KEY" ]] && exit 0
exec ~/.config/eww/scripts/rf_nick.sh "$KEY" "$NICK"
