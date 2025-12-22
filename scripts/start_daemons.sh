#!/bin/bash
# Kill existing eww daemons
eww kill 2>/dev/null

# Start eww daemon
eww daemon

# Wait for daemon to start
sleep 1

# Open all widgets
eww open radar_widget
eww open device_list
eww open network_metrics
