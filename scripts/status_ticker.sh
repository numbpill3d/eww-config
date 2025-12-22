#!/bin/bash
# Random status messages

statuses=(
  "SYSTEM NOMINAL"
  "MONITORING ACTIVE"
  "ALL SYSTEMS GO"
  "SURVEILLANCE ENABLED"
  "FIREWALL ACTIVE"
  "NETWORK SECURE"
  "THREAT LEVEL: LOW"
  "UPTIME: $(uptime -p | cut -d' ' -f2-)"
)

echo "${statuses[$RANDOM % ${#statuses[@]}]}"
