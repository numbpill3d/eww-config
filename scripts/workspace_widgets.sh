#!/usr/bin/env bash
# workspace-widgets.sh
# watches sway workspace focus events; opens/closes eww windows per workspace
# launched by start_eww.sh — do not run multiple instances

# --- CONFIGURE: map workspace name → space-separated eww window list ---
# workspace names are strings (match what sway uses: "1", "2", etc.)
declare -A WS_MAP=(
    [1]="sidebar-left sidebar-right"         # full dashboard
    [2]="sidebar-left scan-panel chan-panel net-panel radar-panel ws2-actions"
    [3]="sidebar-left sidebar-right"
    [4]="sidebar-left sidebar-right"
    [5]="sidebar-left sidebar-right"
    [6]="sidebar-left sidebar-right"
    [7]="sidebar-left sidebar-right"
    [8]="sidebar-left sidebar-right"
    [9]="sidebar-left sidebar-right"
    [10]="sidebar-left sidebar-right"
)
# fallback for workspaces not in the map above
DEFAULT_WINDOWS="sidebar-left sidebar-right"

CURRENT_WINDOWS=""

apply_ws() {
    local ws="$1"
    local target="${WS_MAP[$ws]:-$DEFAULT_WINDOWS}"
    [ "$target" = "$CURRENT_WINDOWS" ] && return

    # close windows leaving the set
    for win in $CURRENT_WINDOWS; do
        echo "$target" | grep -qw "$win" || eww close "$win" 2>/dev/null
    done
    # open windows entering the set
    for win in $target; do
        echo "$CURRENT_WINDOWS" | grep -qw "$win" || eww open "$win" 2>/dev/null
    done

    CURRENT_WINDOWS="$target"
}

# wait for sway IPC to be stable on fresh boot
sleep 1

# init — detect focused workspace and apply immediately
INIT_WS=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused==true) | .name')
apply_ws "$INIT_WS"

# stream workspace focus events — restart loop if swaymsg dies (can happen on boot)
while true; do
    swaymsg -m -t subscribe '["workspace"]' | \
        jq --unbuffered -r 'select(.change=="focus") | .current.name // empty' | \
        while IFS= read -r ws; do
            [ -n "$ws" ] && apply_ws "$ws"
        done
    sleep 1
done
