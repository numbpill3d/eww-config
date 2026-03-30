#!/bin/bash
# Outputs last run time and conclusion for autoblog workflow
REPO="numbpill3d/autoblog_01"
last_run=$(gh run list --repo $REPO --limit 1 --json updatedAt,conclusion,durationMs --jq '.[0] | "\(.updatedAt) \(.conclusion) \(.durationMs)"')
if [[ -z "$last_run" ]]; then
  echo "na na 0"
else
  echo "$last_run"
fi
