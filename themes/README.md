# Landfall Themes

Theme files live in two directories:

- `themes/community/` — free themes distributed with the repo.
- `themes/marketplace/` — paid marketplace themes. These require an embedded `sha256` integrity field.

Validate a community theme:

```bash
cd server/landfall_server
dart run bin/validate_theme.dart ../../themes/community/focus-ink.yaml
```

Validate a marketplace theme:

```bash
cd server/landfall_server
dart run bin/validate_theme.dart ../../themes/marketplace/example.yaml --marketplace
```

See [docs/theme-schema.md](../docs/theme-schema.md) for the token reference and
[docs/theme-submission-guide.md](../docs/theme-submission-guide.md) for the
submission process.
