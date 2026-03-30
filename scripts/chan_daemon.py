#!/usr/bin/env python3
"""chan_daemon.py — reads wifi scan JSON every 15s, writes channel congestion bars.
output file: /tmp/eww_chan_bars  (plain text, multiline, polled by eww)
started by autostart.sh"""
import json, time

SCAN_FILE = "/tmp/eww_wifi_scan.json"
OUT_FILE  = "/tmp/eww_chan_bars"
INTERVAL  = 15
BAR_WIDTH = 8


def bar(n: int, maxn: int) -> str:
    filled = round(n / max(maxn, 1) * BAR_WIDTH)
    filled = min(filled, BAR_WIDTH)
    return "█" * filled + "·" * (BAR_WIDTH - filled)


def render(devices: list) -> str:
    if not devices:
        return "no scan data"

    chans_24: dict[int, int] = {}
    chans_5:  dict[int, int] = {}

    for d in devices:
        try:
            ch = int(d.get("chan", 0))
        except (ValueError, TypeError):
            continue
        band = d.get("band", "?")
        target = chans_5 if band == "5G" else chans_24
        target[ch] = target.get(ch, 0) + 1

    lines: list[str] = []

    if chans_24:
        maxn = max(chans_24.values())
        lines.append("2.4G")
        for ch in sorted(chans_24):
            n = chans_24[ch]
            lines.append(f"  ch{ch:<3} [{bar(n, maxn)}] {n}")

    if chans_5:
        lines.append("5G")
        maxn = max(chans_5.values())
        for ch in sorted(chans_5):
            n = chans_5[ch]
            lines.append(f"  ch{ch:<3} [{bar(n, maxn)}] {n}")

    return "\n".join(lines)


while True:
    try:
        with open(SCAN_FILE) as f:
            devices = json.load(f)
        text = render(devices)
    except Exception:
        text = "awaiting scan"
    try:
        with open(OUT_FILE, "w") as f:
            f.write(text)
    except Exception:
        pass
    time.sleep(INTERVAL)
