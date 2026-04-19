# Landfall Card Schema

Version 1.0 — April 2026

Every piece of content on a Landfall display is a **Card**. Built-in widgets (clock, weather, calendar) are cards. Agent-pushed content is also a card. This document is the authoritative spec for the card schema used by the Agent Push API.

---

## Card Object

A card returned by the API (e.g. from `listCards` or `pushCard`) has the following shape:

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | integer | yes | Database row ID (auto-assigned) |
| `externalId` | string | yes | Stable agent-controlled ID. Defaults to a UUID if not supplied. Use a consistent value to update a card in-place. |
| `source` | string | yes | Origin identifier. Format: `"<namespace>.<name>"` — e.g. `"agent.claude"`, `"skill.home_assistant"`. |
| `title` | string | yes | Primary display text. Max 200 characters. |
| `body` | string | no | Secondary display text. Max 2,000 characters. |
| `dataJson` | string | no | JSON object string for structured/rich rendering. Max 32 KB. Must be a `{}` object, not an array or scalar. |
| `layout` | string | no | Size hint. One of: `small`, `medium`, `large`, `full`. Default: `medium`. |
| `priority` | string | no | Controls default TTL. One of: `ephemeral`, `normal`, `persistent`. Default: `normal`. |
| `expiresAt` | string (ISO 8601) | no | Explicit expiry timestamp. Overrides priority TTL when set. |
| `persistent` | boolean | no | When `true`, the card never auto-expires. Takes precedence over `expiresAt` and `priority`. Default: `false`. |
| `createdAt` | string (ISO 8601) | yes | Server-assigned creation time (UTC). Reset on in-place update. |
| `dismissedAt` | string (ISO 8601) | no | Set when the user manually dismisses the card. Null for active cards. |

---

## Push Request Object

When calling `pushCard` or `updateCard`, the `request` body uses this shape:

| Field | Type | Required | Description |
|---|---|---|---|
| `source` | string | **yes** | Origin identifier. Format: `<namespace>.<name>`. Max 100 characters. |
| `title` | string | **yes** | Primary display text. Max 200 characters. |
| `body` | string | no | Secondary text. Max 2,000 characters. |
| `dataJson` | string | no | Structured data as a JSON object string. Max 32 KB. |
| `layout` | string | no | `small` \| `medium` \| `large` \| `full`. Default: `medium`. |
| `priority` | string | no | `ephemeral` \| `normal` \| `persistent`. Default: `normal`. |
| `expiresAt` | string (ISO 8601) | no | Explicit expiry (UTC). |
| `persistent` | boolean | no | Never auto-expire. Default: `false`. |
| `externalId` | string | no | Stable ID for in-place updates. If omitted, a UUID is generated. |

> **Note:** Serverpod serialization requires a `"__className__": "CardPushRequest"` field in the request object. See the integration guide for examples.

---

## Layout Values

| Value | Meaning |
|---|---|
| `small` | 1 grid cell — compact info, single line |
| `medium` | 2 grid cells — title + short body (default) |
| `large` | 4 grid cells — title, body, and optional data |
| `full` | Full display width — rich/featured content |

---

## Priority and TTL

| Value | Default TTL | Use case |
|---|---|---|
| `ephemeral` | 2 hours | Time-sensitive alerts, notifications |
| `normal` | 24 hours | Standard agent output (default) |
| `persistent` | Never | Maps to `persistent: true`; both are honored |

TTL defaults are user-configurable in Settings. Expiry is evaluated server-side every 5 minutes. Expired cards are **retained** in the database for card history — they are not deleted.

**Expiry resolution order (most specific wins):**
1. `persistent: true` → never expires
2. `expiresAt` is set → expires at that exact time
3. Neither → server applies the `priority` default TTL

---

## Source Convention

The `source` field identifies the origin of a card. It must match the pattern `<namespace>.<name>` — two dot-separated segments of letters, digits, and underscores.

| Namespace | Used by |
|---|---|
| `system` | Built-in Landfall widgets (clock, weather, calendar) |
| `agent` | External AI agents and automations |
| `skill` | Named Landfall skills or integration packs |

Examples: `agent.claude`, `agent.n8n`, `skill.home_assistant`, `skill.github`

---

## In-Place Updates

To update an existing card rather than creating a new one, supply the same `externalId` on every push. If a card with that ID already exists:

- All fields are replaced with the new values
- `dismissedAt` is cleared — a re-pushed card is un-dismissed
- `createdAt` is reset, so TTL starts fresh

Choose a stable, deterministic ID per "slot" on your display:

```
"externalId": "agent.claude.daily-summary"
"externalId": "skill.github.open-prs"
"externalId": "skill.home_assistant.front-door"
```

---

## Validation Errors

The server returns a 400-class error with a human-readable message if validation fails. The response shape is:

```json
{
  "message": "Invalid card payload: title must not be empty."
}
```

Multiple errors are concatenated into a single message.

---

## Changelog

| Version | Date | Notes |
|---|---|---|
| 1.0 | 2026-04-19 | Initial release |
