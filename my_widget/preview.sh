#!/usr/bin/env bash
# Quick 2-second preview

cd "$(dirname "$0")"

eww daemon
sleep 0.2
eww open main
sleep 2
eww close main
