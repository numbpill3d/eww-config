#!/bin/bash
# Package updates monitoring script for Arch/Endeavour OS

STATE_FILE="/tmp/package_updates_state"
LAST_CHECK_FILE="/tmp/package_last_check"

# Check if we need to refresh
current_time=$(date +%s)
if [ -f "$LAST_CHECK_FILE" ]; then
    last_check=$(cat "$LAST_CHECK_FILE")
    time_diff=$((current_time - last_check))
    
    # If checked less than 30 minutes ago, return cached result
    if [ "$time_diff" -lt 1800 ] && [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
        exit 0
    fi
fi

# Check for updates
updates=$(checkupdates 2>/dev/null | wc -l)
aur_updates=0

# Check AUR updates if yay is installed
if command -v yay &> /dev/null; then
    aur_updates=$(yay -Qua 2>/dev/null | wc -l)
fi

total_updates=$((updates + aur_updates))

# Format output
if [ "$total_updates" -eq 0 ]; then
    result="System up to date"
else
    result="$updates official"
    if [ "$aur_updates" -gt 0 ]; then
        result="$result, $aur_updates AUR"
    fi
    
    # Send notification if there are many updates
    if [ "$total_updates" -gt 20 ]; then
        notify-send "System Updates" "$total_updates updates available" -u normal -t 5000
    fi
fi

# Cache the result
echo "$result" > "$STATE_FILE"
echo "$current_time" > "$LAST_CHECK_FILE"

echo "$result"
