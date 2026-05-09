#!/usr/bin/env python3
"""wardrive_db.py — persistent wifi AP database

Modes (sys.argv[1]):
  (none/stdin)            read JSON array from stdin, upsert all APs, write stats
  setstatus <bssid> <s>   set status: unknown|known|watched|flagged
  setnick   <bssid> <n>   set display nick ("-" clears)
  setnotes  <bssid> <n>   set notes field
  focus     <bssid>       write full detail to /tmp/eww_wardrive_focus
"""
import sqlite3, json, sys, os, hashlib
from datetime import datetime, timezone

DB_PATH    = os.path.expanduser("~/.config/eww/data/wardrive.db")
STATS_FILE = "/tmp/eww_wardrive_stats"
FOCUS_FILE = "/tmp/eww_wardrive_focus"
OUI_DB     = "/usr/share/nmap/nmap-mac-prefixes"

# ---- OUI lookup -------------------------------------------------------

_oui_cache = {}

def get_vendor(mac):
    oui = mac.replace(':', '')[:6].upper()
    if oui in _oui_cache:
        return _oui_cache[oui]
    vendor = mac[:8]
    if os.path.exists(OUI_DB):
        try:
            with open(OUI_DB) as f:
                for line in f:
                    parts = line.strip().split(None, 1)
                    if len(parts) == 2 and parts[0].upper() == oui:
                        vendor = parts[1][:24]
                        break
        except Exception:
            pass
    _oui_cache[oui] = vendor
    return vendor

# ---- DB setup ---------------------------------------------------------

def get_conn():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH, timeout=5)
    conn.row_factory = sqlite3.Row
    return conn

