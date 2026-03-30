#!/usr/bin/env python3
"""
Halo-3 style ASCII motion tracker.
Reads /proc/net/arp, places each device at a stable MAC-derived position.
Sweep line rotates based on wall-clock time — poll at 1s for animation.
"""
import time, math, json

# Grid dimensions (chars). Aspect ~0.45 squish for monospace.
W, H   = 25, 11
cx, cy = W // 2, H // 2
r      = min(cx, cy) - 1
ASPECT = 0.48


def get_devices():
    devs = []
    try:
        for line in open('/proc/net/arp'):
            p = line.split()
            if len(p) < 6 or ':' not in p[3]:
                continue
            if p[3] in ('HWaddress', '00:00:00:00:00:00'):
                continue
            devs.append({'ip': p[0], 'mac': p[3]})
    except Exception:
        pass
    return devs


def mac_to_polar(mac):
    try:
        h = int(mac.replace(':', ''), 16)
    except Exception:
        h = hash(mac) & 0xFFFFFFFF
    angle = (h % 360) * math.pi / 180
    dist  = 0.30 + ((h >> 12) % 8) * 0.09   # 0.30 – 0.93
    return angle, dist


def clamp(v, lo, hi):
    return max(lo, min(hi, v))


def make_frame():
    grid = [[' '] * W for _ in range(H)]

    # Outer ring
    for deg in range(360):
        rad = deg * math.pi / 180
        x = round(cx + r * math.cos(rad))
        y = round(cy + r * math.sin(rad) * ASPECT)
        if 0 <= x < W and 0 <= y < H:
            grid[y][x] = '·'

    # Inner ring (half radius, dashed)
    for deg in range(0, 360, 3):
        rad = deg * math.pi / 180
        x = round(cx + r * 0.5 * math.cos(rad))
        y = round(cy + r * 0.5 * math.sin(rad) * ASPECT)
        if 0 <= x < W and 0 <= y < H:
            grid[y][x] = '·'

    # Cross-hairs
    for i in range(W):
        if grid[cy][i] == ' ':
            grid[cy][i] = '-'
    for i in range(H):
        if grid[i][cx] == ' ':
            grid[i][cx] = '|'
    grid[cy][cx] = '+'

    # Sweep line — full rotation every 6 seconds
    sweep_deg = (time.time() * 60) % 360
    sweep_rad = sweep_deg * math.pi / 180
    sd = sweep_deg
    sweep_char = '/' if (45 <= sd < 135) or (225 <= sd < 315) else '\\'
    if sd < 22 or sd >= 338 or (158 <= sd < 202):
        sweep_char = '|'
    elif (67 <= sd < 113) or (247 <= sd < 293):
        sweep_char = '-'

    for step in range(1, r + 1):
        x = round(cx + step * math.cos(sweep_rad))
        y = round(cy + step * math.sin(sweep_rad) * ASPECT)
        if 0 <= x < W and 0 <= y < H and grid[y][x] in (' ', '-', '|'):
            grid[y][x] = sweep_char

    # Device blips
    devs = get_devices()
    legend = []
    for i, dev in enumerate(devs[:9]):
        mark = str(i + 1)
        angle, dist = mac_to_polar(dev['mac'])
        x = clamp(round(cx + r * dist * math.cos(angle)), 0, W - 1)
        y = clamp(round(cy + r * dist * math.sin(angle) * ASPECT), 0, H - 1)
        grid[y][x] = mark
        short_ip = dev['ip'].rsplit('.', 1)[-1]   # last octet only saves space
        legend.append(f"{mark}:.{short_ip}")

    rows = [''.join(row) for row in grid]
    header = f"  MOTION TRACKER  {len(devs):>2} contact{'s' if len(devs) != 1 else ' '}"
    body = '\n'.join(rows)

    # Legend — 3 per line
    legend_lines = []
    for j in range(0, len(legend), 3):
        legend_lines.append('  '.join(legend[j:j+3]))

    return header + '\n' + body + ('\n' + '\n'.join(legend_lines) if legend_lines else '')


print(make_frame())
