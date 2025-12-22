#!/bin/bash
# Network bandwidth graph

INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
STATE_FILE="/tmp/net_bw_state"

if [ ! -f "$STATE_FILE" ]; then
    echo "0 0 $(date +%s)" > "$STATE_FILE"
fi

rx_bytes=$(cat /sys/class/net/"$INTERFACE"/statistics/rx_bytes 2>/dev/null || echo 0)
tx_bytes=$(cat /sys/class/net/"$INTERFACE"/statistics/tx_bytes 2>/dev/null || echo 0)
current_time=$(date +%s)

read old_rx old_tx old_time < "$STATE_FILE"

time_diff=$((current_time - old_time))

if [ $time_diff -gt 0 ]; then
    rx_rate=$(( (rx_bytes - old_rx) / time_diff / 1024 ))
    tx_rate=$(( (tx_bytes - old_tx) / time_diff / 1024 ))
    
    # Create visual bars
    rx_bars=$((rx_rate / 100))
    tx_bars=$((tx_rate / 100))
    
    [ $rx_bars -gt 10 ] && rx_bars=10
    [ $tx_bars -gt 10 ] && tx_bars=10
    
    printf "DN["
    for i in $(seq 1 10); do
        [ $i -le $rx_bars ] && printf "█" || printf "░"
    done
    printf "] %4dKB/s\n" "$rx_rate"
    
    printf "UP["
    for i in $(seq 1 10); do
        [ $i -le $tx_bars ] && printf "█" || printf "░"
    done
    printf "] %4dKB/s\n" "$tx_rate"
else
    echo "CALCULATING..."
fi

echo "$rx_bytes $tx_bytes $current_time" > "$STATE_FILE"
