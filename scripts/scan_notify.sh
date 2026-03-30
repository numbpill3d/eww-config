#!/usr/bin/env bash
# scan_notify.sh — watches /tmp/eww_rf_summary for new devices, fires notify-send
# Polls every 5s; only processes when summary changes AND contains "!"
# rf_live.sh writes /tmp/eww_rf_devices.json as a side-effect every poll cycle

SUMMARY_FILE="/tmp/eww_rf_summary"
DEVICES_FILE="/tmp/eww_rf_devices.json"
KNOWN_FILE="$HOME/.config/eww/data/known_devices"
mkdir -p "$(dirname "$KNOWN_FILE")"
touch "$KNOWN_FILE"

prev_summary=""

while true; do
  sleep 5

  [[ ! -f "$SUMMARY_FILE" ]] && continue
  summary=$(cat "$SUMMARY_FILE" 2>/dev/null)
  [[ "$summary" == "$prev_summary" ]] && continue
  prev_summary="$summary"

  # only act if there are new (!) devices
  [[ "$summary" != *"!"* ]] && continue
  [[ ! -f "$DEVICES_FILE" ]] && continue
  command -v python3 >/dev/null 2>&1 || continue

  python3 - "$DEVICES_FILE" "$KNOWN_FILE" <<'PYEOF'
import json, sys, subprocess

devices_file = sys.argv[1]
known_file   = sys.argv[2]

try:
    with open(devices_file) as f:
        devices = json.load(f)
except Exception:
    sys.exit(0)

try:
    with open(known_file) as f:
        known = set(l.strip() for l in f if l.strip())
except Exception:
    known = set()

new_keys = []
for d in devices:
    if d.get("new") == "true":
        key    = d.get("key", "")
        proto  = d.get("proto", "?").upper()
        disp   = d.get("display") or d.get("addr") or key
        sig    = d.get("sig", "")
        state  = d.get("state_s") or d.get("state", "")
        vendor = d.get("vendor") or d.get("oui", "")
        parts  = [x for x in [sig, state, vendor] if x]
        body   = f"{proto}  {disp}\n{'  '.join(parts)}"
        subprocess.run(
            ["notify-send", "-u", "normal", "-t", "6000",
             "-i", "network-wireless",
             "[ NEW DEVICE DETECTED ]", body.strip()],
            check=False
        )
        new_keys.append(key)

if new_keys:
    with open(known_file, "a") as f:
        for k in new_keys:
            f.write(k + "\n")
PYEOF

done
