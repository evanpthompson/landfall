# Landfall LayoutSchema — Open Specification v1.0

> This is the authoritative reference for the `LayoutSchema` format — the document structure used to programmatically define card positions, visibility, and display configuration on a Landfall display. Agents, automation scripts, and human authors can all use this format to configure a layout without touching the drag-and-drop editor.

---

## Table of Contents

1. [Overview](#overview)
2. [Schema Structure](#schema-structure)
3. [Source-Based Card Reference](#source-based-card-reference)
4. [displayConfig by Card Type](#displayconfig-by-card-type)
5. [Using apply_layout from the REST API](#using-apply_layout-from-the-rest-api)
6. [Using apply_layout from the Agent SDK](#using-apply_layout-from-the-agent-sdk)
7. [Using apply_layout from the MCP Server](#using-apply_layout-from-the-mcp-server)
8. [Combining Layout and Theme](#combining-layout-and-theme)
9. [Complete Examples](#complete-examples)

---

## Overview

### What a LayoutSchema is

A `LayoutSchema` document defines the arrangement of cards on a Landfall display: where each card sits in the grid, whether it is visible, whether it is locked against accidental moves, and how each card-type should be configured (e.g., how many calendar events to show, whether the clock displays seconds).

A LayoutSchema does not describe card content. Content is pushed via the card API. A LayoutSchema describes the *frame*: which slots exist, where they are, and how each card type presents what it knows.

### Relationship to profiles and themes

A LayoutSchema is applied to a named dashboard profile. If no profile is specified, it is applied to the currently active profile. Profiles link to themes via `themeId`; a LayoutSchema does not include theme tokens. Layout and theme are separate concerns applied independently.

The three-way relationship is:
- **Profile** — the named context (Morning Routine, Work Focus, Party)
- **Layout** — where cards are and how they are configured (LayoutSchema)
- **Theme** — what the display looks like visually (ThemeSchema)

Applying a LayoutSchema changes the layout. Applying a theme changes the visual. Both can be applied in the same agent workflow to fully reconfigure the display.

### When to use apply_layout vs. the drag-and-drop editor

Use `apply_layout` when:
- An agent needs to reconfigure the display based on context (switching to a research layout when a long task starts)
- An automation sets up a layout on a schedule (party layout on Friday evenings)
- You are setting up a fresh display and want to script the initial layout rather than manually drag cards
- You are managing multiple displays and need reproducible layout configuration across all of them

Use the drag-and-drop editor when:
- You are interactively refining a layout and want to see changes live
- You want to tweak one or two card positions without defining a complete layout document

Partial layouts (documents that only specify some cards) are valid. Cards not referenced in the schema are left unchanged. You can use `apply_layout` to move one card without touching the rest of the layout.

---

## Schema Structure

### Top-level structure

```yaml
version: "1.0"            # required. Schema version.
meta:                     # optional
  name: "..."             # Display name for this layout document
  description: "..."      # Optional description
  profileSlug: "..."      # Optional — apply to this named profile. If omitted, applies to active profile.

grid:                     # optional — if omitted, the display's current grid dimensions are preserved
  columns: 12             # int, 8–16. Default: 12.
  rows: 8                 # int, 6–12. Default: 8.

cards:                    # required — list of card configuration entries
  - source: "..."         # card source string (see Source-Based Card Reference)
    slot:                 # optional — if omitted, the card's current slot is preserved
      column: 0           # int, 0 to (columns - 1)
      row: 0              # int, 0 to (rows - 1)
      columnSpan: 3       # int, 1 to columns. Card width in grid columns.
      rowSpan: 2          # int, 1 to rows. Card height in grid rows.
    visible: true         # bool, optional. If omitted, current visibility is preserved.
    locked: false         # bool, optional. If omitted, current lock state is preserved.
    mood: normal          # enum, optional. normal | urgent | success | celebratory | muted.
                          # For system cards only — agent-pushed cards carry their own mood.
    displayConfig:        # object, optional. Card-type-specific settings.
      ...
```

### Field reference

| Field | Type | Required | Notes |
|---|---|---|---|
| `version` | string | yes | Must be `"1.0"`. |
| `meta` | object | no | Metadata about this layout document. Not stored on the display. |
| `meta.name` | string | no | Display name for this document. Max 80 characters. |
| `meta.description` | string | no | Max 300 characters. |
| `meta.profileSlug` | string | no | If set, the layout is applied to this profile. Must match an existing profile's slug. If the profile does not exist, the request returns a 404. If omitted, applies to the currently active profile. |
| `grid.columns` | int | no | 8–16. Changes to grid dimensions reflow all cards; cards that would overflow the new grid are clamped to fit. |
| `grid.rows` | int | no | 6–12. |
| `cards` | array | yes | At least one entry required. Empty arrays are rejected. |
| `cards[].source` | string | yes | Source identifier for the card. See Source-Based Card Reference. |
| `cards[].slot` | object | no | If omitted, the card's current slot is preserved unchanged. |
| `cards[].slot.column` | int | yes (if slot set) | Zero-indexed. Must be within grid bounds. |
| `cards[].slot.row` | int | yes (if slot set) | Zero-indexed. Must be within grid bounds. |
| `cards[].slot.columnSpan` | int | yes (if slot set) | 1–columns. Column + columnSpan must not exceed grid column count. |
| `cards[].slot.rowSpan` | int | yes (if slot set) | 1–rows. Row + rowSpan must not exceed grid row count. |
| `cards[].visible` | bool | no | If omitted, current state is preserved. |
| `cards[].locked` | bool | no | If omitted, current state is preserved. Locked cards cannot be moved or resized in the editor. |
| `cards[].mood` | enum | no | System card mood override. One of: `normal`, `urgent`, `success`, `celebratory`, `muted`. Only meaningful for system cards — agent cards carry their mood from the push payload. |
| `cards[].displayConfig` | object | no | Card-type-specific configuration. See displayConfig by Card Type. |

### Validation rules

- `version` must be exactly the string `"1.0"`.
- Slot positions must be within the grid. A card at `column: 10, columnSpan: 4` on a 12-column grid is invalid — it would overflow.
- Duplicate source values within the `cards` array are not allowed. Each source may appear at most once per document.
- `displayConfig` is validated against the registered configuration schema for each card type. Unknown keys within `displayConfig` produce a warning but are not rejected — forward compatibility is preserved.

---

## Source-Based Card Reference

Cards are referenced by `source` string, not by internal UUID. This is a deliberate design constraint: agents and automation scripts should not need to inspect the display's current state to determine card IDs before reconfiguring a layout. The source string is stable, human-readable, and documented here.

### System card sources

These sources correspond to the built-in Landfall widgets. Every display has all of these registered; they may be visible or hidden.

| Source | Card type | Notes |
|---|---|---|
| `system.clock` | Clock widget | Large time display with optional seconds and date line. |
| `system.weather.current` | Current weather | Temperature, conditions, feels-like, wind. |
| `system.weather.forecast` | 5-day forecast strip | Horizontal row of 5 forecast tiles. |
| `system.calendar` | Calendar events | Upcoming event list from linked calendar feeds. |
| `system.photos` | Photo frame | Rotating slideshow from linked photo source. |

### Agent card feed source

| Source | Notes |
|---|---|
| `agent.feed` | The agent card panel — the vertical strip showing agent-pushed cards. This is not an individual card but the feed container. Its slot determines where the agent panel sits relative to the main grid. Configuring its visibility hides or shows the entire agent panel. |

### Agent-pushed card sources

Individual agent-pushed cards have sources in the form `agent.<name>` where `<name>` is the value the pushing agent specified in the `source` field of the push payload. These sources are not listed here because they are defined by the agent integrations that produce them.

Agent-pushed cards cannot be repositioned via LayoutSchema — their slot within the agent feed panel is determined by push order and priority, not grid position. LayoutSchema controls the agent feed panel as a whole (via `agent.feed`), not individual cards within it.

### Server behavior when a source is not found

If a card entry references a source that does not exist in the active profile:

- For system card sources: the server creates a new `CardConfig` entry with default slot values and applies the specified configuration. Default slot: `{column: 0, row: 0, columnSpan: 3, rowSpan: 2}`.
- For `agent.feed`: always exists; cannot be absent.
- For agent-pushed card sources: ignored. Agent-pushed card positions within the feed cannot be set via LayoutSchema.

### Partial layouts

A layout document does not need to reference every card. Cards not mentioned in the document are left exactly as they are — position, visibility, locked state, and displayConfig all unchanged. This makes LayoutSchema composable:

```yaml
# This is a valid partial layout — it only moves the clock.
version: "1.0"
cards:
  - source: "system.clock"
    slot: { column: 0, row: 0, columnSpan: 4, rowSpan: 3 }
```

---

## displayConfig by Card Type

`displayConfig` is a flat object of configuration parameters specific to each card type. Parameters are optional; unspecified parameters use their documented defaults. Unknown parameters are ignored with a warning.

### system.clock

| Parameter | Type | Default | Notes |
|---|---|---|---|
| `showSeconds` | bool | `false` | Whether to display the seconds digit. Showing seconds increases visual movement and may not be appropriate for all display contexts. |
| `showDate` | bool | `true` | Whether to display the date line below the time. |
| `showDayOfWeek` | bool | `true` | Whether to include the day of week in the date line (e.g., "Tuesday, April 28"). Only meaningful if `showDate` is true. |
| `use24Hour` | bool | `false` | 24-hour clock format. When false, displays AM/PM suffix. |
| `variant` | enum | `large` | `large \| compact`. `large` uses the maximum available font size for the card's slot. `compact` uses a reduced size, leaving room for additional information below. |

**Example:**
```yaml
- source: "system.clock"
  slot: { column: 0, row: 0, columnSpan: 3, rowSpan: 2 }
  displayConfig:
    showSeconds: false
    showDate: true
    showDayOfWeek: true
    use24Hour: false
    variant: large
```

### system.weather.current

| Parameter | Type | Default | Notes |
|---|---|---|---|
| `units` | enum | `imperial` | `imperial \| metric`. Controls temperature units (°F vs °C) and wind speed (mph vs km/h). |
| `showFeelsLike` | bool | `true` | Display the "feels like" temperature below the actual temperature. |
| `showWind` | bool | `false` | Display wind speed and direction. |
| `showHumidity` | bool | `false` | Display humidity percentage. |
| `showConditionLabel` | bool | `true` | Display the text condition label (e.g., "Partly Cloudy"). When false, only the condition icon is shown. |
| `variant` | enum | `standard` | `standard \| minimal`. `minimal` shows only temperature and condition icon — no secondary data. |

**Example:**
```yaml
- source: "system.weather.current"
  slot: { column: 0, row: 2, columnSpan: 3, rowSpan: 2 }
  displayConfig:
    units: imperial
    showFeelsLike: true
    showWind: false
    variant: standard
```

### system.weather.forecast

| Parameter | Type | Default | Notes |
|---|---|---|---|
| `units` | enum | `imperial` | `imperial \| metric`. Matches the current weather card if both are shown. |
| `days` | int | `5` | 3–7. Number of forecast days to display. Cards narrower than 8 columns should use 3 days to avoid truncation. |
| `showHighLow` | bool | `true` | Show daily high and low temperatures per tile. When false, shows only the high. |
| `showPrecipitation` | bool | `false` | Show precipitation probability per tile. |

**Example:**
```yaml
- source: "system.weather.forecast"
  slot: { column: 3, row: 6, columnSpan: 9, rowSpan: 2 }
  displayConfig:
    units: imperial
    days: 5
    showHighLow: true
    showPrecipitation: false
```

### system.calendar

| Parameter | Type | Default | Notes |
|---|---|---|---|
| `daysAhead` | int | `7` | 1–30. How many days of upcoming events to include. |
| `maxEvents` | int | `8` | 1–20. Maximum number of events to show. Events are ordered by start time ascending. |
| `showTime` | bool | `true` | Show event start time. All-day events always show "All day" regardless of this setting. |
| `showCalendarColor` | bool | `true` | Show the calendar feed's color dot next to each event. Useful for distinguishing events from multiple calendars. |
| `showLocation` | bool | `false` | Show event location if present. Only recommended for cards with `rowSpan` ≥ 3. |
| `hideAllDay` | bool | `false` | When true, all-day events are filtered out of the list. |
| `variant` | enum | `list` | `list \| compact`. `compact` reduces line height and removes the calendar color dot to fit more events. |

**Example:**
```yaml
- source: "system.calendar"
  slot: { column: 0, row: 4, columnSpan: 3, rowSpan: 4 }
  displayConfig:
    daysAhead: 7
    maxEvents: 6
    showTime: true
    showCalendarColor: true
    showLocation: false
    hideAllDay: false
    variant: list
```

### system.photos

| Parameter | Type | Default | Notes |
|---|---|---|---|
| `intervalSeconds` | int | `30` | 10–300. How long each photo is displayed before transitioning to the next. |
| `transition` | enum | `crossfade` | `crossfade \| slide \| fade`. How photos transition. |
| `transitionDurationMs` | int | `800` | 200–2000. Transition animation duration in milliseconds. |
| `showCaption` | bool | `false` | Show photo filename or caption if available. |
| `fit` | enum | `cover` | `cover \| contain`. `cover` fills the card slot (may crop). `contain` shows the full image (may letterbox). |
| `randomOrder` | bool | `true` | When true, photos cycle in random order. When false, photos cycle in the order they appear in the source folder. |

**Example:**
```yaml
- source: "system.photos"
  slot: { column: 3, row: 0, columnSpan: 9, rowSpan: 6 }
  displayConfig:
    intervalSeconds: 30
    transition: crossfade
    transitionDurationMs: 800
    showCaption: false
    fit: cover
    randomOrder: true
```

### agent.feed

| Parameter | Type | Default | Notes |
|---|---|---|---|
| `maxCards` | int | `null` | 1–50. Maximum number of agent cards to show in the panel at once. Null means no cap (the profile's `ProfileCardFilter.maxAgentCards` applies). |
| `showSource` | bool | `true` | Show the source label below each card's title. |
| `showTimestamp` | bool | `true` | Show the card's push timestamp. |
| `cardSpacing` | enum | `normal` | `compact \| normal \| comfortable`. Controls vertical spacing between cards in the feed. |

**Example:**
```yaml
- source: "agent.feed"
  slot: { column: 9, row: 0, columnSpan: 3, rowSpan: 8 }
  visible: true
  displayConfig:
    maxCards: 10
    showSource: true
    showTimestamp: true
    cardSpacing: normal
```

---

## Using apply_layout from the REST API

### Endpoint

```
POST /api/layout/apply
Authorization: Bearer <api-key>
Content-Type: application/yaml   (or application/json)
```

### Request body

The raw LayoutSchema document (YAML or JSON). The `Content-Type` header determines which parser is used.

### Response

```json
{
  "ok": true,
  "profileId": "uuid",
  "profileSlug": "work-focus",
  "appliedCards": 4,
  "skippedCards": 0,
  "layout": { ... }
}
```

| Field | Notes |
|---|---|
| `ok` | `true` on success. |
| `profileId` | UUID of the profile that was updated. |
| `profileSlug` | Slug of the profile that was updated. |
| `appliedCards` | Number of card configs that were created or updated. |
| `skippedCards` | Number of card entries in the document that were skipped (e.g., agent-pushed card sources). |
| `layout` | The full updated layout object as stored. |

### Error responses

| Status | Meaning |
|---|---|
| `400 Bad Request` | Schema validation failed. Response body contains an array of validation errors, each with `token`, `expected`, and `received` fields. |
| `401 Unauthorized` | Missing or invalid API key. |
| `404 Not Found` | `meta.profileSlug` specified a profile that does not exist. |
| `422 Unprocessable Entity` | Document is structurally valid but semantically invalid (e.g., slot out of grid bounds). |

### Example: curl

```bash
curl -X POST https://your-landfall-server/api/layout/apply \
  -H "Authorization: Bearer lf_key_your_api_key_here" \
  -H "Content-Type: application/yaml" \
  --data-binary @research-layout.yaml
```

---

## Using apply_layout from the Agent SDK

### From a YAML string

```dart
import 'package:landfall_agent_sdk/landfall_agent_sdk.dart';

final client = LandfallClient(
  serverUrl: 'https://your-landfall-server',
  apiKey: 'lf_key_your_api_key_here',
);

const layoutYaml = '''
version: "1.0"
meta:
  profileSlug: "work-focus"
cards:
  - source: "system.clock"
    slot: { column: 0, row: 0, columnSpan: 3, rowSpan: 2 }
    locked: true
  - source: "system.calendar"
    slot: { column: 0, row: 2, columnSpan: 3, rowSpan: 6 }
    displayConfig:
      daysAhead: 3
      maxEvents: 5
  - source: "system.photos"
    visible: false
  - source: "agent.feed"
    slot: { column: 3, row: 0, columnSpan: 9, rowSpan: 8 }
''';

final result = await client.applyLayout(LayoutDraft.fromYaml(layoutYaml));
print('Applied ${result.appliedCards} cards to ${result.profileSlug}');
```

### Builder API

For programmatic layout construction without a YAML string:

```dart
final result = await client.applyLayout(
  LayoutDraft.build()
    .profile('work-focus')
    .card(
      'system.clock',
      slot: SlotDraft(column: 0, row: 0, columnSpan: 3, rowSpan: 2),
      locked: true,
      displayConfig: {'showSeconds': false, 'showDate': true},
    )
    .card(
      'system.calendar',
      slot: SlotDraft(column: 0, row: 2, columnSpan: 3, rowSpan: 6),
      displayConfig: {'daysAhead': 3, 'maxEvents': 5},
    )
    .hideCard('system.photos')
    .card(
      'agent.feed',
      slot: SlotDraft(column: 3, row: 0, columnSpan: 9, rowSpan: 8),
    ),
);
```

### SDK method reference

#### `LayoutDraft.fromYaml(String yaml)`

Parses a YAML string into a `LayoutDraft`. Throws `LayoutParseException` if the YAML is malformed or the schema version is not recognized.

#### `LayoutDraft.fromJson(Map<String, dynamic> json)`

Parses a JSON map into a `LayoutDraft`.

#### `LayoutDraft.build()`

Returns a `LayoutDraftBuilder` for the fluent builder API.

#### `LayoutDraftBuilder.profile(String slug)`

Specifies the target profile by slug. If not called, the layout is applied to the active profile.

#### `LayoutDraftBuilder.card(String source, {SlotDraft? slot, bool? visible, bool? locked, String? mood, Map<String, dynamic>? displayConfig})`

Adds a card entry to the layout. All parameters except `source` are optional; unspecified parameters preserve the card's current state.

#### `LayoutDraftBuilder.hideCard(String source)`

Convenience method. Equivalent to `.card(source, visible: false)`.

#### `LayoutDraftBuilder.showCard(String source)`

Convenience method. Equivalent to `.card(source, visible: true)`.

#### `LandfallClient.applyLayout(LayoutDraft draft)`

Sends the layout draft to the server. Returns a `LayoutResult`. Throws `LandfallApiException` on HTTP errors; throws `LayoutValidationException` if the server returns a 400 with validation errors.

---

## Using apply_layout from the MCP Server

Landfall exposes three MCP tools for display configuration:

### `apply_layout`

Applies a LayoutSchema document to the display.

```
apply_layout(layout_yaml: string) -> LayoutResult
```

**Parameters:**

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `layout_yaml` | string | yes | A valid LayoutSchema document in YAML format. |

**Returns:**

```json
{
  "ok": true,
  "profileSlug": "work-focus",
  "appliedCards": 4,
  "message": "Layout applied to profile 'work-focus'."
}
```

**Example MCP invocation (Claude Desktop):**

When building an automation in Claude Desktop that reconfigures the display for a research session:

```
Use the apply_layout tool with the following YAML to switch to a research-optimized layout:

version: "1.0"
meta:
  profileSlug: "work-focus"
cards:
  - source: "system.clock"
    slot: { column: 0, row: 0, columnSpan: 2, rowSpan: 1 }
  - source: "agent.feed"
    slot: { column: 2, row: 0, columnSpan: 10, rowSpan: 8 }
  - source: "system.photos"
    visible: false
  - source: "system.weather.current"
    visible: false
  - source: "system.weather.forecast"
    visible: false
```

### `apply_theme`

Applies a theme to the active profile by slug.

```
apply_theme(theme_slug: string, profile_slug?: string) -> ThemeResult
```

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `theme_slug` | string | yes | The slug of an imported or marketplace theme. |
| `profile_slug` | string | no | If omitted, applies to the active profile. |

### `switch_profile`

Switches the active profile.

```
switch_profile(profile_slug: string) -> ProfileResult
```

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `profile_slug` | string | yes | The slug of the profile to activate. |

---

## Combining Layout and Theme

Layout and theme are separate concerns but can be applied in sequence in the same agent workflow. A common pattern: switch profile (which may already have a linked theme), then apply a layout override for the specific session context.

### REST API sequence

```bash
# 1. Switch to the party profile (automatically applies its linked theme)
curl -X POST https://your-landfall-server/api/profile/switch \
  -H "Authorization: Bearer lf_key_..." \
  -H "Content-Type: application/json" \
  -d '{"profileSlug": "party"}'

# 2. Apply a layout override — photos full-screen, hide calendar and work agent cards
curl -X POST https://your-landfall-server/api/layout/apply \
  -H "Authorization: Bearer lf_key_..." \
  -H "Content-Type: application/yaml" \
  --data-binary @party-layout.yaml
```

### Agent SDK sequence

```dart
// Switch profile (applies its linked theme automatically)
await client.switchProfile('party');

// Apply layout on top
await client.applyLayout(
  LayoutDraft.build()
    .profile('party')
    .card('system.photos',
      slot: SlotDraft(column: 0, row: 0, columnSpan: 12, rowSpan: 8),
      visible: true,
      displayConfig: {'intervalSeconds': 15, 'randomOrder': true},
    )
    .hideCard('system.calendar')
    .hideCard('agent.feed'),
);
```

### Order of operations

When a profile is switched:
1. The profile's layout is applied (card positions and visibility from the stored layout)
2. The profile's linked theme is applied (if the profile has a `themeId`)
3. A display refresh event is emitted

When `apply_layout` is called:
1. The specified card configs are updated
2. A display refresh event is emitted
3. The profile's theme is not changed

When `apply_theme` is called:
1. The profile's `themeId` is updated
2. A display refresh event is emitted
3. Card positions are not changed

The display processes refresh events sequentially. Calling `switchProfile`, `applyLayout`, and `applyTheme` in rapid succession will each trigger a refresh; for performance, group them in a single `apply_layout` call that also specifies the profile, and separately call `apply_theme` only if you need a different theme than the profile's default.

---

## Complete Examples

Six annotated layout files — one for each seed profile. These are the layouts that ship with Landfall on a fresh install. They can be re-applied to restore a profile to its seed state.

### Morning Routine

Clock prominent, weather, calendar. Good for checking the day at a glance while getting ready.

```yaml
version: "1.0"
meta:
  name: "Morning Routine — Seed Layout"
  profileSlug: "morning-routine"

grid:
  columns: 12
  rows: 8

cards:
  # Clock: large, top-left, prominent
  - source: "system.clock"
    slot: { column: 0, row: 0, columnSpan: 5, rowSpan: 3 }
    visible: true
    locked: true
    displayConfig:
      showSeconds: false
      showDate: true
      showDayOfWeek: true
      variant: large

  # Current weather: below the clock
  - source: "system.weather.current"
    slot: { column: 0, row: 3, columnSpan: 5, rowSpan: 2 }
    visible: true
    displayConfig:
      units: imperial
      showFeelsLike: true
      showWind: false

  # Forecast strip: bottom-left
  - source: "system.weather.forecast"
    slot: { column: 0, row: 5, columnSpan: 5, rowSpan: 3 }
    visible: true
    displayConfig:
      days: 5
      showHighLow: true

  # Calendar: right side, full height
  - source: "system.calendar"
    slot: { column: 5, row: 0, columnSpan: 5, rowSpan: 8 }
    visible: true
    displayConfig:
      daysAhead: 7
      maxEvents: 10
      showTime: true
      showCalendarColor: true

  # Agent feed: far right, narrow
  - source: "agent.feed"
    slot: { column: 10, row: 0, columnSpan: 2, rowSpan: 8 }
    visible: true
    displayConfig:
      cardSpacing: compact

  # Photos: hidden during morning routine
  - source: "system.photos"
    visible: false
```

---

### Work Focus

Minimal. Calendar and clock only. Agent feed hidden — no distractions.

```yaml
version: "1.0"
meta:
  name: "Work Focus — Seed Layout"
  profileSlug: "work-focus"

grid:
  columns: 12
  rows: 8

cards:
  # Clock: compact, top-left
  - source: "system.clock"
    slot: { column: 0, row: 0, columnSpan: 3, rowSpan: 2 }
    visible: true
    locked: true
    displayConfig:
      showSeconds: false
      showDate: true
      showDayOfWeek: false
      variant: compact

  # Calendar: large, takes most of the screen
  - source: "system.calendar"
    slot: { column: 0, row: 2, columnSpan: 6, rowSpan: 6 }
    visible: true
    displayConfig:
      daysAhead: 14
      maxEvents: 12
      showTime: true
      showCalendarColor: true

  # Agent feed: hidden. ProfileCardFilter.showAgentCards is false on this profile.
  - source: "agent.feed"
    visible: false

  # Weather: hidden during focus mode
  - source: "system.weather.current"
    visible: false

  - source: "system.weather.forecast"
    visible: false

  # Photos: hidden during focus mode
  - source: "system.photos"
    visible: false
```

---

### Family Evening

Clock, photos as the hero, calendar visible for reference. Agent feed on.

```yaml
version: "1.0"
meta:
  name: "Family Evening — Seed Layout"
  profileSlug: "family-evening"

grid:
  columns: 12
  rows: 8

cards:
  # Photos: hero element, most of the screen
  - source: "system.photos"
    slot: { column: 0, row: 0, columnSpan: 8, rowSpan: 6 }
    visible: true
    displayConfig:
      intervalSeconds: 20
      transition: crossfade
      fit: cover
      randomOrder: true

  # Clock: top-right
  - source: "system.clock"
    slot: { column: 8, row: 0, columnSpan: 4, rowSpan: 2 }
    visible: true
    displayConfig:
      showSeconds: false
      showDate: true
      showDayOfWeek: true

  # Calendar: right side, below clock
  - source: "system.calendar"
    slot: { column: 8, row: 2, columnSpan: 4, rowSpan: 6 }
    visible: true
    displayConfig:
      daysAhead: 3
      maxEvents: 6
      showTime: true

  # Current weather: bottom-left, below photos
  - source: "system.weather.current"
    slot: { column: 0, row: 6, columnSpan: 4, rowSpan: 2 }
    visible: true
    displayConfig:
      variant: minimal
      units: imperial

  # Agent feed: bottom-center strip
  - source: "agent.feed"
    slot: { column: 4, row: 6, columnSpan: 4, rowSpan: 2 }
    visible: true
    displayConfig:
      cardSpacing: compact
      maxCards: 4
```

---

### Party

Photos full-screen. Calendar and work content hidden. Agent feed filtered by profile (celebratory + success only) and shown in a corner.

```yaml
version: "1.0"
meta:
  name: "Party — Seed Layout"
  profileSlug: "party"

grid:
  columns: 12
  rows: 8

cards:
  # Photos: full screen. The whole display is the slideshow.
  - source: "system.photos"
    slot: { column: 0, row: 0, columnSpan: 10, rowSpan: 8 }
    visible: true
    displayConfig:
      intervalSeconds: 10
      transition: slide
      transitionDurationMs: 600
      fit: cover
      randomOrder: true

  # Clock: small, far right, unobtrusive
  - source: "system.clock"
    slot: { column: 10, row: 0, columnSpan: 2, rowSpan: 1 }
    visible: true
    displayConfig:
      showSeconds: false
      showDate: false
      variant: compact

  # Agent feed: small panel, bottom-right. Profile filter limits to celebratory + success.
  - source: "agent.feed"
    slot: { column: 10, row: 1, columnSpan: 2, rowSpan: 7 }
    visible: true
    displayConfig:
      maxCards: 5
      showTimestamp: false
      cardSpacing: compact

  # Calendar: hidden. Not appropriate for party context.
  - source: "system.calendar"
    visible: false

  - source: "system.weather.current"
    visible: false

  - source: "system.weather.forecast"
    visible: false
```

---

### Night Watch

Clock only. Maximum size. Everything else hidden.

```yaml
version: "1.0"
meta:
  name: "Night Watch — Seed Layout"
  profileSlug: "night-watch"

grid:
  columns: 12
  rows: 8

cards:
  # Clock: full screen. This is the entire display.
  - source: "system.clock"
    slot: { column: 0, row: 0, columnSpan: 12, rowSpan: 8 }
    visible: true
    locked: true
    displayConfig:
      showSeconds: true
      showDate: true
      showDayOfWeek: false
      variant: large

  - source: "system.weather.current"
    visible: false

  - source: "system.weather.forecast"
    visible: false

  - source: "system.calendar"
    visible: false

  - source: "system.photos"
    visible: false

  - source: "agent.feed"
    visible: false
```

---

### Kids Mode

Photos and clock. Agent feed filtered by profile (curated sources only). Calendar hidden.

```yaml
version: "1.0"
meta:
  name: "Kids Mode — Seed Layout"
  profileSlug: "kids-mode"

grid:
  columns: 12
  rows: 8

cards:
  # Photos: large hero
  - source: "system.photos"
    slot: { column: 0, row: 0, columnSpan: 9, rowSpan: 8 }
    visible: true
    displayConfig:
      intervalSeconds: 15
      transition: crossfade
      fit: cover
      randomOrder: true
      showCaption: false

  # Clock: right side, comfortable size
  - source: "system.clock"
    slot: { column: 9, row: 0, columnSpan: 3, rowSpan: 3 }
    visible: true
    displayConfig:
      showSeconds: false
      showDate: false
      variant: large

  # Agent feed: small, right side, bottom. Profile filter limits to safe sources.
  - source: "agent.feed"
    slot: { column: 9, row: 3, columnSpan: 3, rowSpan: 5 }
    visible: true
    displayConfig:
      maxCards: 3
      showTimestamp: false

  - source: "system.calendar"
    visible: false

  - source: "system.weather.current"
    visible: false

  - source: "system.weather.forecast"
    visible: false
```

---

*LayoutSchema v1.0 — April 2026*
*Maintained by the Landfall project. Submit corrections and additions via GitHub issue or PR.*
