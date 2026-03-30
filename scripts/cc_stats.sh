#!/usr/bin/env bash
# cc_stats.sh — Claude Code token usage daemon launcher
# delegates all logic to cc_tokens.py (same directory)
# writes /tmp/eww_cc_tokens_day, /tmp/eww_cc_tokens_week, /tmp/eww_cc_cost_day

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/cc_tokens.py"
