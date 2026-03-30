#!/bin/bash
# launch_agent.sh — open an agent in a new floating kitty window
# usage: launch_agent.sh <agent>

AGENT="$1"

case "$AGENT" in
  zeroclaw)
    CMD="/home/deadgirl/.local/bin/zeroclaw" ;;
  goose)
    CMD="/usr/bin/goose" ;;
  claude|claw)
    CMD="/home/deadgirl/.local/bin/claude" ;;
  *)
    CMD="$AGENT" ;;
esac

kitty --detach --class agent-float -- "$CMD"
