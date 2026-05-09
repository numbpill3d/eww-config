#!/usr/bin/env python3
"""
Claude Code token usage tracker.
Reads from ~/.claude/usage/ JSONL logs that Claude Code writes locally.
Falls back to parsing ~/.claude/logs/ if present.
Writes daily + weekly totals to /tmp/eww_cc_*.
"""
import os, time, json, glob
from datetime import datetime, timedelta

LOG_DIR  = os.path.expanduser("~/.claude/projects")
LOG_DIR2 = os.path.expanduser("~/.claude/logs")          # fallback, may not exist
INTERVAL = 60

# Pricing (Sonnet 4.6, $/1M tokens)
INPUT_COST  = 3.00
OUTPUT_COST = 15.00

def parse_logs(directory):
    entries = []
    for pattern in ["*.jsonl", "*.json"]:
        for f in glob.glob(os.path.join(directory, "**", pattern), recursive=True):
            try:
                for line in open(f):
                    line = line.strip()
                    if not line:
                        continue
                    obj = json.loads(line)
                    # Claude Code stores usage inside obj['message']['usage']
                    # Normalise so the rest of the code finds it at obj['usage']
                    if 'message' in obj and isinstance(obj.get('message'), dict):
                        if 'usage' in obj['message'] and 'usage' not in obj:
                            obj['usage'] = obj['message']['usage']
                    entries.append(obj)
            except Exception:
                pass
    return entries

def calc_tokens(entries, since: datetime):
    total_in = total_out = 0
    for e in entries:
        ts_str = e.get("timestamp") or e.get("ts") or e.get("created_at", "")
        try:
            ts = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
            ts = ts.replace(tzinfo=None)
        except Exception:
            continue
        if ts < since:
            continue
        usage = e.get("usage") or {}
        total_in  += usage.get("input_tokens", 0)
        total_out += usage.get("output_tokens", 0)
    return total_in, total_out

def fmt_tokens(n):
    if n >= 1_000_000: return f"{n/1_000_000:.2f}M"
    if n >= 1_000:     return f"{n/1_000:.1f}K"
    return str(n)

def calc_cost(inp, out):
    return (inp / 1_000_000 * INPUT_COST) + (out / 1_000_000 * OUTPUT_COST)

while True:
    try:
        entries = []
        for d in [LOG_DIR, LOG_DIR2]:
            if os.path.isdir(d):
                entries += parse_logs(d)

        now  = datetime.utcnow()
        day  = now.replace(hour=0, minute=0, second=0, microsecond=0)
        week = now - timedelta(days=7)

        din, dout   = calc_tokens(entries, day)
        win, wout   = calc_tokens(entries, week)

        cost_d = calc_cost(din, dout)

        open("/tmp/eww_cc_tokens_day",  "w").write(fmt_tokens(din + dout))
        open("/tmp/eww_cc_tokens_week", "w").write(fmt_tokens(win + wout))
        open("/tmp/eww_cc_cost_day",    "w").write(f"${cost_d:.2f}")
    except Exception as e:
        open("/tmp/eww_cc_tokens_day", "w").write("err")
    time.sleep(INTERVAL)
