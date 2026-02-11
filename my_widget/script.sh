#!/usr/bin/env bash
# Start Eww and open the window

cd "$(dirname "$0")"

eww daemon
sleep 0.2
eww open main
