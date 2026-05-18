# landfall_agent_sdk

Official Dart SDK for pushing cards to a [Landfall](https://github.com/evanpthompson/landfall) display from agents, scripts, and automations.

## Quickstart

```dart
final client = LandfallClient(
  serverUrl: 'http://your-landfall-server:8080',
  apiKey: 'lf_...',
);

await client.push(
  CardDraft.build()
    .title('Flight DEN→LAX dropped to \$287')
    .priority(CardPriority.ephemeral)
    .expires(const Duration(hours: 4)),
);

client.close();
```

That's it. The card appears on the display within 30 seconds.

---

## Installation

Add as a path dependency (pub.dev publish is pending):

```yaml
dependencies:
  landfall_agent_sdk:
    path: path/to/packages/agent_sdk
```

---

## Getting an API key

Use the helper script (reads the management token from `passwords.yaml` automatically):

```bash
bash tools/scripts/mint_api_key.sh --name my-dart-agent
```

Or manually, with the management token from `deploy/.env`:

```bash
curl -s -X POST http://localhost:8080/apiKey/generateKey \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <API_KEY_MANAGEMENT_TOKEN>" \
  -d '{"name": "my-dart-agent"}'
```

Copy the `plainTextKey` from the response — it is shown exactly once.

---

## API Reference

### `LandfallClient`

```dart
final client = LandfallClient(
  serverUrl: 'http://your-landfall-server:8080',  // your Landfall server
  apiKey: 'lf_...',                       // API key from generateKey
);
```

| Method | Description |
|---|---|
| `push(CardDraft)` | Push a card; returns `PushedCard` with the assigned `cardId`. |
| `update(cardId, CardDraft)` | Replace a card in-place. Throws if `cardId` not found. |
| `dismiss(cardId)` | Dismiss a card. Returns `true` if dismissed, `false` if not found. |
| `pushTicker(message, {source, ttl})` | Push a 30-second ticker heartbeat. Returns the card ID. |
| `listCards()` | Return all active cards, newest first. |
| `close()` | Release the underlying HTTP client. |

### `CardDraft.build()` — fluent builder

```dart
CardDraft.build()
  .title('Flight DEN→LAX dropped to \$287')   // required
  .source('agent.myapp')                        // default: 'agent.sdk'
  .body('Round trip, June 14.')
  .layout(CardLayout.medium)                    // small | medium | large | full | ticker
  .priority(CardPriority.ephemeral)             // ephemeral | normal | persistent
  .expires(const Duration(hours: 4))            // relative TTL
  // or .expiresAt(DateTime.utc(...))           // absolute expiry
  // or .persistent()                           // never auto-expires
  .cardId('myapp.flight-alert')                 // stable slot ID for in-place updates
  .data({'price': 287, 'route': 'DEN-LAX'})    // structured data for rich templates
  ();  // or .call() — builds the CardDraft
```

### In-place updates with `cardId`

Set a stable `cardId` so re-pushing replaces rather than stacks:

```dart
// First push — creates the card.
await client.push(
  CardDraft.build()
    .title('PR count: 3 open')
    .source('agent.github')
    .cardId('agent.github.open-prs')(),
);

// Later — updates the same card slot.
await client.push(
  CardDraft.build()
    .title('PR count: 7 open')
    .source('agent.github')
    .cardId('agent.github.open-prs')(),
);
```

### Ticker heartbeats

Use `pushTicker` to signal agent activity before the main card is ready:

```dart
await client.pushTicker(
  'Claude is researching EV tax credits...',
  source: 'agent.claude',
);

// ... do the work ...

await client.push(
  CardDraft.build()
    .title('EV Tax Credits 2026')
    .body(summary)
    .source('agent.claude')(),
);
```

### Error handling

```dart
try {
  await client.push(draft);
} on LandfallClientException catch (e) {
  print('${e.statusCode}: ${e.message}');
}
```

### `CardLayout` values

| Value | Description |
|---|---|
| `small` | One grid cell. Good for a single metric. |
| `medium` | Two grid cells. Default. |
| `large` | Four grid cells (2×2). Good for summaries. |
| `full` | Full display width. High-priority alerts. |
| `ticker` | Ghost ticker strip. Use `pushTicker` instead. |

### `CardPriority` values

| Value | Default TTL | Use for |
|---|---|---|
| `ephemeral` | 2 hours | Time-sensitive alerts |
| `normal` | 24 hours | Standard agent output |
| `persistent` | Never | Cards that stay until dismissed |

---

## Example

A runnable standalone example is at [`example/push_card.dart`](example/push_card.dart).

```bash
LANDFALL_URL=http://localhost:8080 \
LANDFALL_API_KEY=lf_... \
  dart run example/push_card.dart
```

---

## Choosing an integration path

| | REST API | MCP server | Agent SDK |
|---|---|---|---|
| **Best for** | Any language, any agent | MCP-compatible AI agents (Claude Desktop, Cursor) | Dart/Flutter agents and automation scripts |
| **Setup** | `curl` or any HTTP client | MCP client configuration | `dart pub add landfall_agent_sdk` |
| **Type safety** | None — raw JSON | Tool schema validation | Compile-time, IDE autocomplete |
| **Reference** | [Agent Integration Guide](../../docs/agent_integration_guide.md) | [MCP Setup Guide](../../docs/mcp_setup_guide.md) | This README |

---

## Self-hosting

See the [Self-Hosting Guide](../../docs/self_hosting_guide.md) to run your own Landfall server on a Raspberry Pi, VPS, or Docker host.

---

## For AI assistants

Key facts for using the Dart SDK in an agent implementation:

- **Not on pub.dev yet.** Use a path dependency pointing to `packages/agent_sdk/` in the monorepo. The pub.dev publish is pending.
- **`serverUrl`** should be `http://<host>:8080` — the Serverpod API port. Photos and OAuth are on `:8082` but the SDK only needs the API port.
- **`close()` is required** after you're done. The SDK holds an HTTP client that must be released — omitting `close()` keeps the Dart process alive.
- **`cardId` maps to `externalId`** in the REST API. The SDK uses `cardId` in the builder; the server stores it as `externalId`. Use a stable, deterministic ID per "slot" to enable in-place updates.
- **`push()` vs `update()`:** `push()` is an upsert (creates or replaces by `cardId`). `update()` throws if the card doesn't exist. Prefer `push()` for agent workflows where you're not sure if the card exists yet.
- **`pushTicker()`** pushes a 30-second ephemeral card into the ticker strip — use it to signal agent activity before the main result is ready.
- **Error handling:** `LandfallClientException` carries `statusCode` and `message`. The `message` matches the server's validation error format from [card-schema.md](../../docs/card-schema.md).
- **Test suite:** 30 unit tests at `test/`. Run with `dart test` from the `packages/agent_sdk/` directory.

## License

MIT — see [LICENSE](../../LICENSE).
