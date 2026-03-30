#!/usr/bin/env python3
"""
Read /proc/net/arp and output a JSON array of LAN devices.
Optionally tries getent for hostnames (fast, no network scan).
"""
import json, subprocess

devices = []
try:
    for line in open('/proc/net/arp'):
        parts = line.split()
        # header line or bad entry
        if len(parts) < 6 or ':' not in parts[3]:
            continue
        mac = parts[3]
        if mac in ('HWaddress', '00:00:00:00:00:00'):
            continue
        ip    = parts[0]
        iface = parts[5]
        # quick hostname lookup via getent (hits /etc/hosts + mDNS, no ping)
        try:
            r = subprocess.run(['getent', 'hosts', ip], capture_output=True, text=True, timeout=1)
            host = r.stdout.split()[1] if r.stdout.strip() else '?'
        except Exception:
            host = '?'
        devices.append({'ip': ip, 'mac': mac, 'host': host, 'iface': iface})
except Exception:
    pass

print(json.dumps(devices))
