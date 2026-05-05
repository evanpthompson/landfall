#!/usr/bin/env python3
"""
Push an RSS headline digest to Landfall.

Usage:
    pip install feedparser requests
    export LANDFALL_URL="http://localhost:8080"
    export LANDFALL_API_KEY="lf_..."
    python docs/examples/rss/rss_digest.py "https://example.com/feed.xml"
"""

from __future__ import annotations

import os
import sys
from datetime import datetime, timedelta, timezone

import feedparser
import requests


LANDFALL_URL = os.environ["LANDFALL_URL"].rstrip("/")
LANDFALL_API_KEY = os.environ["LANDFALL_API_KEY"]


def push_card(feed_url: str, title: str, body: str) -> None:
    expires_at = datetime.now(timezone.utc) + timedelta(hours=6)
    response = requests.post(
        f"{LANDFALL_URL}/api/v1/cards",
        headers={
            "Authorization": f"Bearer {LANDFALL_API_KEY}",
            "Content-Type": "application/json",
        },
        json={
            "id": f"agent.rss.{abs(hash(feed_url))}",
            "source": "agent.rss",
            "title": title,
            "body": body,
            "layout": "large",
            "priority": "normal",
            "expiresAt": expires_at.isoformat(),
        },
        timeout=10,
    )
    response.raise_for_status()


def main() -> None:
    feed_url = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("RSS_FEED_URL")
    if not feed_url:
        raise SystemExit("Pass a feed URL or set RSS_FEED_URL.")

    feed = feedparser.parse(feed_url)
    entries = feed.entries[:5]
    if not entries:
        raise SystemExit("No RSS entries found.")

    feed_title = feed.feed.get("title", "RSS digest")
    lines = [f"- {entry.get('title', 'Untitled')}" for entry in entries]
    push_card(feed_url, feed_title, "\n".join(lines))
    print(f"Pushed {len(entries)} headlines from {feed_title}.")


if __name__ == "__main__":
    main()
