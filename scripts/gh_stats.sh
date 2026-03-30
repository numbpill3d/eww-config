#!/usr/bin/env bash
# gh_stats.sh — GitHub stats daemon
# runs in a loop, writes to /tmp/eww_gh_*
# uses public API — no auth needed, 60 req/hr limit

USER="numbpill3d"
INTERVAL=300  # 5 min

fetch_gh() {
  # --- repos count ---
  profile=$(curl -sf --max-time 10 "https://api.github.com/users/$USER")
  if [[ -n "$profile" ]]; then
    echo "$profile" | jq -r '.public_repos // "?"' > /tmp/eww_gh_repos
  fi

  # --- events: commits this week + streak ---
  events=$(curl -sf --max-time 10 "https://api.github.com/users/$USER/events/public?per_page=100")
  if [[ -n "$events" ]]; then

    # commits this week (sum payload.commits across PushEvents)
    week_ago=$(date -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
               || date -v-7d +%Y-%m-%dT%H:%M:%SZ)
    commits=$(echo "$events" | jq --arg w "$week_ago" \
      '[.[] | select(.type=="PushEvent" and .created_at >= $w)
             | (.payload.commits // []) | length] | add // 0')
    echo "$commits" > /tmp/eww_gh_commits

    # streak — consecutive days with at least one PushEvent
    streak=0
    prev_day=""
    while IFS= read -r day; do
      if [[ -z "$prev_day" ]]; then
        streak=1
        prev_day="$day"
      else
        prev_ts=$(date -d "$prev_day" +%s 2>/dev/null || date -jf "%Y-%m-%d" "$prev_day" +%s)
        curr_ts=$(date -d "$day"      +%s 2>/dev/null || date -jf "%Y-%m-%d" "$day"      +%s)
        diff=$(( (prev_ts - curr_ts) / 86400 ))
        if [[ "$diff" -le 1 ]]; then
          ((streak++))
          prev_day="$day"
        else
          break
        fi
      fi
    done < <(echo "$events" | jq -r \
      '[.[] | select(.type=="PushEvent") | .created_at[:10]] | unique | sort | reverse | .[]')
    echo "$streak" > /tmp/eww_gh_streak
  fi
}

while true; do
  fetch_gh
  sleep $INTERVAL
done
