#!/usr/bin/env bash
# dns_probe.sh — probe DNS resolver + public IP
# writes: /tmp/eww_dns_server  (first nameserver from resolv.conf)
#         /tmp/eww_pubip        (public IPv4 via opendns, no auth)
#
# usage:
#   dns_probe.sh           — run once and exit  (eww [r] button)
#   dns_probe.sh --daemon  — loop every 60s     (autostart.sh)

probe_once() {
    local dns pubip

    dns=$(awk '/^nameserver/ { print $2; exit }' /etc/resolv.conf 2>/dev/null)
    printf '%s\n' "${dns:-?}" > /tmp/eww_dns_server

    # opendns myip — fast, no auth, returns your public IPv4
    pubip=$(dig +short +timeout=4 myip.opendns.com @resolver1.opendns.com 2>/dev/null \
            | head -1)
    printf '%s\n' "${pubip:-?}" > /tmp/eww_pubip
}

if [[ "$1" == "--daemon" ]]; then
    while true; do
        probe_once
        sleep 60
    done
else
    probe_once
fi
