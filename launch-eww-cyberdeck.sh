#!/bin/bash

echo "Launching MINIMAL EWW HUD..."

killall eww 2>/dev/null
sleep 1

eww daemon &
sleep 2

# Launch all HUD widgets
eww open-many hud_uptime hud_threats hud_thermal hud_processes hud_network hud_usb hud_kernel hud_status hud_debug hud_memory hud_logs hud_radar hud_breach hud_rss hud_clipboard hud_cron

echo ""
echo "HUD activated!"
echo "- Minimal, compact widgets"
echo "- HUD-style border layout"
echo "- Radar notifications OFF"
echo ""
echo "To close: eww close-all"
