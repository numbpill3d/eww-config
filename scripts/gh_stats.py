#!/usr/bin/env python3
"""
GitHub stats daemon for eww — writes to /tmp/eww_gh_*
Uses GitHub GraphQL API. Set GITHUB_TOKEN env var.
Polling interval: 5 min.
"""
import os, time, json, urllib.request

GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN", "")
USERNAME = "numbpill3d"
INTERVAL = 300

def gql(query):
    req = urllib.request.Request(
        "https://api.github.com/graphql",
        data=json.dumps({"query": query}).encode(),
        headers={
            "Authorization": f"Bearer {GITHUB_TOKEN}",
            "Content-Type": "application/json",
        }
    )
    with urllib.request.urlopen(req, timeout=15) as r:
        return json.loads(r.read())

def fetch():
    q = f"""
    {{
      user(login: "{USERNAME}") {{
        repositories(first: 1) {{ totalCount }}
        contributionsCollection {{
          contributionCalendar {{
            totalContributions
            weeks {{
              contributionDays {{
                contributionCount
                date
              }}
            }}
          }}
        }}
      }}
    }}
    """
    d = gql(q)["data"]["user"]
    repos = d["repositories"]["totalCount"]
    cal = d["contributionsCollection"]["contributionCalendar"]
    total = cal["totalContributions"]

    # commits this week
    days = cal["weeks"][-1]["contributionDays"]
    week_commits = sum(x["contributionCount"] for x in days)

    # streak
    all_days = [day for week in cal["weeks"] for day in week["contributionDays"]]
    streak = 0
    for day in reversed(all_days):
        if day["contributionCount"] > 0:
            streak += 1
        else:
            break

    open("/tmp/eww_gh_commits", "w").write(str(week_commits))
    open("/tmp/eww_gh_streak",  "w").write(str(streak))
    open("/tmp/eww_gh_repos",   "w").write(str(repos))

while True:
    try:
        if GITHUB_TOKEN:
            fetch()
    except Exception as e:
        open("/tmp/eww_gh_commits", "w").write("err")
    time.sleep(INTERVAL)
