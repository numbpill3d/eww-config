#!/bin/bash
# start_eww.sh — clean restart of eww sidebars + workspace widget daemon
# called via exec_always on sway start and sway reload

# kill workspace and wifi refresh daemons (will restart below)
pkill -f workspace_widgets.sh 2>/dev/null
pkill -f wifi_scan_loop 2>/dev/null

# kill any running eww daemon cleanly
eww kill 2>/dev/null

# give it a moment to fully die
sleep 1

# start daemon (ignore exit code — it's fine if it was already dead)
eww daemon
sleep 0.5

# pre-seed wifi scan cache so ws2 panel has data immediately
~/.config/eww/scripts/wifi_scan.sh > /tmp/eww_wifi_scan.json &

# background wifi refresh loop: rescan every 30s so cache stays warm
(while sleep 30; do ~/.config/eww/scripts/wifi_scan.sh > /tmp/eww_wifi_scan.json; done) &

# always open left sidebar (workspace daemon handles right sidebar per workspace)
eww open sidebar-left

# launch workspace widget daemon — opens/closes windows based on current workspace
~/.config/eww/scripts/workspace_widgets.sh &
