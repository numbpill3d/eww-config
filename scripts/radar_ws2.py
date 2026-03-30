#!/usr/bin/env python3
"""
radar_ws2.py — Halo-3 style motion tracker for workspace 2.

Output: plain text. All device blips are X.
Colors are tracked in ~/.config/eww/data/device_colors and shown in
the scan panel as colored ■ dots — per-char color isn't possible in
eww text labels.

Proximity derived from real data:
  WiFi APs   : RSSI dBm  (-30 = center,  -90 = outer ring)
  ARP nodes  : kernel state  (reachable=close, stale=far)
  BT devices : pairing state (connected=close, paired=mid)

Grid: 51×25 chars. Sweep: 72°/s (5 s/rotation), 500ms poll = 36°/frame.
"""
import time, math, json

W, H   = 51, 25
cx, cy = W // 2, H // 2
R      = cx - 2
AX     = (cy - 1) / R

GLYPHS = {
    'rtr': 'R', 'phn': 'P', 'lap': 'L',
    'iot': 'I', 'tv':  'V', 'spk': 'A',
    'kbd': 'K', 'unk': '?',
}

STATE_SHORT = {
    'reachable': 'up', 'delay': 'up', 'probe': 'up',
    'stale': 'st', 'connected': 'cn', 'paired': 'pr',
}

RING  = '\u00b7'   # · middle dot
CH_H  = '\u2500'   # ─
CH_V  = '\u2502'   # │
CH_X  = '\u254b'   # ╋


# ── helpers ───────────────────────────────────────────────────────────────────

def stable_angle(key):
    h = 5381
    for c in key:
        h = ((h << 5) + h + ord(c)) & 0xFFFFFFFF
    return (h % 3600) / 1800.0 * math.pi


def rssi_dist(dbm):
    v = max(-90, min(-30, int(dbm)))
    return 0.15 + ((-v - 30) / 60.0) * 0.77


def state_dist(state):
    return {
        'reachable': 0.20, 'delay': 0.28,  'probe':     0.36,
        'stale':     0.68, 'connected': 0.18, 'paired': 0.44,
    }.get(str(state).lower(), 0.55)


def clamp(v, lo, hi):
    return max(lo, min(hi, v))




# ── data sources ─────────────────────────────────────────────────────────────

def get_sources():
    devs = []

    try:
        aps = json.loads(open('/tmp/eww_wifi_scan.json').read())
        for ap in aps[:14]:
            dbm = int(ap.get('dbm', -70))
            key = ap.get('bssid', '')
            devs.append({
                'label': (ap.get('ssid') or '?')[:9],
                'dist':  rssi_dist(dbm),
                'angle': stable_angle(key),
                'state': 'up',
            })
    except Exception:
        pass

    try:
        nodes = json.loads(open('/tmp/eww_rf_devices.json').read())
        for nd in nodes[:14]:
            key = nd.get('key', nd.get('addr', ''))
            st  = STATE_SHORT.get(nd.get('state', 'stale'), '??')
            devs.append({
                'label': nd.get('display', '?')[:9],
                'dist':  state_dist(nd.get('state', 'stale')),
                'angle': stable_angle(key),
                'state': st,
            })
    except Exception:
        pass

    return devs


# ── frame renderer ────────────────────────────────────────────────────────────

def make_frame():
    grid = [[' '] * W for _ in range(H)]

    # Three concentric rings
    for frac, step in [(1.0, 1), (0.62, 2), (0.32, 3)]:
        for deg in range(0, 360, step):
            rad = deg * math.pi / 180
            x = round(cx + R * frac * math.cos(rad))
            y = round(cy + R * frac * math.sin(rad) * AX)
            if 0 <= x < W and 0 <= y < H and grid[y][x] == ' ':
                grid[y][x] = RING

    # Crosshairs
    for i in range(W):
        if grid[cy][i] in (' ', RING):
            grid[cy][i] = CH_H
    for i in range(H):
        if grid[i][cx] in (' ', RING):
            grid[i][cx] = CH_V
    grid[cy][cx] = CH_X

    # Cardinal markers
    n_y = clamp(round(cy - R * AX), 0, H - 1)
    s_y = clamp(round(cy + R * AX), 0, H - 1)
    e_x = clamp(round(cx + R),      0, W - 1)
    w_x = clamp(round(cx - R),      0, W - 1)
    grid[n_y][cx] = 'N'
    grid[s_y][cx] = 'S'
    grid[cy][e_x] = 'E'
    grid[cy][w_x] = 'W'

    # Rotating sweep — block chars, 72°/s
    sweep_deg = (time.time() * 72) % 360
    for trail in range(40):
        td = (sweep_deg - trail) % 360
        tr = td * math.pi / 180
        if   trail == 0:  ch = '\u2588'   # █
        elif trail < 9:   ch = '\u2593'   # ▓
        elif trail < 22:  ch = '\u2592'   # ▒
        elif trail < 38:  ch = '\u2591'   # ░
        else: break
        for step in range(1, R + 1):
            x = round(cx + step * math.cos(tr))
            y = round(cy + step * math.sin(tr) * AX)
            if 0 <= x < W and 0 <= y < H:
                if grid[y][x] in (' ', CH_H, CH_V, RING):
                    grid[y][x] = ch

    # Device blips — all X
    devs = get_sources()
    placed = set()
    legend = []

    for dev in devs[:22]:
        a, d = dev['angle'], dev['dist']
        x = clamp(round(cx + R * d * math.cos(a)), 1, W - 2)
        y = clamp(round(cy + R * d * math.sin(a) * AX), 1, H - 2)
        for _ in range(10):
            if (x, y) not in placed:
                break
            d = min(d + 0.06, 0.94)
            x = clamp(round(cx + R * d * math.cos(a)), 1, W - 2)
            y = clamp(round(cy + R * d * math.sin(a) * AX), 1, H - 2)
        placed.add((x, y))
        grid[y][x] = 'X'
        legend.append(f"X:{dev['label']}[{dev['state']}]")

    rows = [''.join(row) for row in grid]

    total = len(devs)
    ts    = time.strftime('%H:%M:%S')
    pad   = W - len(ts) - 3
    header = f"RADAR {'─' * max(1, pad - 15)} {total:>2}ct  {ts}"

    leg_lines = []
    for i in range(0, min(len(legend), 12), 2):
        pair = legend[i:i+2]
        leg_lines.append('  '.join(f"{s:<24}" for s in pair))

    parts = [header, '\n'.join(rows)]
    if leg_lines:
        parts.append('\n'.join(leg_lines))
    return '\n'.join(parts)


if __name__ == '__main__':
    print(make_frame())
