#!/usr/bin/env python3
"""
Research a topic with Claude and push a summary card to Landfall.

Usage:
    python claude_research.py "What are the main risks of using LLMs in prod?"

Requirements:
    pip install anthropic requests

Environment:
    ANTHROPIC_API_KEY  — your Anthropic API key
    LANDFALL_URL       — e.g. http://localhost:8080
    LANDFALL_API_KEY   — generated via POST /apiKey/generateKey
"""

import os
import sys

import anthropic
import requests

LANDFALL_URL = os.environ["LANDFALL_URL"]
LANDFALL_API_KEY = os.environ["LANDFALL_API_KEY"]


def push_card(title: str, body: str, external_id: str) -> None:
    resp = requests.post(
        f"{LANDFALL_URL}/agent/pushCard",
        json={
            "apiKey": LANDFALL_API_KEY,
            "request": {
                "__className__": "CardPushRequest",
                "source": "agent.claude",
                "title": title,
                "body": body,
                "layout": "large",
                "priority": "normal",
                "externalId": external_id,
            },
        },
        timeout=10,
    )
    resp.raise_for_status()


def main() -> None:
    topic = " ".join(sys.argv[1:]) or "Summarize the current state of AI agents"

    client = anthropic.Anthropic()

    message = client.messages.create(
        model="claude-opus-4-7",
        max_tokens=300,
        system=(
            "You are a concise research assistant. "
            "Respond with a 2-3 sentence summary suitable for a display card. "
            "No markdown, no bullet points — plain prose only."
        ),
        messages=[{"role": "user", "content": topic}],
    )

    summary = message.content[0].text.strip()
    title = topic[:80] + ("..." if len(topic) > 80 else "")

    push_card(
        title=title,
        body=summary,
        external_id="agent.claude.research",
    )
    print(f"Card pushed: {title}")
    print(f"Summary: {summary}")


if __name__ == "__main__":
    main()
