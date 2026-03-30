#!/bin/bash

# Get the path to the heartbeat state file
STATE_FILE="/home/deadgirl/.openclaw/workspace/memory/heartbeat-state.json"

# Get current time in seconds since epoch
CURRENT_TIME=$(date +%s)

# Read last Moltbook check time from JSON
LAST_CHECK=$(jq -r '.lastMoltbookCheck // 0' "$STATE_FILE")

# Calculate time difference in seconds
TIME_DIFF=$((CURRENT_TIME - LAST_CHECK))

# Define a freshness window (e.g., 60 minutes = 3600 seconds)
FRESHNESS_WINDOW_SECONDS=$((60 * 60))

# Calculate score (100 for fresh, decreasing to 0 for stale)
if [ "$LAST_CHECK" -eq 0 ] || [ "$TIME_DIFF" -ge "$FRESHNESS_WINDOW_SECONDS" ]; then
  SCORE=0 # Completely stale or never checked
else
  # Invert the freshness: smaller diff means higher score
  SCORE=$((100 - (TIME_DIFF * 100 / FRESHNESS_WINDOW_SECONDS)))
  if [ "$SCORE" -lt 0 ]; then
    SCORE=0
  fi
fi

echo "$SCORE"