def init_db(conn):
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS networks (
            bssid       TEXT PRIMARY KEY,
            ssid        TEXT NOT NULL DEFAULT '',
            security    TEXT DEFAULT 'OPEN',
            channel     INTEGER DEFAULT 0,
            band        TEXT DEFAULT '?',
            vendor      TEXT DEFAULT '',
            nick        TEXT DEFAULT '',
            color       TEXT DEFAULT '',
            status      TEXT DEFAULT 'unknown',
            first_seen  TEXT NOT NULL,
            last_seen   TEXT NOT NULL,
            times_seen  INTEGER DEFAULT 1,
            last_signal INTEGER DEFAULT 0,
            max_signal  INTEGER DEFAULT 0,
            notes       TEXT DEFAULT ''
        );
        CREATE TABLE IF NOT EXISTS sightings (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            bssid       TEXT NOT NULL,
            ssid        TEXT,
            signal      INTEGER,
            channel     INTEGER,
            ts          TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_sightings_bssid ON sightings(bssid);
        CREATE INDEX IF NOT EXISTS idx_networks_status ON networks(status);
        CREATE INDEX IF NOT EXISTS idx_networks_last ON networks(last_seen);
    """)
    conn.commit()

# ---- Write helpers ----------------------------------------------------

def upsert_network(conn, ap, now):
    bssid = (ap.get('bssid') or '').strip()
    if not bssid or bssid == 'ff:ff:ff:ff:ff:ff':
        return
    ssid     = (ap.get('ssid') or '').strip()
    security = (ap.get('security') or 'OPEN').strip()
    channel  = int(ap.get('chan') or ap.get('channel') or 0)
    band     = (ap.get('band') or '?').strip()
    signal   = int(ap.get('signal') or 0)
    vendor   = get_vendor(bssid)

    existing = conn.execute(
        "SELECT times_seen, max_signal FROM networks WHERE bssid=?", (bssid,)
    ).fetchone()

    if existing:
        new_max = max(existing['max_signal'] or 0, signal)
        conn.execute(
            "UPDATE networks SET ssid=?,security=?,channel=?,band=?,vendor=?,"
            "last_seen=?,times_seen=times_seen+1,last_signal=?,max_signal=? WHERE bssid=?",
            (ssid, security, channel, band, vendor, now, signal, new_max, bssid)
        )
    else:
        conn.execute(
            "INSERT INTO networks(bssid,ssid,security,channel,band,vendor,"
            "first_seen,last_seen,last_signal,max_signal) VALUES(?,?,?,?,?,?,?,?,?,?)",
            (bssid, ssid, security, channel, band, vendor, now, now, signal, signal)
        )

    conn.execute(
        "INSERT INTO sightings(bssid,ssid,signal,channel,ts) VALUES(?,?,?,?,?)",
        (bssid, ssid, signal, channel, now)
    )

def write_stats(conn):
    total   = conn.execute("SELECT COUNT(*) FROM networks").fetchone()[0]
    known   = conn.execute("SELECT COUNT(*) FROM networks WHERE status='known'").fetchone()[0]
    watched = conn.execute("SELECT COUNT(*) FROM networks WHERE status='watched'").fetchone()[0]
    flagged = conn.execute("SELECT COUNT(*) FROM networks WHERE status='flagged'").fetchone()[0]
    today   = datetime.now(timezone.utc).strftime('%Y-%m-%d')
    new_today = conn.execute(
        "SELECT COUNT(*) FROM networks WHERE first_seen>=?", (today,)
    ).fetchone()[0]
    try:
        with open(STATS_FILE, 'w') as f:
            f.write(f"db:{total}  kn:{known}  wt:{watched}  !:{flagged}  new:{new_today}")
    except Exception:
        pass

# ---- Read helpers (used by wardrive_map.py) ---------------------------

def get_all_networks(conn):
    return conn.execute(
        "SELECT bssid,ssid,security,channel,band,vendor,nick,color,status,"
        "first_seen,last_seen,times_seen,last_signal,max_signal,notes "
        "FROM networks ORDER BY last_seen DESC"
    ).fetchall()

def get_signal_history(conn, bssid, limit=16):
    rows = conn.execute(
        "SELECT signal FROM sightings WHERE bssid=? ORDER BY id DESC LIMIT ?",
        (bssid, limit)
    ).fetchall()
    return [r['signal'] for r in reversed(rows)]

def set_status(conn, bssid, status):
    valid = ('unknown', 'known', 'watched', 'flagged')
    if status not in valid:
        return
    conn.execute("UPDATE networks SET status=? WHERE bssid=?", (status, bssid))
    conn.commit()

def set_nick(conn, bssid, nick):
    conn.execute("UPDATE networks SET nick=? WHERE bssid=?",
                 ('' if nick == '-' else nick, bssid))
    conn.commit()

def set_notes(conn, bssid, notes):
    conn.execute("UPDATE networks SET notes=? WHERE bssid=?", (notes, bssid))
    conn.commit()

# ---- Signal sparkline -------------------------------------------------

_SPARK = ' ▁▂▃▄▅▆▇█'

def spark(values):
    if not values:
        return ''
    lo, hi = min(values), max(values)
    span = hi - lo or 1
    out = []
    for v in values:
        idx = int((v - lo) / span * (len(_SPARK) - 1))
        out.append(_SPARK[idx])
    return ''.join(out)

# ---- Focus detail for wardrive panel ----------------------------------

def write_focus(conn, bssid):
    net = conn.execute(
        "SELECT * FROM networks WHERE bssid=?", (bssid,)
    ).fetchone()
    lines = []
    if not net:
        lines.append(f"[ {bssid} ]")
        lines.append("not in db yet — run a wifi scan first")
    else:
        label = net['nick'] or net['ssid'] or '[hidden]'
        lines.append(f"[ {label} ]")
        lines.append(f"bssid    {net['bssid']}")
        lines.append(f"ssid     {net['ssid'] or '[hidden]'}")
        lines.append(f"status   {net['status']}")
        lines.append(f"security {net['security']}")
        lines.append(f"channel  ch{net['channel']}  {net['band']}")
        lines.append(f"vendor   {net['vendor']}")
        lines.append(f"signal   {net['last_signal']}%  max:{net['max_signal']}%")
        lines.append(f"seen     {net['times_seen']}x")
        lines.append(f"first    {(net['first_seen'] or '')[:16]}")
        lines.append(f"last     {(net['last_seen'] or '')[:16]}")
        hist = get_signal_history(conn, bssid, 16)
        if hist:
            lines.append(f"history  {spark(hist)}  ({hist[-1]}%)")
        if net['notes']:
            lines.append(f"notes    {net['notes']}")
    try:
        with open(FOCUS_FILE, 'w') as f:
            f.write('\n'.join(lines))
    except Exception:
        pass

# ---- Main -------------------------------------------------------------

if __name__ == '__main__':
    mode = sys.argv[1] if len(sys.argv) > 1 else ''

    if mode == 'setstatus':
        bssid, status = sys.argv[2], sys.argv[3]
        conn = get_conn(); init_db(conn)
        set_status(conn, bssid, status)
        conn.close()

    elif mode == 'setnick':
        bssid, nick = sys.argv[2], sys.argv[3]
        conn = get_conn(); init_db(conn)
        set_nick(conn, bssid, nick)
        conn.close()

    elif mode == 'setnotes':
        bssid = sys.argv[2]
        notes = sys.argv[3] if len(sys.argv) > 3 else ''
        conn = get_conn(); init_db(conn)
        set_notes(conn, bssid, notes)
        conn.close()

    elif mode == 'focus':
        bssid = sys.argv[2]
        conn = get_conn(); init_db(conn)
        write_focus(conn, bssid)
        conn.close()

    else:
        # stdin mode: read JSON array, upsert all
        data = sys.stdin.read().strip()
        if not data:
            sys.exit(0)
        try:
            aps = json.loads(data)
        except json.JSONDecodeError:
            sys.exit(1)
        conn = get_conn()
        init_db(conn)
        now = datetime.now(timezone.utc).isoformat(timespec='seconds')
        for ap in aps:
            upsert_network(conn, ap, now)
        conn.commit()
        write_stats(conn)
        conn.close()
