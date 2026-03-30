#!/bin/bash
# Reads last github action run for traffic-phantom
REPO="numbpill3d/traffic-phantom"
last_run=$(gh run list --repo $REPO --limit 1 --json updatedAt,conclusion,durationMs --jq '.[0] | "\(.updatedAt) \(.conclusion) \(.durationMs)"')
if [[ -z "$last_run" ]]; then
  echo "na na 0"
else
  echo "$last_run"
fi
