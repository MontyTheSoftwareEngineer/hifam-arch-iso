#!/usr/bin/env python3

import subprocess
import json
import sys
from datetime import datetime

def run(cmd):
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        return None
    return result.stdout.strip()

def get_repos(owner):
    out = run(["gh", "repo", "list", owner, "--limit", "200", "--json", "nameWithOwner"])
    if not out:
        return []
    data = json.loads(out)
    return [r["nameWithOwner"] for r in data]

def get_events(repo):
    out = run(["gh", "api", f"repos/{repo}/events"])
    if not out:
        return []
    try:
        return json.loads(out)
    except:
        return []

def find_last_activity(user, owner):
    repos = get_repos(owner)
    latest_time = None
    latest_repo = None

    for repo in repos:
        events = get_events(repo)
        for e in events:
            if e.get("actor", {}).get("login") == user:
                t = e.get("created_at")
                if t:
                    dt = datetime.fromisoformat(t.replace("Z", "+00:00"))
                    if not latest_time or dt > latest_time:
                        latest_time = dt
                        latest_repo = repo

    return latest_time, latest_repo

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: last_active.py <username> <owner>")
        sys.exit(1)

    user = sys.argv[1]
    owner = sys.argv[2]

    t, repo = find_last_activity(user, owner)

    if t:
        print(f"{t.isoformat()}  {repo}")
    else:
        print("No activity found")
