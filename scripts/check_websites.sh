#!/bin/bash
# Website/service monitoring script

# Configuration - EDIT THIS SECTION WITH YOUR WEBSITES
declare -A SITES=(
    ["Example Site"]="https://example.com"
    # Add your sites here like:
    # ["My Website"]="https://yoursite.com"
    # ["API"]="https://api.yoursite.com/health"
)

STATE_DIR="/tmp/website_monitor"
mkdir -p "$STATE_DIR"

status_output=""
issues=0

# Function to check a single site
check_site() {
    local name="$1"
    local url="$2"
    local state_file="$STATE_DIR/${name// /_}.state"
    
    # Perform HTTP request with timeout
    local response=$(curl -s -o /dev/null -w "%{http_code}|%{time_total}" -m 10 "$url" 2>/dev/null)
    local http_code=$(echo "$response" | cut -d'|' -f1)
    local response_time=$(echo "$response" | cut -d'|' -f2)
    
    # Check if site is up
    if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
        local time_ms=$(printf "%.0f" "$(echo "$response_time * 1000" | bc)")
        
        # Check if response time is concerning
        if [ "$time_ms" -gt 3000 ]; then
            status_output="${status_output}[!] $name: SLOW (${time_ms}ms)\n"
            issues=1
        else
            status_output="${status_output}[✓] $name: OK (${time_ms}ms)\n"
        fi
        
        # Store current state
        echo "UP|$http_code|$time_ms" > "$state_file"
    else
        status_output="${status_output}[X] $name: DOWN (HTTP $http_code)\n"
        issues=1
        
        # Check previous state for notification
        if [ -f "$state_file" ]; then
            local prev_state=$(cat "$state_file" | cut -d'|' -f1)
            if [ "$prev_state" = "UP" ]; then
                notify-send "Website Down" "$name is not responding (HTTP $http_code)" -u critical -t 15000
            fi
        else
            notify-send "Website Down" "$name is not responding (HTTP $http_code)" -u critical -t 15000
        fi
        
        echo "DOWN|$http_code|0" > "$state_file"
    fi
}

# Check all configured sites
for name in "${!SITES[@]}"; do
    url="${SITES[$name]}"
    check_site "$name" "$url"
done

# Output result
if [ "$issues" -eq 0 ] && [ ${#SITES[@]} -gt 0 ]; then
    echo "All sites operational"
elif [ ${#SITES[@]} -eq 0 ]; then
    echo "No sites configured"
else
    echo -e "$status_output" | head -c 150
fi

# If force parameter is passed, show all results
if [ "$1" = "force" ]; then
    echo -e "\n=== Full Site Status ===\n$status_output" | notify-send "Website Status" "$(cat -)" -t 10000
fi
