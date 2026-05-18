# Landfall Themes

Community themes live in `themes/community/`. Drop a `*.yaml` file in there
and validate it with:

```bash
cd server/landfall_server
dart run bin/validate_theme.dart ../../themes/community/your-theme.yaml
```

See [docs/theme-schema.md](../docs/theme-schema.md) for the full token
reference.
