#!/usr/bin/env python3

import subprocess
import json
from datetime import datetime, timezone

ORG = "CryoBio-AI"

REPOS = [
    "fusion_cryo",
    "fusion_main",
    "fusion_android_2022_02_blue",
    "kona-squish",
    "bioconnect-production-programmer",
    "python-utilities",
    "Password-Reset-Tool",
    "kona-qt",
]

USERS = [
    "surgosan",
    "lucasmelnyk",
    "MosfetMcKenna",
    "MontyTheSoftwareEngineer",
]


def run(cmd):
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        return None
    return result.stdout.strip()


def get_events(repo):
    out = run(["gh", "api", f"repos/{ORG}/{repo}/events"])
    if not out:
        return []
    try:
        return json.loads(out)
    except:
        return []


def find_activity():
    user_latest = {u: {"time": None, "repo": None} for u in USERS}

    for repo in REPOS:
        events = get_events(repo)

        for e in events:
            user = e.get("actor", {}).get("login")
            if user not in USERS:
                continue

            t = e.get("created_at")
            if not t:
                continue

            dt = datetime.fromisoformat(t.replace("Z", "+00:00"))

            if (
                not user_latest[user]["time"]
                or dt > user_latest[user]["time"]
            ):
                user_latest[user]["time"] = dt
                user_latest[user]["repo"] = repo

    return user_latest


def format_output(data):
    now = datetime.now(timezone.utc)

    # Find most recent overall
    latest_user = None
    latest_time = None

    tooltip_lines = []

    for user, info in data.items():
        t = info["time"]
        repo = info["repo"]

        if t:
            delta = now - t
            hours = int(delta.total_seconds() // 3600)

            if hours < 24:
                rel = f"{hours}h ago"
            else:
                rel = f"{hours // 24}d ago"

            line = f"{user}: {rel} ({repo})"

            if not latest_time or t > latest_time:
                latest_time = t
                latest_user = user
        else:
            line = f"{user}: no activity"

        tooltip_lines.append(line)

    # Text for waybar
    if latest_user:
        delta = now - latest_time
        hours = int(delta.total_seconds() // 3600)

        if hours < 24:
            rel = f"{hours}h"
        else:
            rel = f"{hours // 24}d"

        text = f"{latest_user} {rel}"
    else:
        text = "No activity"

    return {
        "text": text,
        "tooltip": "\n".join(tooltip_lines),
    }


if __name__ == "__main__":
    data = find_activity()
    output = format_output(data)
    print(json.dumps(output))
