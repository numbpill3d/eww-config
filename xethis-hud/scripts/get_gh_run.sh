#!/bin/bash
REPO=$1
gh run list --repo $REPO --limit 1 --json updatedAt --jq '.[0].updatedAt' | xargs -I {} date -d {} +"%H:%M"
