#!/bin/bash
# Network status monitoring script

# Check if connected to network
if ping -c 1 8.8.8.8 &> /dev/null; then
    # Get active interface
    interface=$(ip route | grep default | awk '{print $5}' | head -n1)
    
    # Get IP address
    ip_addr=$(ip addr show "$interface" | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    
    # Get data rates
    rx_bytes=$(cat /sys/class/net/"$interface"/statistics/rx_bytes)
    tx_bytes=$(cat /sys/class/net/"$interface"/statistics/tx_bytes)
    
    # Store current values for rate calculation
    state_file="/tmp/net_stats_$interface"
    
    if [ -f "$state_file" ]; then
        old_rx=$(cat "$state_file" | cut -d' ' -f1)
        old_tx=$(cat "$state_file" | cut -d' ' -f2)
        old_time=$(cat "$state_file" | cut -d' ' -f3)
        
        current_time=$(date +%s)
        time_diff=$((current_time - old_time))
        
        if [ $time_diff -gt 0 ]; then
            rx_rate=$(( (rx_bytes - old_rx) / time_diff / 1024 ))
            tx_rate=$(( (tx_bytes - old_tx) / time_diff / 1024 ))
            echo "ONLINE ↓${rx_rate}KB/s ↑${tx_rate}KB/s"
        else
            echo "ONLINE $ip_addr"
        fi
    else
        echo "ONLINE $ip_addr"
    fi
    
    echo "$rx_bytes $tx_bytes $(date +%s)" > "$state_file"
else
    echo "OFFLINE"
fi
