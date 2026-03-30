#!/usr/bin/env python3
"""
YouTube stats daemon — tracks two channels.
Reads YT_API_KEY, YT_CHANNEL_ID_1, YT_CHANNEL_ID_2 from environment.
"""
import os, time, json, urllib.request, urllib.parse

API_KEY    = os.environ.get("YT_API_KEY", "")
CHANNEL_1  = os.environ.get("YT_CHANNEL_ID_1", "")
CHANNEL_2  = os.environ.get("YT_CHANNEL_ID_2", "")
INTERVAL   = 600

def fmt(n):
    if n >= 1_000_000: return f"{n/1_000_000:.1f}M"
    if n >= 1_000:     return f"{n/1_000:.1f}K"
    return str(n)

def fetch_channel(channel_id):
    params = urllib.parse.urlencode({
        "part": "statistics,snippet",
        "id": channel_id,
        "key": API_KEY,
    })
    url = f"https://www.googleapis.com/youtube/v3/channels?{params}"
    with urllib.request.urlopen(url, timeout=15) as r:
        data = json.loads(r.read())
    item  = data["items"][0]
    stats = item["statistics"]
    title = item["snippet"]["title"]
    return {
        "title": title,
        "subs":  int(stats.get("subscriberCount", 0)),
        "views": int(stats.get("viewCount", 0)),
        "videos": int(stats.get("videoCount", 0)),
    }

while True:
    try:
        if API_KEY and CHANNEL_1 and CHANNEL_2:
            c1 = fetch_channel(CHANNEL_1)
            c2 = fetch_channel(CHANNEL_2)

            open("/tmp/eww_yt_subs",    "w").write(fmt(c1["subs"]))
            open("/tmp/eww_yt_views",   "w").write(fmt(c1["views"]))
            open("/tmp/eww_yt_videos",  "w").write(str(c1["videos"]))
            open("/tmp/eww_yt2_subs",   "w").write(fmt(c2["subs"]))
            open("/tmp/eww_yt2_views",  "w").write(fmt(c2["views"]))
            open("/tmp/eww_yt2_videos", "w").write(str(c2["videos"]))
            open("/tmp/eww_yt_title1",  "w").write(c1["title"][:20])
            open("/tmp/eww_yt_title2",  "w").write(c2["title"][:20])
        else:
            for f in ["/tmp/eww_yt_subs", "/tmp/eww_yt2_subs"]:
                open(f, "w").write("no key")
    except Exception as e:
        open("/tmp/eww_yt_subs", "w").write("err")
    time.sleep(INTERVAL)
