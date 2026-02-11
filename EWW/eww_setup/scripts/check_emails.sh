#!/bin/bash
# Email monitoring script

STATE_FILE="/tmp/email_state"

# Method 1: Check via notmuch if installed
check_notmuch() {
    if command -v notmuch &> /dev/null; then
        local unread=$(notmuch count tag:unread 2>/dev/null)
        if [ -n "$unread" ] && [ "$unread" -gt 0 ]; then
            echo "$unread unread"
            
            # Notify on new emails
            local state_count=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
            if [ "$unread" -gt "$state_count" ]; then
                local new_count=$((unread - state_count))
                notify-send "New Email" "$new_count new message(s)" -u normal -t 5000
            fi
            
            echo "$unread" > "$STATE_FILE"
            return
        fi
    fi
}

# Try methods in order
check_notmuch || echo "No new mail"
