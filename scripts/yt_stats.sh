#!/usr/bin/env bash
# yt_stats.sh — YouTube stats daemon
# needs a YouTube Data API v3 key — free from console.cloud.google.com
# runs in a loop, writes to /tmp/eww_yt_*

# ---- CONFIGURE THESE ----
API_KEY="YOUR_YOUTUBE_API_KEY_HERE"
CHANNEL_ID_1="YOUR_CHANNEL_ID_1_HERE"   # AI Explains AI
CHANNEL_ID_2="YOUR_CHANNEL_ID_2_HERE"   # second channel (leave blank if none)
# channel ID looks like: UCxxxxxxxxxxxxxxxxxxxxxxxx
# find yours at: youtube.com/account_advanced
# --------------------------

INTERVAL=600  # 10 min (yt api quota is 10k units/day, each stats req = 1 unit)
BASE="https://www.googleapis.com/youtube/v3"

fetch_channel() {
  local cid="$1"
  local prefix="$2"   # "yt" or "yt2"
  local title_slot="$3"

  if [[ -z "$cid" || "$cid" == "YOUR_CHANNEL_ID"* ]]; then
    echo "?" > /tmp/eww_${prefix}_subs
    echo "?" > /tmp/eww_${prefix}_views
    echo "?" > /tmp/eww_${prefix}_videos
    return
  fi

  data=$(curl -sf --max-time 10 \
    "${BASE}/channels?part=statistics,snippet&id=${cid}&key=${API_KEY}")

  if [[ -z "$data" ]]; then return; fi

  echo "$data" | jq -r '.items[0].statistics.subscriberCount // "?"' > /tmp/eww_${prefix}_subs
  echo "$data" | jq -r '.items[0].statistics.viewCount       // "?"' > /tmp/eww_${prefix}_views
  echo "$data" | jq -r '.items[0].statistics.videoCount      // "?"' > /tmp/eww_${prefix}_videos

  if [[ -n "$title_slot" ]]; then
    echo "$data" | jq -r '.items[0].snippet.title // "?"' > /tmp/eww_${title_slot}
  fi
}

if [[ "$API_KEY" == "YOUR_"* ]]; then
  echo "yt_stats: set API_KEY and CHANNEL_IDs in $0" >&2
  # write placeholders so widgets don't hang on "?"
  for f in yt_subs yt_views yt_videos yt2_subs yt2_views yt2_videos yt_title1 yt_title2; do
    echo "?" > /tmp/eww_$f
  done
  exit 1
fi

while true; do
  fetch_channel "$CHANNEL_ID_1" "yt"  "eww_yt_title1"
  fetch_channel "$CHANNEL_ID_2" "yt2" "eww_yt_title2"
  sleep $INTERVAL
done
