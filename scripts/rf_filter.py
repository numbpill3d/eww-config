#!/usr/bin/env python3
"""rf_filter.py PROTO — filter /tmp/eww_rf_devices.json by proto,
merging colorclass from ~/.config/eww/data/device_colors."""
import json, sys, os

proto = sys.argv[1] if len(sys.argv) > 1 else 'arp'

colors = {}
try:
    path = os.path.expanduser('~/.config/eww/data/device_colors')
    for line in open(path):
        parts = line.strip().split(None, 1)
        if len(parts) == 2:
            colors[parts[0]] = parts[1]
except Exception:
    pass

devices = json.load(open('/tmp/eww_rf_devices.json'))
out = []
for d in devices:
    if d.get('proto') == proto:
        d['colorclass'] = colors.get(d.get('key', ''), '')
        out.append(d)

print(json.dumps(out))
