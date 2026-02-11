#!/bin/bash
# System events monitoring script

STATE_FILE="/tmp/system_events_state"
JOURNAL_CURSOR_FILE="/tmp/journal_cursor"

events=""

# Function to check journalctl for recent errors
check_journal() {
    local cursor=""
    
    if [ -f "$JOURNAL_CURSOR_FILE" ]; then
        cursor=$(cat "$JOURNAL_CURSOR_FILE")
    fi
    
    if [ -n "$cursor" ]; then
        errors=$(journalctl --cursor="$cursor" -p err -n 5 --no-pager -o short-monotonic 2>/dev/null | grep -v "^--" | wc -l)
    else
        errors=$(journalctl -p err -n 5 --no-pager -o short-monotonic 2>/dev/null | grep -v "^--" | wc -l)
    fi
    
    if [ "$errors" -gt 0 ]; then
        events="${events}[!] $errors new error(s) in journal\n"
        
        # Send notification for critical errors
        journalctl -p crit -n 1 --no-pager -o cat 2>/dev/null | while read -r line; do
            if [ -n "$line" ]; then
                notify-send "System Alert" "Critical error detected" -u critical -t 10000
            fi
        done
    fi
    
    # Store cursor for next check
    journalctl -n 1 --show-cursor 2>/dev/null | grep "^-- cursor:" | cut -d: -f2- | xargs > "$JOURNAL_CURSOR_FILE"
}

# Check for failed systemd services
check_failed_services() {
    local failed=$(systemctl --failed --no-legend --no-pager 2>/dev/null | wc -l)
    
    if [ "$failed" -gt 0 ]; then
        events="${events}[X] $failed failed service(s)\n"
        
        # Get service names
        local services=$(systemctl --failed --no-legend --no-pager 2>/dev/null | awk '{print $1}' | head -n 3 | tr '\n' ' ')
        events="${events}    $services\n"
    fi
}

# Check disk space warnings
check_disk_space() {
    local critical_partitions=$(df -h | awk '$5+0 >= 90 {print $6 " " $5}')
    
    if [ -n "$critical_partitions" ]; then
        events="${events}[!] Critical disk space:\n"
        echo "$critical_partitions" | while read -r line; do
            events="${events}    $line\n"
        done
        
        notify-send "Disk Space Warning" "Partition critically low on space" -u critical -t 10000
    fi
}

# Check for package manager locks
check_package_locks() {
    if [ -f "/var/lib/pacman/db.lck" ]; then
        events="${events}[*] Package manager in use\n"
    fi
}

# Check CPU temperature (if sensors available)
check_temperature() {
    if command -v sensors &> /dev/null; then
        local temp=$(sensors | grep -i "Core 0" | awk '{print $3}' | tr -d '+°C' | cut -d. -f1)
        
        if [ -n "$temp" ] && [ "$temp" -gt 80 ]; then
            events="${events}[!] High CPU temp: ${temp}°C\n"
            
            if [ "$temp" -gt 90 ]; then
                notify-send "Temperature Warning" "CPU temperature critical: ${temp}°C" -u critical -t 10000
            fi
        fi
    fi
}

# Run all checks
check_journal
check_failed_services
check_disk_space
check_package_locks
check_temperature

# Output result
if [ -z "$events" ]; then
    echo "No system events"
else
    echo -e "$events" | head -c 200
fi
