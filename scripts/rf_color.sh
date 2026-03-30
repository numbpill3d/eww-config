#!/usr/bin/env bash
# rf_color.sh KEY COLOR
# Assigns a radar blip color to a device key.
# COLOR empty = remove assignment (reverts to default radar red).
# Stored in ~/.config/eww/data/device_colors  (one "KEY COLOR" per line)
KEY="$1"
COLOR="$2"
FILE="$HOME/.config/eww/data/device_colors"
mkdir -p "$(dirname "$FILE")"
touch "$FILE"
python3 - "$KEY" "$COLOR" "$FILE" <<'EOF'
import sys
key, color, path = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    lines = open(path).readlines()
except FileNotFoundError:
    lines = []
lines = [l for l in lines if not l.startswith(key + ' ') and l.strip() != key]
if color:
    lines.append(key + ' ' + color + '\n')
open(path, 'w').writelines(lines)
EOF
