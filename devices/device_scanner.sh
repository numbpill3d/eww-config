#!/bin/bash

# Configuration
EWWD_SOCKET_DIR="$XDG_RUNTIME_DIR/eww"
EWWD_SOCKET="$EWWD_SOCKET_DIR/eww"
DEVICE_FILE="/tmp/eww_devices.txt"
LAST_DEVICES_FILE="/tmp/eww_last_devices.txt"
CHECK_INTERVAL=5

# Get network range dynamically
get_network_range() {
    gateway=$(ip route | grep default | awk '{print $3}' | head -1)
    if [[ -n "$gateway" ]]; then
        # Extract network prefix (first 3 octets)
        network_prefix=$(echo $gateway | cut -d'.' -f1-3)
        echo "${network_prefix}.0/24"
    else
        echo "192.168.1.0/24"
    fi
}

# Scan for devices
scan_devices() {
    network_range=$(get_network_range)
    echo "Scanning network: $network_range"
    
    # Use nmap for device discovery
    nmap -sn $network_range 2>/dev/null | grep "Nmap scan report" | awk '{print $5}' | sort > "$DEVICE_FILE"
    
    # Add timestamp
    echo "$(date '+%Y-%m-%d %H:%M:%S')" > "${DEVICE_FILE}.timestamp"
}

# Check for new devices and notify
check_new_devices() {
    if [[ -f "$LAST_DEVICES_FILE" ]]; then
        # Compare with previous scan
        new_devices=$(comm -13 <(sort "$LAST_DEVICES_FILE") <(sort "$DEVICE_FILE"))
        
        if [[ -n "$new_devices" ]]; then
            echo "New devices detected:"
            echo "$new_devices"
            
            # Send notification for each new device
            while IFS= read -r device; do
                if [[ -n "$device" ]]; then
                    notify-send "📡 New Device Detected" "IP: $device" -u normal -t 5000
                    echo "Notification sent for: $device"
                fi
            done <<< "$new_devices"
        fi
    fi
    
    # Update last devices file
    cp "$DEVICE_FILE" "$LAST_DEVICES_FILE"
}

# Update eww widget
update_eww_widget() {
    if [[ -S "$EWWD_SOCKET" ]]; then
        # Read devices and timestamp
        devices_list=""
        if [[ -f "$DEVICE_FILE" ]]; then
            while IFS= read -r device; do
                if [[ -n "$device" ]]; then
                    devices_list="${devices_list}${device}\n"
                fi
            done < "$DEVICE_FILE"
        fi
        
        timestamp=""
        if [[ -f "${DEVICE_FILE}.timestamp" ]]; then
            timestamp=$(cat "${DEVICE_FILE}.timestamp")
        fi
        
        # Update eww variables
        eww -c ~/.config/eww/devices update device_list="$devices_list"
        eww -c ~/.config/eww/devices update last_update="$timestamp"
        
        echo "Eww widget updated"
    else
        echo "Eww daemon not running, starting it..."
        eww -c ~/.config/eww/devices daemon
        sleep 2
        eww -c ~/.config/eww/devices open device_widget
    fi
}

# Main loop
echo "Starting device monitoring..."
echo "Press Ctrl+C to stop"

while true; do
    scan_devices
    check_new_devices
    update_eww_widget
    
    echo "Sleeping for $CHECK_INTERVAL seconds..."
    sleep $CHECK_INTERVAL
done
