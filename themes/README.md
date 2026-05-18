# Landfall Themes

Community themes live in `themes/community/`. Drop a `*.yaml` file in there
and validate it with:

```bash
cd server/landfall_server
dart run bin/validate_theme.dart ../../themes/community/your-theme.yaml
```

See [docs/theme-schema.md](../docs/theme-schema.md) for the full token
reference.

---

## For AI assistants

- Community theme files live in `themes/community/<slug>.yaml`. To contribute a theme, add a file there and open a PR.
- Validate a theme before committing: `cd server/landfall_server && dart run bin/validate_theme.dart ../../themes/community/your-theme.yaml`
- The full token vocabulary, required fields, validation rules, and annotated examples are in [docs/theme-schema.md](../docs/theme-schema.md).
- Theme files are YAML (preferred) or JSON. Required fields: `version: "1.0"` and `meta.name`. Everything else is optional.
- `background.type: image` requires Pro on the display — don't use it in community themes.
