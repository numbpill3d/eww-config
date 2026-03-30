#!/usr/bin/env bash
# agent_toggle.sh — close all agent windows if any open, else open chat view

OPEN=$(eww active-windows 2>/dev/null)

if echo "$OPEN" | grep -qF "agent-"; then
  eww close agent-chat       2>/dev/null
  eww close agent-chat-view  2>/dev/null
  eww close agent-agents     2>/dev/null
else
  eww open agent-chat-view 2>/dev/null
  sleep 0.25
  # window: 460x360 centered on 1920x1080 → input bar center ~(960, 709)
  ydotool mousemove --absolute -x 960 -y 709 2>/dev/null
  sleep 0.05
  ydotool click 0x110 2>/dev/null
fi
