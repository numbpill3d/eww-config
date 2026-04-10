#!/usr/bin/env bash
# ws2_export.sh — dump current ws2 scan data to ~/scan_export_<ts>.txt
TS=$(date +%Y%m%d_%H%M%S)
OUT="$HOME/scan_export_${TS}.txt"

{
  echo "=== SCAN EXPORT ${TS} ==="
  echo ""
  echo "--- WIFI NETWORKS ---"
  python3 -c "
import json, sys
try:
    data = json.load(open('/tmp/eww_wifi_scan.json'))
    for d in data:
        ssid  = d.get('ssid', '?')
        bssid = d.get('bssid', '')
        chan  = d.get('chan', '?')
        band  = d.get('band', '?')
        dbm   = d.get('dbm', '?')
        sec   = d.get('security', '?')
        dist  = d.get('dist_s', '?')
        sig   = d.get('signal', 0)
        print(f'{ssid:<30} {bssid}  ch{chan:<4} {band:<5} {dbm}dBm  {sec:<8} {dist}  [{sig}%]')
except Exception as e:
    print(f'error: {e}')
" 2>/dev/null

  echo ""
  echo "--- ARP DEVICES ---"
  python3 -c "
import json, sys
try:
    data = json.load(open('/tmp/eww_rf_devices.json'))
    for d in data:
        if d.get('proto') != 'arp':
            continue
        disp   = d.get('display', '?')
        addr   = d.get('addr', '?')
        mac    = d.get('mac', '')
        vendor = d.get('vendor', '?')
        dtype  = d.get('dtype', '?')
        state  = d.get('state', '')
        dist   = d.get('dist_s', '?')
        nick_flag = '*' if disp != addr else ' '
        print(f'{nick_flag}{disp:<20} {addr:<16} {mac}  {vendor:<14} {dtype}  {state:<12} {dist}')
except Exception as e:
    print(f'error: {e}')
" 2>/dev/null

  echo ""
  echo "--- BLUETOOTH ---"
  python3 -c "
import json, sys
try:
    data = json.load(open('/tmp/eww_rf_devices.json'))
    for d in data:
        if d.get('proto') != 'bt':
            continue
        disp   = d.get('display', '?')
        mac    = d.get('mac', '')
        vendor = d.get('vendor', '?')
        dtype  = d.get('dtype', '?')
        state  = d.get('state', '')
        dist   = d.get('dist_s', '?')
        print(f'{disp:<20} {mac}  {vendor:<14} {dtype}  {state:<12} {dist}')
except Exception as e:
    print(f'error: {e}')
" 2>/dev/null

  echo ""
  echo "--- RF SUMMARY ---"
  cat /tmp/eww_rf_summary 2>/dev/null
  echo ""
  echo "--- NETWORK ---"
  echo "dns:  $(cat /tmp/eww_dns_server 2>/dev/null || echo '?')"
  echo "ext:  $(cat /tmp/eww_pubip 2>/dev/null || echo '?')"
  echo "ping: $(cat /tmp/eww_ping_ms 2>/dev/null || echo '?')"
} > "$OUT"

notify-send -t 3000 "scan export" "saved: $OUT" 2>/dev/null || true
