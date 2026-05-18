# landfall_server

The Serverpod backend for Landfall — REST and WebSocket APIs, card storage, calendar sync, OAuth routes, and agent push endpoints.

## Running locally

Start Postgres and Redis first:

```bash
docker compose up --build --detach
```

Then start the server:

```bash
dart bin/main.dart --apply-migrations
```

The server starts on port `8080` (API) and port `8082` (web/OAuth). For the full local dev setup including the display app, see [`docs/macos_local_dev.md`](../../docs/macos_local_dev.md).

## Generated code

Endpoint handlers live in `lib/src/`. Generated serialization code lives in `lib/src/generated/` — do not edit those files directly. Regenerate after adding or changing endpoints:

```bash
cd server/landfall_server
serverpod generate
```

After generating, the `server/landfall_client/` package is also updated. Any mismatch between `lib/src/generated/protocol.yaml` and the generated code causes a fatal `ExitException(1)` on server startup — not a runtime error.

## Testing

```bash
cd server/landfall_server
dart test
```

Tests hit a real local Postgres database (`landfall_test`). Do not mock the database layer — see `CONTRIBUTING.md`.

## Key paths

| Path | Contents |
|---|---|
| `lib/src/auth/` | `authenticateRequest`, API key validation, `authUserId` canonical derivation |
| `lib/src/api/` | Agent push, card, layout, and key management endpoints |
| `lib/src/web/routes/` | OAuth callback routes (Google, Microsoft), companion routes |
| `lib/src/generated/` | Serverpod-generated serialization — never edit manually |
| `config/passwords.yaml` | Server secrets (gitignored; example at `config/passwords.yaml.example`) |

## For AI assistants

- **Schema changes are fatal.** After any endpoint or model change, run `serverpod generate` and commit the updated `lib/src/generated/` files alongside the endpoint change. A stale generated file causes `ExitException(1)` at server startup.
- **Auth entry point:** `lib/src/api/authenticate_request.dart` (or `authenticateRequest` — grep to confirm the current filename). This is where API key validation and `authUserId` derivation happen.
- **`authUserId` canonical source:** `lib/src/auth/auth_user_id.dart`. Never re-implement locally — always import from here.
- **OAuth routes:** `lib/src/web/routes/` — Google and Microsoft callback handlers. Any security fix to OAuth must include a test.
- **No database mocks in tests.** Serverpod integration tests connect to a real `landfall_test` Postgres DB. The test runner is `dart test`, not `flutter test`.
- **Migrations:** Serverpod applies migrations automatically on startup when `--apply-migrations` is passed. New models require a migration file — `serverpod generate` creates one.
