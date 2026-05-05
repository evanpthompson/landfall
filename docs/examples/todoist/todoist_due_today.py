#!/usr/bin/env python3
"""
Push a Todoist "due today" card to Landfall.

Usage:
    pip install requests
    export TODOIST_API_TOKEN="..."
    export LANDFALL_URL="http://localhost:8080"
    export LANDFALL_API_KEY="lf_..."
    python docs/examples/todoist/todoist_due_today.py
"""

from __future__ import annotations

import os
from datetime import datetime, timedelta, timezone

import requests


LANDFALL_URL = os.environ["LANDFALL_URL"].rstrip("/")
LANDFALL_API_KEY = os.environ["LANDFALL_API_KEY"]
TODOIST_API_TOKEN = os.environ["TODOIST_API_TOKEN"]


def todoist_tasks_due_today() -> list[dict]:
    response = requests.get(
        "https://api.todoist.com/rest/v2/tasks",
        headers={"Authorization": f"Bearer {TODOIST_API_TOKEN}"},
        params={"filter": "today | overdue"},
        timeout=10,
    )
    response.raise_for_status()
    return response.json()


def push_card(tasks: list[dict]) -> None:
    count = len(tasks)
    title = "No tasks due today" if count == 0 else f"{count} tasks due today"
    body = "Clear calendar." if count == 0 else "\n".join(
        f"- {task['content']}" for task in tasks[:6]
    )

    expires_at = datetime.now(timezone.utc) + timedelta(hours=4)
    response = requests.post(
        f"{LANDFALL_URL}/api/v1/cards",
        headers={
            "Authorization": f"Bearer {LANDFALL_API_KEY}",
            "Content-Type": "application/json",
        },
        json={
            "id": "agent.todoist.due-today",
            "source": "agent.todoist",
            "title": title,
            "body": body,
            "layout": "medium",
            "priority": "normal" if count == 0 else "ephemeral",
            "expiresAt": expires_at.isoformat(),
        },
        timeout=10,
    )
    response.raise_for_status()


def main() -> None:
    tasks = todoist_tasks_due_today()
    push_card(tasks)
    print(f"Pushed Todoist card with {len(tasks)} tasks.")


if __name__ == "__main__":
    main()
