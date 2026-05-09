#!/usr/bin/env python3
"""wifi_scan.py — nmcli wifi list → JSON array for eww defpoll"""
import subprocess, json, re, os

def sig_bars(s):
    if s >= 80: return '\u2593\u2593\u2593\u2593'
    if s >= 60: return '\u2593\u2593\u2593\u2591'
    if s >= 40: return '\u2593\u2593\u2591\u2591'
    if s >= 20: return '\u2593\u2591\u2591\u2591'
    return '\u2591\u2591\u2591\u2591'

def dist_s(sig):
    if sig >= 80: return '<5m'
    if sig >= 60: return '~15m'
    if sig >= 40: return '~50m'
    if sig >= 20: return '>100m'
    return 'far'

subprocess.Popen(
    ['nmcli', 'device', 'wifi', 'rescan'],
    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
)

r = subprocess.run(
    ['nmcli', '-g', 'SSID,BSSID,SIGNAL,SECURITY,CHAN', 'device', 'wifi', 'list'],
    capture_output=True, text=True
)

devices = []
seen = set()
for raw in r.stdout.splitlines():
    parts = re.split(r'(?<!\\):', raw)
    if len(parts) < 5:
        continue
    ssid  = parts[0].replace('\\:', ':').strip() or '[hidden]'
    bssid = parts[1].replace('\\:', ':').strip()
    try:    sig = int(parts[2].strip())
    except: sig = 0
    sec  = parts[3].strip()
    chan = parts[4].strip()

    if bssid in seen:
        continue
    seen.add(bssid)

    sec_s = sec.split()[0][:6] if sec and sec.upper() != 'OPEN' else 'OPEN'
    level = 4 if sig >= 80 else 3 if sig >= 60 else 2 if sig >= 40 else 1 if sig >= 20 else 0

    try:
        band = '5G' if int(chan) >= 36 else '2.4G'
    except ValueError:
        band = '?'

    dbm = sig // 2 - 100

    devices.append({
        'ssid':     ssid,
        'bssid':    bssid,
        'signal':   sig,
        'security': sec_s,
        'chan':      chan,
        'bars':     sig_bars(sig),
        'level':    str(level),
        'band':     band,
        'dbm':      str(dbm),
        'dist_s':   dist_s(sig),
    })

devices.sort(key=lambda x: -x['signal'])
print(json.dumps(devices))

# log every scan to wardrive DB (non-blocking)
try:
    import subprocess as _sp
    _db = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'wardrive_db.py')
    _proc = _sp.Popen(
        ['python3', _db],
        stdin=_sp.PIPE, stdout=_sp.DEVNULL, stderr=_sp.DEVNULL
    )
    _proc.stdin.write(json.dumps(devices).encode())
    _proc.stdin.close()
except Exception:
    pass
