#!/usr/bin/env python3
"""wardrive_map.py — render wardrive DB as ASCII map, list, or stats

Usage:
  wardrive_map.py map    — ASCII scatter plot (eww defpoll, 5s)
  wardrive_map.py list   — network table sorted by last_seen (30s)
  wardrive_map.py stats  — counts + channel breakdown (60s)
"""
import sys, os, hashlib
from datetime import datetime, timezone

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from wardrive_db import get_conn, init_db, get_all_networks

W, H = 68, 26   # canvas dimensions (chars)

# ---- Scatter map ------------------------------------------------------

def bssid_pos(bssid):
    h = hashlib.md5(bssid.encode()).hexdigest()
    x = int(h[0:4], 16) % (W - 2) + 1
    y = int(h[4:8], 16) % (H - 2) + 1
    return x, y

_PRIORITY = {'!': 5, '*': 4, '@': 3, '#': 2, '+': 2, 'o': 1, '.': 0}

def ap_symbol(status, signal, is_new_today):
    if status == 'flagged':  return '!'
    if status == 'watched':  return '*'
    if is_new_today:         return '@'
    if status == 'known':    return '#' if signal >= 60 else 'o'
    return '+' if signal >= 60 else '.'

def render_map(networks):
    today = datetime.now(timezone.utc).strftime('%Y-%m-%d')
    canvas = [[' '] * W for _ in range(H)]
    for x in range(W):
        canvas[0][x] = canvas[H-1][x] = '-'
    for y in range(H):
        canvas[y][0] = canvas[y][W-1] = '|'
    for corner in [(0,0),(0,W-1),(H-1,0),(H-1,W-1)]:
        canvas[corner[0]][corner[1]] = '+'

    placed = 0
    status_counts = {'known':0,'watched':0,'flagged':0,'unknown':0,'today':0}
    for net in networks:
        bssid  = net['bssid']
        status = net['status'] or 'unknown'
        signal = net['last_signal'] or 0
        is_today = (net['first_seen'] or '')[:10] == today
        sym = ap_symbol(status, signal, is_today)
        x, y = bssid_pos(bssid)
        cur = canvas[y][x]
        if cur == ' ' or _PRIORITY.get(sym, 0) > _PRIORITY.get(cur, 0):
            canvas[y][x] = sym
        placed += 1
        if is_today:                       status_counts['today'] += 1
        if status in status_counts:        status_counts[status] += 1

    lines = [''.join(row) for row in canvas]
    legend = (
        f" #=known  o=kn-wk  +=unk  .=unk-wk  *=watch  @=new-today  !=flag"
        f"  [{placed}]"
    )
    lines.append(legend[:W+2])
    return '\n'.join(lines)

# ---- List view --------------------------------------------------------

def render_list(networks):
    if not networks:
        return "[ no networks in db — run a wifi scan ]"
    hdr = f"{'STATUS':<8} {'SSID':<18} {'BSSID':<17} {'CH':>3} {'SIG':>4} {'SEEN':>4} {'LAST':<10}"
    sep = '-' * len(hdr)
    lines = [hdr, sep]
    for net in networks[:120]:
        status = (net['status'] or 'unknown')[:7]
        label  = (net['nick'] or net['ssid'] or '[hidden]')[:18]
        bssid  = net['bssid'] or ''
        ch     = str(net['channel'] or '?')
        sig    = str(net['last_signal'] or '?') + '%'
        seen   = str(net['times_seen'] or 1)
        last   = (net['last_seen'] or '')[:10]
        lines.append(
            f"{status:<8} {label:<18} {bssid:<17} {ch:>3} {sig:>4} {seen:>4} {last:<10}"
        )
    if len(networks) > 120:
        lines.append(f"  ... {len(networks)-120} more")
    return '\n'.join(lines)

# ---- Stats view -------------------------------------------------------

def render_stats(networks):
    if not networks:
        return "[ no data ]"
    today   = datetime.now(timezone.utc).strftime('%Y-%m-%d')
    total   = len(networks)
    known   = sum(1 for n in networks if n['status'] == 'known')
    watched = sum(1 for n in networks if n['status'] == 'watched')
    flagged = sum(1 for n in networks if n['status'] == 'flagged')
    unknown = sum(1 for n in networks if n['status'] == 'unknown')
    new_today = sum(1 for n in networks if (n['first_seen'] or '')[:10] == today)
    open_net  = sum(1 for n in networks if (n['security'] or '').upper() == 'OPEN')
    wpa3      = sum(1 for n in networks if 'WPA3' in (n['security'] or '').upper())

    ch_count = {}
    for n in networks:
        ch = n['channel'] or 0
        ch_count[ch] = ch_count.get(ch, 0) + 1
    top_ch = sorted(ch_count.items(), key=lambda x: -x[1])[:12]
    max_cnt = max(c for _, c in top_ch) if top_ch else 1

    lines = [
        "[ WARDRIVE DB ]",
        f"  total    {total}",
        f"  known    {known}",
        f"  watched  {watched}",
        f"  flagged  {flagged}",
        f"  unknown  {unknown}",
        f"  new today {new_today}",
        f"  open     {open_net}",
        f"  wpa3     {wpa3}",
        "",
        "[ CHANNEL CONGESTION ]",
    ]
    for ch, cnt in top_ch:
        band = '5G  ' if (ch or 0) >= 36 else '2.4G'
        bar_len = int(cnt / max_cnt * 28)
        bar = '█' * bar_len + '░' * (28 - bar_len)
        lines.append(f"  ch{str(ch):<4} {band}  {bar}  {cnt}")

    # top 5 SSIDs by sighting count
    top_ssid = sorted(networks, key=lambda n: -(n['times_seen'] or 0))[:5]
    lines += ["", "[ MOST SEEN ]"]
    for n in top_ssid:
        label = (n['nick'] or n['ssid'] or '[hidden]')[:24]
        lines.append(f"  {label:<24}  {n['times_seen']}x  {(n['last_seen'] or '')[:10]}")

    return '\n'.join(lines)

# ---- Main -------------------------------------------------------------

if __name__ == '__main__':
    mode = sys.argv[1] if len(sys.argv) > 1 else 'map'
    try:
        conn = get_conn()
        init_db(conn)
        nets = get_all_networks(conn)
        conn.close()
    except Exception as e:
        print(f"db error: {e}")
        sys.exit(1)

    if mode == 'list':
        print(render_list(nets))
    elif mode == 'stats':
        print(render_stats(nets))
    else:
        print(render_map(nets))
