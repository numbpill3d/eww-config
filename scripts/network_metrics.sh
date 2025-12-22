#!/bin/bash
echo '{
  "interface": "wlan0",
  "status": "up",
  "packets": "'$(( RANDOM % 1000 ))'"
}'
