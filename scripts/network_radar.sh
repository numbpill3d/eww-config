#!/bin/bash
# Network Radar Scanner - Detects devices on local network

STATE_FILE="/tmp/network_radar_state"
KNOWN_DEVICES_FILE="$HOME/.config/eww/known_devices.txt"

# Create known devices file if it doesn't exist
if [ ! -f "$KNOWN_DEVICES_FILE" ]; then
    touch "$KNOWN_DEVICES_FILE"
fi

# Get network interface and subnet
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
if [ -z "$INTERFACE" ]; then
    echo "NO NETWORK"
    exit 0
fi

SUBNET=$(ip -o -f inet addr show "$INTERFACE" | awk '{print $4}')

if [ "$1" = "count" ]; then
    # Just return device count
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE" | wc -l
    else
        echo "0"
    fi
    exit 0
fi

# Scan network (quick scan)
scan_result=$(timeout 10 nmap -sn "$SUBNET" 2>/dev/null | grep "Nmap scan report" | awk '{print $5}')

if [ -z "$scan_result" ]; then
    # Fallback to arp scan if nmap not available
    scan_result=$(arp -a | grep -v "incomplete" | awk '{print $2}' | tr -d '()')
fi

# Store current scan
echo "$scan_result" > "$STATE_FILE"

# Check for unknown devices
output=""
unknown_count=0

while IFS= read -r device; do
    if ! grep -q "$device" "$KNOWN_DEVICES_FILE"; then
        output="${output}[!] UNKNOWN: $device\n"
        unknown_count=$((unknown_count + 1))
        
        # Send notification for first unknown device
        if [ "$unknown_count" -eq 1 ]; then
            notify-send "Network Radar" "Unknown device detected: $device" -u normal -t 8000
        fi
    else
        output="${output}[✓] KNOWN: $device\n"
    fi
done <<< "$scan_result"

# If no output, show status
if [ -z "$output" ]; then
    echo "SCANNING NETWORK..."
else
    echo -e "$output" | head -n 10
fi

# Auto-learn devices after 5 scans (optional)
# Uncomment to automatically add devices to known list
# if [ $(wc -l < "$STATE_FILE") -gt 5 ]; then
#     cat "$STATE_FILE" >> "$KNOWN_DEVICES_FILE"
#     sort -u "$KNOWN_DEVICES_FILE" -o "$KNOWN_DEVICES_FILE"
# fi
