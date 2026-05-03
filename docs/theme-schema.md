# Landfall ThemeSchema — Open Specification v1.0

> This is the authoritative reference for Landfall theme authors, agent integrations, and the marketplace validation pipeline. If you are building a theme, start with [Creating Your First Theme](#creating-your-first-theme). If you are building a tool that generates or validates themes, start with [Theme File Format](#theme-file-format) and [Full Token Reference](#full-token-reference).

---

## Table of Contents

1. [Overview](#overview)
2. [Design Principles](#design-principles)
3. [Theme File Format](#theme-file-format)
4. [Five-Layer Structure](#five-layer-structure)
5. [Full Token Reference](#full-token-reference)
6. [Safe Zones](#safe-zones)
7. [Landfall Font Registry](#landfall-font-registry)
8. [Card Mood Rendering](#card-mood-rendering)
9. [Versioning and Compatibility](#versioning-and-compatibility)
10. [Creating Your First Theme](#creating-your-first-theme)
11. [Import and Distribution](#import-and-distribution)
12. [Marketplace Submission Guide](#marketplace-submission-guide)
13. [Full Annotated Example](#full-annotated-example)

---

## Overview

### What Landfall themes are

A Landfall theme is a structured document that defines the complete visual language of a Landfall display. It controls background treatment, card appearance, typography, animation style, and how semantic card states (urgent, celebratory, success, muted) are rendered visually.

Themes are applied to named dashboard profiles. A profile can have one linked theme; the display renders all cards using that theme's token values. Switching profiles can therefore switch both layout and visual language simultaneously — a "Party" profile might activate a vibrant, high-energy theme while a "Focus" profile uses a minimal, low-distraction one.

Themes are expressed as design tokens: named, typed decisions that the Landfall renderer maps to concrete visual properties at render time. You are not writing CSS or directly specifying widget styles. You are expressing intent — "the accent color is this blue", "cards have rounded corners", "urgent content should pulse" — and the renderer resolves that intent into pixels appropriate for the display's physical resolution and platform.

### What Landfall themes are not

- **Themes are not layout tools.** Card positions, grid dimensions, and which cards are visible are controlled by `LayoutSchema`, not ThemeSchema. A theme defines how the display looks; a layout defines what appears where.
- **Themes are not a CSS superset.** You cannot target specific widgets by selector, override margin and padding on individual elements, or inject arbitrary style values. The token vocabulary is intentionally constrained to prevent themes from breaking usability.
- **Themes are not per-card.** Tokens apply uniformly across the entire display. Per-card visual overrides (via `CardMood`) use the theme's mood token set, not card-specific style values.

### How themes relate to profiles and agent output

A profile links to one theme via `themeId`. When no theme is linked, the display uses the app's built-in default dark theme.

Agents push cards with a `mood` field (`urgent`, `celebratory`, `success`, `muted`, or `normal`). The active theme determines how each mood renders — border color, fill, animation, scale. Agents express *what kind of result this is*; the theme expresses *how that looks*. This separation means agent integrations are theme-agnostic by design.

---

## Design Principles

These principles explain why the schema is shaped the way it is. Understanding them helps you make good token choices and avoid the failure modes the constraints are designed to prevent.

### 1. Every token has a type and a range

`card.radius: 12` is valid. `card.radius: "2em"` is not. Every token in this schema is typed (hex, rgba, float, enum, int) and range-bounded where applicable. This makes validation deterministic: valid token values always produce a renderable display. The renderer never encounters input it cannot handle.

When a value is out of range, the schema validator rejects the theme entirely before it reaches the renderer. This is intentional — a half-valid theme that silently clips values is harder to reason about than one that fails loudly at import time.

### 2. Relative values over absolute where it matters

`typography.scale: comfortable` is better than `typography.baseFontSize: 18`. The Landfall renderer applies the scale multiplier against the display's physical resolution at render time. A "comfortable" scale on a 1080p Fire TV produces appropriately-sized text at TV viewing distance; the same theme applied to a 4K display scales up proportionally. Theme authors express intent; the renderer resolves to pixels.

This also applies to animation speed. `animation.speed: fast` means 150ms regardless of device. You do not need to calibrate timing to specific hardware.

### 3. Derived values reduce boilerplate

Several tokens can be automatically derived from other tokens if not explicitly set:

- `color.accentMuted` defaults to `color.accent` at 0.2 alpha
- `color.agent.border` defaults to `color.accent` at 0.3 alpha
- `color.divider` defaults to `color.text.primary` at 0.1 alpha

This means a minimal theme only needs to specify the tokens it cares about. A theme that sets `color.accent: "#FF6B35"` will get a coherent muted accent and agent border automatically, unless it overrides them.

### 4. Mood token defaults must always be legible

If a theme does not define `mood.urgent.*` tokens, the renderer falls back to base theme defaults (red border, subtle fill, pulse animation). This guarantee is load-bearing: no theme can accidentally produce an invisible urgent card. The fallback is always visible, always high-contrast, always distinguishable from a normal card.

This is why the mood section is optional but its defaults are not negotiable. If you define mood tokens, define them with sufficient contrast. The marketplace validation pipeline checks contrast ratios for mood tokens.

### 5. The schema is versioned; tokens are never removed

`version: "1.0"` is a required field in every theme file. New tokens added in minor versions (1.1, 1.2) have documented defaults — old themes at 1.0 remain fully valid. Tokens are deprecated before removal; no token disappears without at least one major version of advance notice and an automated migration path.

---

## Theme File Format

Themes are YAML or JSON files. YAML is preferred for human-authored themes because it supports comments and is more readable at the length a full theme document typically reaches. JSON is preferred for agent-generated and tool-generated themes.

Both formats are accepted at import time. The server stores themes as JSONB internally; the original format is not preserved.

### Required fields

```yaml
version: "1.0"
meta:
  name: "My Theme"
```

Every other field is optional. An empty theme (only `version` and `meta.name`) is valid and applies the built-in defaults for every token.

### File structure

```
version        string    required    Schema version. Must be "1.0".
meta           object    required
  name         string    required    Display name. Max 60 characters.
  author       string    optional    Author handle or name.
  description  string    optional    One or two sentences. Max 200 characters.
  previewUrl   string    optional    URL to a 1920×1080 PNG preview image.
  tags         array     optional    String tags for marketplace filtering.
  license      string    optional    SPDX license identifier or "proprietary".

surface        object    optional    Background and card container tokens.
typography     object    optional    Font and text tokens.
color          object    optional    Color palette tokens.
animation      object    optional    Transition and motion tokens.
moods          object    optional    Per-mood visual treatment tokens.
```

### Validation rules

- `version` must be exactly the string `"1.0"` (or a later declared version).
- Token values must conform to the types and ranges in the Full Token Reference.
- Color values specified as `hex` must be 3 or 6 digit hex strings with a leading `#`.
- Color values specified as `rgba` must be in the form `rgba(r, g, b, a)` where r/g/b are 0–255 and a is 0.0–1.0. Shorthand `rgb()` without alpha is not accepted where rgba is expected.
- Float values are decimal numbers. Integer values must not include a decimal point.
- Enum values are case-sensitive and must exactly match the documented options.
- `background.value` interpretation depends on `background.type` — see the Surface token reference for details.

---

## Five-Layer Structure

The token vocabulary is organized into five layers. Each layer has a distinct scope and rationale for existing as a separate concern.

### Layer 1: Surface

Controls the display background and card container treatment. These tokens have the highest visual impact — they define the display's dominant character before any card content is considered.

Background and card tokens are separated rather than merged because they need different constraints. Background tokens control what is behind the cards (and can reference images or gradients in Pro). Card tokens control the containers that sit on top and must always maintain legibility regardless of the background choice.

### Layer 2: Typography

Controls font family, text weight, letter spacing, and scale. Typography is a strong identity signal for themes — "JetBrains Mono on a dark background" reads as technical; "Playfair Display" reads as editorial. The token set is intentionally narrow: it is not possible to set different fonts for different card types (except the clock, which has a dedicated override), and it is not possible to set arbitrary pixel sizes.

The `timeDisplay` override exists because clock typography has special requirements. A clock widget displaying `11:47 PM` benefits from a different rhythm and weight than body text — often thinner, more spaced, more architectural. Giving the clock its own font family without opening up arbitrary per-widget overrides is the right compromise.

### Layer 3: Color

Controls the accent color, text hierarchy colors, semantic status colors, and the agent card border. Color tokens interact with each other through the derived value system — setting `color.accent` influences the automatic defaults for `color.accentMuted` and `color.agent.border`.

The color layer does not include card background or border colors — those are in `surface.card.*` — because the distinction between "brand color" and "container color" matters. Card fill is a neutral container treatment; accent is an interactive and highlight color. They serve different purposes and are changed for different reasons.

### Layer 4: Animation

Controls how content transitions, how cards enter the grid, and the ghost ticker scroll speed. Animation tokens are the most subjective layer — what feels "right" is highly personal. The options are deliberately coarse (fast/normal/relaxed rather than millisecond values) to prevent themes from encoding overly specific animation timing that may feel wrong on different hardware.

Setting `animation.transition: instant` and `animation.cardEntry: none` produces a completely static display — appropriate for themes designed for maximum legibility or minimum distraction.

### Layer 5: Card Mood Rendering

Controls how the five semantic card states (`urgent`, `celebratory`, `success`, `muted`, `normal`) look in this theme. This layer is where themes become active participants in the agent integration story — an agent pushes `mood: "urgent"`, and this theme decides what urgency looks like.

Normal mood cards use the base card surface tokens (`surface.card.*`) without modification. The four other moods each have their own border color, fill color, optional pulse, optional animation, scale, and opacity tokens.

---

## Full Token Reference

### `surface`

#### `surface.background`

| Token | Type | Options / Range | Default | Notes |
|---|---|---|---|---|
| `background.type` | enum | `solid \| gradient \| image \| blur` | `solid` | `image` requires Pro license on the display. `blur` applies a blur to the video/live feed behind the app, if available. |
| `background.value` | string | type-dependent | `"#0D0D0F"` | For `solid`: 3 or 6-digit hex. For `gradient`: JSON array of stop objects (see below). For `image`: absolute HTTPS URL to a static image. For `blur`: integer string representing blur radius in px, e.g. `"20"`. |
| `background.overlay` | rgba | any rgba | `null` | An optional color layer drawn on top of `image` and `gradient` backgrounds. Use to ensure card legibility over busy images. Has no effect when `type` is `solid`. |

**Gradient stop format** (for `background.type: gradient`):
```json
[
  { "color": "#1a1a2e", "stop": 0.0 },
  { "color": "#16213e", "stop": 0.5 },
  { "color": "#0f3460", "stop": 1.0 }
]
```
Stops must be in ascending order from 0.0 to 1.0. At least 2 stops required. Max 8 stops. The gradient direction is fixed at 135° (top-left to bottom-right). Direction is not a configurable token.

#### `surface.card`

| Token | Type | Options / Range | Default | Notes |
|---|---|---|---|---|
| `card.fill` | rgba | any rgba | `rgba(255,255,255,0.05)` | Card body background. Low alpha values work well over dark backgrounds; higher alpha values produce more opaque cards that work better over image backgrounds. |
| `card.border.color` | rgba | any rgba | `rgba(255,255,255,0.1)` | Card border color. Set alpha to 0 to effectively disable the border without setting `border.style: none`. |
| `card.border.width` | float | 0.0–3.0 | `1.0` | Border width in dp. |
| `card.border.style` | enum | `solid \| dashed \| none` | `solid` | `none` ignores `border.color` and `border.width`. |
| `card.radius` | int | 0–24 | `8` | Corner radius in dp. 0 = square corners. 24 = fully pill-shaped at small card heights. |
| `card.blur` | int | 0–20 | `0` | Backdrop blur in px applied behind the card fill. Creates a frosted glass effect over the background. Performance cost increases with value; values above 12 may affect frame rate on lower-powered hardware. |
| `card.shadow` | enum | `none \| subtle \| medium \| strong` | `none` | Drop shadow beneath cards. Particularly useful when `card.fill` alpha is very low and card edges need definition. |

---

### `typography`

| Token | Type | Options / Range | Default | Notes |
|---|---|---|---|---|
| `fontFamily` | string | Landfall font registry name | `"System"` | Must exactly match a name from the [Landfall Font Registry](#landfall-font-registry). Invalid names fall back to `"System"` with a validation warning (not a hard error). |
| `scale` | enum | `compact \| comfortable \| display` | `comfortable` | `compact` reduces all text sizes by ~15%; `display` increases by ~20%. Applied as a multiplier at render time against the display's base resolution. |
| `heading.weight` | int | 300–800 | `600` | Must be a multiple of 100. Applied to card titles and section headers. |
| `body.weight` | int | 300–600 | `400` | Must be a multiple of 100. Applied to card body text, event lists, and secondary content. |
| `letterSpacing` | enum | `tight \| normal \| wide` | `normal` | `tight` = -0.5px at base scale; `normal` = 0; `wide` = +1.0px at base scale. |
| `timeDisplay.fontFamily` | string | Landfall font registry name | inherits `fontFamily` | Clock widget font family override. The clock widget renders the time string using this font. If not set, inherits the base `fontFamily`. |
| `timeDisplay.weight` | int | 100–900 | `200` | Clock widget font weight. Defaults to 200 (thin) because thin weights create stronger visual rhythm in time displays. Must be a multiple of 100. |

---

### `color`

| Token | Type | Default | Derived from | Notes |
|---|---|---|---|---|
| `accent` | hex | `#4A9EFF` | — | Primary interactive and highlight color. Used for selected states, active indicators, and key data points. |
| `accentMuted` | rgba | derived | `accent` at 0.2 alpha | Softer version of accent. Used for backgrounds of accent-colored interactive elements. Set explicitly to override derivation. |
| `text.primary` | hex | `#FFFFFF` | — | Primary text color. Applied to card titles, time display, and most prominent text. |
| `text.secondary` | rgba | `rgba(255,255,255,0.6)` | — | Supporting text. Applied to card subtitles, event times, and secondary data. |
| `text.tertiary` | rgba | `rgba(255,255,255,0.35)` | — | Caption-level text. Applied to source labels, timestamps, and least-prominent text. |
| `divider` | rgba | derived | `text.primary` at 0.1 alpha | Separator color used between list items and in grid lines. |
| `agent.border` | rgba | derived | `accent` at 0.3 alpha | Border color for agent-pushed cards. Visually distinguishes agent content from system cards. |
| `success` | hex | `#34C759` | — | Positive semantic color. Used in success mood rendering defaults and in system status indicators. |
| `warning` | hex | `#FF9F0A` | — | Warning semantic color. Used in system status indicators. Not currently used in mood rendering (no `warning` mood exists). |
| `alert` | hex | `#FF3B30` | — | Error and alert semantic color. Used in urgent mood rendering defaults and system error states. |

**Color contrast guidance:** At TV viewing distances (8–12 feet), contrast ratios that feel fine on a monitor at arm's length can become unreadable. Aim for a contrast ratio of at least 4.5:1 between `text.primary` and the effective card background (accounting for `card.fill` composited over `background.value`). The marketplace validation pipeline runs automated contrast checks against this target.

---

### `animation`

| Token | Type | Options | Default | Notes |
|---|---|---|---|---|
| `transition` | enum | `instant \| fade \| slide \| scale` | `fade` | How content within a card transitions when its data refreshes. `instant` = no animation. `fade` = cross-fade. `slide` = content slides up as new content arrives. `scale` = brief scale pop on refresh. |
| `speed` | enum | `fast \| normal \| relaxed` | `normal` | Animation duration multiplier. `fast` = 150ms, `normal` = 300ms, `relaxed` = 500ms. Applies to all transitions and card entry animations. |
| `cardEntry` | enum | `fade \| slide \| scale \| none` | `fade` | How new cards enter the grid when a card becomes visible or a layout change occurs. `none` = instant appearance. |
| `tickerScroll` | enum | `slow \| normal \| fast` | `normal` | Scroll speed for the ghost ticker strip at the bottom of the display. Slower values give more time to read long messages; faster values maintain a sense of activity. |

Setting both `transition: instant` and `cardEntry: none` produces a fully static display. This is appropriate for themes optimized for maximum legibility or environments where motion is unwanted.

---

### `moods`

The moods section defines how semantic card states look in this theme. Every token within each mood block is optional — unset tokens fall back to the documented defaults below. You do not need to define a complete mood block; defining only `urgent.borderColor` while leaving everything else unset is valid.

`normal` mood uses the base card surface tokens (`surface.card.*`) without modification. It has no mood token block.

#### `moods.urgent`

Applied to cards pushed with `mood: "urgent"`. Represents content that requires attention, is time-sensitive, or indicates a problem state.

| Token | Type | Default | Notes |
|---|---|---|---|
| `urgent.borderColor` | rgba | `rgba(255,59,48,0.8)` | Strong, high-alpha red. Should be immediately distinguishable from normal card borders. |
| `urgent.fillColor` | rgba | `rgba(255,59,48,0.1)` | Subtle tint over the card background. Enough to color the card without obscuring content. |
| `urgent.pulse` | bool | `true` | When true, the card border animates with a slow pulse (fade in/out, 2-second cycle). |
| `urgent.scale` | float | `1.01` | 0.95–1.10. Cards rendered at this scale relative to their slot. Small scale increases draw the eye without disrupting the layout. |
| `urgent.animation` | enum | `pulse \| none` | `pulse` triggers the border pulse described above. `none` disables all mood-specific animation. |

#### `moods.celebratory`

Applied to cards pushed with `mood: "celebratory"`. Represents high-energy positive content: milestones, events, achievements.

| Token | Type | Default | Notes |
|---|---|---|---|
| `celebratory.borderColor` | rgba | `rgba(52,199,89,0.6)` | Bright green. Distinct from success to allow different intensities of positive signal. |
| `celebratory.fillColor` | rgba | `rgba(52,199,89,0.08)` | Very subtle green tint. |
| `celebratory.pulse` | bool | `false` | |
| `celebratory.scale` | float | `1.0` | 0.95–1.10. |
| `celebratory.animation` | enum | `glow \| confetti \| scale \| none` | `glow` = animated outer glow on the card border. `confetti` = brief particle burst on card entry (does not repeat). `scale` = brief scale bounce on entry. |

#### `moods.success`

Applied to cards pushed with `mood: "success"`. Represents positive outcomes, completed goals, good news. Lower intensity than celebratory.

| Token | Type | Default | Notes |
|---|---|---|---|
| `success.borderColor` | rgba | `rgba(52,199,89,0.5)` | Slightly lower alpha than celebratory. Visually similar but less insistent. |
| `success.fillColor` | rgba | `rgba(52,199,89,0.06)` | |
| `success.pulse` | bool | `false` | |
| `success.scale` | float | `1.0` | |
| `success.animation` | enum | `none` | No entry animation by default. Success is good news, but not an event. |

#### `moods.muted`

Applied to cards pushed with `mood: "muted"`. Represents low-priority, informational, or background-awareness content.

| Token | Type | Default | Notes |
|---|---|---|---|
| `muted.borderColor` | rgba | inherits `card.border.color` | Muted cards do not need a distinct border. |
| `muted.fillColor` | rgba | inherits `card.fill` | |
| `muted.pulse` | bool | `false` | |
| `muted.scale` | float | `1.0` | |
| `muted.animation` | enum | `none` | |
| `muted.opacity` | float | `0.5` | 0.3–0.8. The primary visual treatment for muted cards. Reduced opacity signals low importance without hiding the content entirely. |

**Opacity note:** `muted.opacity` applies to the entire card widget, not just the fill. Text, borders, and content are all rendered at this opacity. Do not set below 0.3 — content below that threshold becomes unreadable at TV viewing distances.

---

## Safe Zones

The following elements are excluded from the theme schema by design. They always render using hardcoded system styles that themes cannot reach.

| Element | Why it is protected |
|---|---|
| Settings access button (the gear pill on the display surface) | A theme that hides or obscures this would make settings unreachable without external intervention. The display must always have a way to change its own configuration. |
| Error and offline state indicators | When the server is unreachable or a data source fails, the error state must be legible regardless of background color or card fill. Error states use system colors, not theme tokens. |
| Card dismissal controls | Users must always be able to dismiss a card. A theme that makes dismiss controls invisible or blends them into the background removes user agency over their display. |
| First-run wizard and auth screens | Onboarding and authentication flows are shown before a theme is applied. They use the app's built-in styles. |
| Theme import and validation UI | The screen used to import a new theme must not be themed by that theme — that would create a bootstrap paradox where a broken theme hides the UI used to fix it. |
| System status indicators (memory, network, sync) | Status indicators in the settings screen and system overlay use hardcoded styles. |

Safe zone elements are rendered by Flutter widgets that are not under the `ThemeCubit`'s scope. They receive `ThemeData` from a separate provider that is always the built-in app theme. This is a structural guarantee, not a convention — it is not possible to accidentally theme a safe zone element without modifying the widget tree.

---

## Landfall Font Registry

All fonts listed below are bundled in the Landfall app binary at build time. They do not require a network request at render time. Using a font name not in this registry produces a validation warning (not an error) and falls back to `"System"`.

Fonts are selected for three criteria: TV-distance legibility (characters must be distinct at 8+ feet), stylistic range (the registry should cover minimal through expressive), and license compatibility (all fonts are licensed under the Open Font License).

### Sans-Serif

| Name | Character | Best for |
|---|---|---|
| `System` | Platform sans-serif (Roboto on Android, SF Pro on iOS) | Universal fallback. Maximally legible. Least distinctive. |
| `Inter` | Humanist sans. Optimized for screen readability. | General-purpose. Clean, unobtrusive. Works for everything. |
| `DM Sans` | Geometric sans. Friendly and open. | Modern, approachable themes. Good for family dashboards. |
| `Outfit` | Contemporary geometric. Slightly playful. | Clean and minimal with a hint of personality. |
| `Space Grotesk` | Monospace-influenced sans. Technical feel, but warm. | Technical themes that want legibility over terminal aesthetics. |
| `Lexend` | Specifically designed to reduce visual stress. | Themes optimized for legibility. Good for always-on displays. |
| `Syne` | Display sans. Strong personality. | Bold headers on artistic or editorial themes. Use for `heading.weight` only if using for the time display. |

### Serif

| Name | Character | Best for |
|---|---|---|
| `Playfair Display` | High-contrast serif. Elegant and editorial. | Themes with a print or magazine aesthetic. Works best at larger scales. |
| `Lora` | Low-contrast serif. Warm and readable. | Calendar and text-heavy cards. The most readable serif at small sizes. |

### Monospace

| Name | Character | Best for |
|---|---|---|
| `JetBrains Mono` | Developer monospace. Highly legible, designed for code. | Technical/hacker themes. Strong pairing with `Space Grotesk` for body. |
| `Space Mono` | Retro monospace. Strong terminal/typewriter character. | Themes going for a retro-computing or terminal aesthetic. |

### Display / Specialty

| Name | Character | Best for |
|---|---|---|
| `Orbitron` | Geometric, sci-fi. Each character is architecturally distinct. | Clock widgets (`timeDisplay.fontFamily`). Not recommended for body text. |
| `Bebas Neue` | Condensed uppercase display. High-impact. | Large headlines. Not suitable for body text — no lowercase. |
| `Righteous` | Rounded retro. Playful energy. | Party, entertainment, or casual themes. |

### Requesting new fonts

To request a font for inclusion in the registry, open an issue on the Landfall GitHub repository with the tag `font-request`. Include: the font name, a link to its Google Fonts or repository page, a description of what stylistic gap it fills, and at least one example theme concept that benefits from it.

Font additions are released in minor version increments (e.g., registry v1.1). Once added, fonts are never removed — only deprecated with a mapping to the closest stylistic equivalent. Deprecated fonts continue to render correctly; they simply do not appear in the registry listing for new themes.

---

## Card Mood Rendering

### The principle: agents declare what, themes declare how

When an agent pushes a card with `mood: "urgent"`, it is expressing a semantic fact about that content: this is time-sensitive and requires attention. The agent does not know what color scheme the display is using, what time of day it is, or what profile is active. It should not need to.

The active theme's `moods` tokens translate semantic state into visual appearance. An "urgent" card on the Neon Arcade theme has a hot pink border. The same card on a minimal monochrome theme has a crisp white border. Both convey urgency; each does it in the vocabulary of its visual context.

This separation has a practical consequence: agent integrations are theme-agnostic by design. An integration built with the default dark theme will look correct on every well-formed theme, without modification.

### Fallback chain

If a theme does not define mood tokens, or defines only some tokens for a mood, the fallback chain is:

1. Theme-defined token value
2. Base theme default for that token (documented above in the Full Token Reference moods section)
3. Base card style (`surface.card.*`) — used only for `borderColor` and `fillColor` when even the base defaults are somehow unavailable

The fallback is resolved server-side when the theme is validated and stored. The Flutter client receives a fully-resolved token set — it never needs to compute defaults.

### Normal mood

Normal mood cards render using base card surface tokens exclusively. There is no `moods.normal` block. If you want to style normal cards differently from agent cards, use `color.agent.border` to give agent-pushed normal-mood cards a distinct border while keeping their fill identical to system cards.

### Mood and profile card filters

Profile card filters can include a `agentMoodAllowlist` — a set of moods that are permitted to appear in that profile's agent feed. Cards with moods not in the allowlist are not fetched from the server at all. This filtering is evaluated server-side before the theme renders anything.

Party Mode with `agentMoodAllowlist: [celebratory, success]` means only good news reaches the display. The theme's `moods.celebratory` and `moods.success` tokens do all the visual work; the profile filter does the content curation.

---

## Versioning and Compatibility

### Version field

Every theme file must declare its schema version:

```yaml
version: "1.0"
```

The version is validated at import time. If the version is not recognized, the import is rejected with a clear error.

### Minor versions (1.x)

Minor versions add new optional tokens with documented defaults. Old themes at 1.0 remain valid when new tokens are added in 1.1 — the renderer applies the defaults for any missing tokens. Theme authors do not need to update their theme files when a minor version is released unless they want to use the new tokens.

Examples of minor-version additions: new font registry entries, a new animation option, a new card shadow option.

### Major versions (2.0+)

Major versions may rename, merge, or restructure tokens. A major version release includes:

1. A full migration guide documenting every breaking change
2. An automated converter that upgrades a 1.x theme file to 2.0 format
3. A deprecation period during which both versions are valid
4. Marketplace themes are converted to the new major version at import time

No token disappears in a major version without appearing in the deprecation list in a prior minor version first. A deprecated token continues to function for one full major version lifecycle before removal.

### Theme schema version vs theme version

The `version` field in a theme file refers to the ThemeSchema version the theme was authored against. This is not the same as the theme's own version (which would be relevant if you publish a `v1.2` of your theme to the marketplace). Authors using a marketplace-published theme get the latest version of that theme; the ThemeSchema version the theme was authored with is tracked separately.

---

## Creating Your First Theme

This section walks you through authoring a complete theme from scratch. By the end you will have a valid, importable theme that expresses a coherent visual concept.

### Before you start

Pick a concept. The best themes have a clear identity that you can state in a sentence: "dark green terminal", "warm editorial like a quality magazine", "ultra-minimal, almost nothing", "vibrant and high-contrast for a party". This sentence will guide every token decision.

For this walkthrough, the concept is: **"Deep Blue — calm, focused, slightly cool. Good for a work context."**

### Step 1: Create the file

Create a file named `deep-blue.yaml`.

```yaml
version: "1.0"
meta:
  name: "Deep Blue"
  author: "yourhandle"
  description: "Calm and focused. Cool navy palette with a cyan accent."
  tags: [dark, minimal, focus, blue]
```

This is already a valid theme. Import it and you will see the default styles — but with your metadata attached.

### Step 2: Set the background

The background is the dominant visual. For Deep Blue, we want a very dark navy — not pure black, which would read as "default", but a desaturated blue-black that establishes the palette.

```yaml
surface:
  background:
    type: solid
    value: "#080C14"
```

### Step 3: Style the cards

Cards sit on top of the background. With a very dark background, we want cards to be barely visible as containers — just enough surface definition to group their content, not enough to compete with it.

```yaml
surface:
  background:
    type: solid
    value: "#080C14"
  card:
    fill: "rgba(255, 255, 255, 0.04)"
    border:
      color: "rgba(100, 160, 220, 0.2)"
      width: 1.0
      style: solid
    radius: 6
    blur: 0
    shadow: none
```

The card border uses a slightly blue-tinted white rather than a neutral white. This keeps the palette coherent — even the structural chrome has a blue cast.

### Step 4: Choose typography

For a focus theme, `Inter` at `comfortable` scale is the right call. Legible, professional, no personality that competes with the content.

```yaml
typography:
  fontFamily: "Inter"
  scale: comfortable
  heading:
    weight: 600
  body:
    weight: 400
  letterSpacing: normal
  timeDisplay:
    fontFamily: "Orbitron"
    weight: 200
```

The clock gets `Orbitron` because the geometric, architectural character of `Orbitron` works well for time display. The thin weight (`200`) creates a sense of precision.

### Step 5: Set the color palette

With the background established, the accent color is the most important decision. For Deep Blue, a bright cyan sits naturally over the dark navy.

```yaml
color:
  accent: "#38BDF8"
  text:
    primary: "#E2EFF9"
    secondary: "rgba(226, 239, 249, 0.6)"
    tertiary: "rgba(226, 239, 249, 0.35)"
  success: "#4ADE80"
  warning: "#FBBF24"
  alert: "#F87171"
```

`text.primary` is not pure white — it's a very slightly blue-tinted near-white (`#E2EFF9`). This keeps the typography inside the palette rather than sitting outside it.

We are not setting `accentMuted`, `divider`, or `agent.border` because the defaults derived from `accent` will be coherent.

### Step 6: Set animation

For a focus theme, animation should be minimal. Content transitions should not distract.

```yaml
animation:
  transition: fade
  speed: normal
  cardEntry: fade
  tickerScroll: slow
```

### Step 7: Define mood rendering

For a focus-oriented theme, urgency should be clear but not alarming. We will override the defaults to make urgent cards more reserved — still visible, but not jarring.

```yaml
moods:
  urgent:
    borderColor: "rgba(248, 113, 113, 0.7)"
    fillColor: "rgba(248, 113, 113, 0.08)"
    pulse: true
    scale: 1.005
    animation: pulse
  celebratory:
    borderColor: "rgba(74, 222, 128, 0.6)"
    fillColor: "rgba(74, 222, 128, 0.07)"
    animation: glow
  success:
    borderColor: "rgba(74, 222, 128, 0.45)"
    fillColor: "rgba(74, 222, 128, 0.05)"
  muted:
    opacity: 0.45
```

### Step 8: Import and test

Save the file and import it via Settings > Themes > Import from file. Apply it to a profile and observe the display.

Things to check:
- Is text legible at arms's length? Step back and squint. Body text that requires squinting will be unreadable at TV viewing distance.
- Do card boundaries feel right? If the grid looks undefined (cards blending into background), increase `card.border.color` alpha slightly.
- Do urgent cards stand out? Push a test card with `mood: urgent` (see the integration guide for how to do this with curl) and verify it reads as different from normal cards.
- Does the clock feel like it belongs? If `Orbitron` feels too aggressive, switch `timeDisplay.fontFamily` to `"Inter"` and compare.

### Your completed theme

```yaml
version: "1.0"
meta:
  name: "Deep Blue"
  author: "yourhandle"
  description: "Calm and focused. Cool navy palette with a cyan accent."
  tags: [dark, minimal, focus, blue]

surface:
  background:
    type: solid
    value: "#080C14"
  card:
    fill: "rgba(255, 255, 255, 0.04)"
    border:
      color: "rgba(100, 160, 220, 0.2)"
      width: 1.0
      style: solid
    radius: 6
    blur: 0
    shadow: none

typography:
  fontFamily: "Inter"
  scale: comfortable
  heading:
    weight: 600
  body:
    weight: 400
  letterSpacing: normal
  timeDisplay:
    fontFamily: "Orbitron"
    weight: 200

color:
  accent: "#38BDF8"
  text:
    primary: "#E2EFF9"
    secondary: "rgba(226, 239, 249, 0.6)"
    tertiary: "rgba(226, 239, 249, 0.35)"
  success: "#4ADE80"
  warning: "#FBBF24"
  alert: "#F87171"

animation:
  transition: fade
  speed: normal
  cardEntry: fade
  tickerScroll: slow

moods:
  urgent:
    borderColor: "rgba(248, 113, 113, 0.7)"
    fillColor: "rgba(248, 113, 113, 0.08)"
    pulse: true
    scale: 1.005
    animation: pulse
  celebratory:
    borderColor: "rgba(74, 222, 128, 0.6)"
    fillColor: "rgba(74, 222, 128, 0.07)"
    animation: glow
  success:
    borderColor: "rgba(74, 222, 128, 0.45)"
    fillColor: "rgba(74, 222, 128, 0.05)"
  muted:
    opacity: 0.45
```

---

## Import and Distribution

### Import by URL

Any HTTPS URL pointing to a raw YAML or JSON theme file can be imported via Settings > Themes > Import from URL. The display fetches the document, validates it against the current schema version, and stores it locally.

The URL does not need to be hosted on the Landfall marketplace. GitHub raw URLs, personal sites, and any static file host work. The only requirement is HTTPS — HTTP URLs are not accepted.

On import, the server performs:
1. Fetch with a 10-second timeout
2. Content-type check (must be `text/yaml`, `application/yaml`, `text/plain`, or `application/json`)
3. Schema version validation
4. Token type and range validation for every specified token
5. Contrast ratio checks on text-over-background and mood border-over-card-fill combinations
6. Storage in the display's `themes` table

If any step fails, the import is rejected with specific error messages identifying the failing token(s). No partial imports — the theme either fully succeeds or fully fails.

### Import by file

Themes can be uploaded as `.yaml` or `.json` files via Settings > Themes > Import from file. Same validation pipeline as URL import. File size limit: 64 KB. Any theme file that requires more than 64 KB likely contains embedded data that belongs elsewhere.

### Via the marketplace

Marketplace themes are imported with a single tap from the theme browser. Purchased themes are linked to the display's account and re-downloadable after reinstall.

### CI preview pipeline

When you submit a theme to the marketplace via GitHub PR, the CI pipeline:
1. Validates the theme against the current JSON Schema
2. Renders a 1920×1080 PNG preview using a headless Flutter build with seed content (clock, weather card, calendar card, a sample agent card)
3. Renders the same preview with one card of each mood (urgent, celebratory, success, muted)
4. Attaches the preview images to the PR as comments

The preview images are what appear in the marketplace theme browser. The quality of your preview screenshot directly affects conversion. Use real-looking seed content if you are submitting a theme that is sensitive to content layout.

---

## Marketplace Submission Guide

### Who can submit

Anyone. Community themes are welcome. You do not need to be a Landfall contributor or have prior experience with the codebase.

### Free vs paid themes

Free themes are submitted via GitHub PR and appear in the marketplace at no charge. They are licensed under the Open Font License or similar permissive terms.

Paid themes ($3–15 one-time purchase) are submitted via a separate process (see the [theme marketplace onboarding form](https://landfall.dev/marketplace/submit)). Paid themes require a preview video in addition to static screenshots and go through a brief manual review for technical correctness (not aesthetic judgment). Revenue share: 70% to the author, 30% to Landfall.

### Submission checklist

Before opening a PR, confirm:

- [ ] `version` field is present and valid
- [ ] `meta.name` is present and under 60 characters
- [ ] `meta.description` is present and under 200 characters
- [ ] Theme file is under 64 KB
- [ ] All token values are within documented ranges
- [ ] Contrast ratio ≥ 4.5:1 between `text.primary` and effective card background
- [ ] Urgent mood is visually distinguishable from normal mood cards
- [ ] No `background.type: image` (image backgrounds require Pro; free-tier themes must not use them)
- [ ] Theme has been locally imported and visually tested on a real or simulated display

### PR process

1. Fork the `landfall` repository
2. Add your theme file to `packages/themes/community/<your-theme-slug>.yaml`
3. Open a PR with the title format: `[theme] Your Theme Name`
4. CI runs automatically: validation + preview rendering
5. If CI passes, your PR will be reviewed within 7 days
6. Review checks: technical correctness only. Aesthetic judgment is explicitly not performed. The community decides what is good.

### What gets rejected

- Token values out of documented ranges
- Contrast ratio below 4.5:1 on primary text
- `background.type: image` in a free-tier theme
- Theme file over 64 KB
- Themes that fail CI validation
- Themes that are byte-for-byte copies of existing themes

Rejection is not permanent. Fix the listed issues and re-push; CI re-runs automatically.

### Licensing

Community themes in this repository are licensed under MIT unless explicitly stated otherwise in the theme file's `meta.license` field. Themes with a `proprietary` license are not accepted into the community registry — they belong in the paid marketplace tier.

---

## Full Annotated Example

A complete production-quality theme with every token documented inline. This is the "Neon Arcade" theme from the architecture reference, annotated for clarity.

```yaml
# ThemeSchema version. Required. Do not change unless migrating to a new major version.
version: "1.0"

meta:
  name: "Neon Arcade"
  author: "landfall"
  description: "High-contrast neon on deep black. High energy. Good for entertainment contexts."
  # previewUrl points to a 1920×1080 PNG. This is shown in the theme browser.
  previewUrl: "https://themes.landfall.dev/previews/neon-arcade.png"
  tags: [vibrant, dark, gaming, entertainment, neon]
  license: "MIT"

surface:
  background:
    # solid: background.value is a hex color
    type: solid
    # Near-black with a very slight blue cast — not pure #000000
    value: "#050508"
  card:
    # Very low alpha: cards are barely visible as containers.
    # This works because the neon borders provide definition.
    fill: "rgba(255, 255, 255, 0.04)"
    border:
      # Cyan-green neon at 30% alpha. Bright enough to define cards, not overwhelming.
      color: "rgba(0, 255, 180, 0.3)"
      # 1.5dp: slightly thicker than default to ensure the neon color reads on small cards
      width: 1.5
      style: solid
    # Sharp corners. Neon aesthetic doesn't do rounded corners.
    radius: 4
    # No blur — blur softens neon edges and fights the aesthetic
    blur: 0
    # No shadow — the border is doing the depth work
    shadow: none

typography:
  # JetBrains Mono: legible monospace with strong technical character
  fontFamily: "JetBrains Mono"
  # compact: slightly smaller text keeps the information density high
  scale: compact
  heading:
    # Bold headings for strong contrast with body text
    weight: 700
  body:
    # Standard weight for monospace at TV viewing distance
    weight: 400
  # Wide letter spacing complements the monospace font
  letterSpacing: wide
  timeDisplay:
    # Orbitron for the clock: geometric, sci-fi, maximally distinct from body text
    fontFamily: "Orbitron"
    # thin weight — architectural, precise
    weight: 200

color:
  # Bright cyan-green: the signature neon color
  accent: "#00FFB4"
  # accentMuted is not set: auto-derived as rgba(0,255,180,0.2)
  text:
    # Near-white with a very slight cyan tint
    primary: "#E8FFF9"
    # Secondary at 70% alpha of the primary
    secondary: "rgba(0, 255, 180, 0.7)"
    # Tertiary: much lower opacity, nearly invisible — labels only
    tertiary: "rgba(255, 255, 255, 0.3)"
  # Cyan-tinted dividers keep the palette coherent
  divider: "rgba(0, 255, 180, 0.15)"
  agent:
    # Agent cards get a slightly brighter border to signal external origin
    border: "rgba(0, 255, 180, 0.4)"
  # Semantic colors in neon style
  success: "#00FF88"
  warning: "#FFB800"
  alert: "#FF3366"

animation:
  # Fade transitions feel right for neon — no jarring cuts
  transition: fade
  # Fast: the arcade aesthetic is responsive, not languid
  speed: fast
  # Cards scale in on entry — a quick pop that feels energetic
  cardEntry: scale
  # Ticker scrolls fast — information moves quickly in arcade mode
  tickerScroll: fast

moods:
  urgent:
    # Hot pink-red: distinct from the cyan accent, immediately alarming
    borderColor: "#FF3366"
    fillColor: "rgba(255, 51, 102, 0.12)"
    # Pulse is appropriate for urgent neon — it reads as "alert"
    pulse: true
    # Slight scale increase draws the eye
    scale: 1.02
    animation: pulse
  celebratory:
    # Bright green: the other major neon color after cyan
    borderColor: "#00FF88"
    fillColor: "rgba(0, 255, 136, 0.1)"
    pulse: false
    scale: 1.0
    # Glow: the neon glow animation is perfect for celebratory in this theme
    animation: glow
  success:
    # Same green family as celebratory but slightly lower intensity
    borderColor: "#00FF88"
    fillColor: "rgba(0, 255, 136, 0.08)"
    animation: none
  muted:
    # Muted cards at 45% opacity — present but not competing
    opacity: 0.45
```

---

## Era Concept Sketches

These sketches validate that the token vocabulary can express radically different aesthetic eras. Each is a complete, valid theme file — copy, modify, and import. The inline notes explain token choices in terms of the era's source material.

---

### Synthwave '84

Dark purple retro-futurism inspired by the neon-drenched artwork of modern synthwave artists and the cover aesthetics of 80s science fiction. Think FM-84, Timecop1983, and The Midnight. Deep violet backgrounds, electric cyan, coral-pink — the neon palette of a sunset highway that never actually existed.

```yaml
version: "1.0"

meta:
  name: "Synthwave '84"
  author: "landfall"
  description: "Deep purple retro-futurism. Electric cyan and coral neon on midnight violet. The neon highway at 2am."
  tags: [dark, neon, 80s, retro, synthwave]
  license: "MIT"

surface:
  background:
    type: solid
    # The deep purple-black of the original Synthwave '84 palette — not pure black,
    # not navy, but the specific violet-dark that reads as "after midnight."
    value: "#262335"
  card:
    # Nearly invisible fill — the neon borders define the cards, not the fill
    fill: "rgba(255, 255, 255, 0.03)"
    border:
      # Coral-pink neon: the secondary signature color of the synthwave palette
      color: "rgba(249, 126, 114, 0.4)"
      width: 1.5
      style: solid
    # No border radius — 80s geometry is flat and angular
    radius: 0
    blur: 0
    shadow: none

typography:
  # Monospace = terminal = the 80s computer. JetBrains Mono is clean enough for TV
  # distance without losing the technical character.
  fontFamily: "JetBrains Mono"
  scale: normal
  heading:
    weight: 700
  body:
    weight: 400
  # Wide letter spacing is essential — the neon palette needs breathing room
  letterSpacing: wide
  timeDisplay:
    # Orbitron was designed for exactly this: a geometric, science-fiction clock face
    fontFamily: "Orbitron"
    weight: 200

color:
  # Electric cyan: the defining synthwave color. There is no debate about this.
  accent: "#03edf9"
  text:
    primary: "#ffffff"
    secondary: "rgba(255, 255, 255, 0.75)"
    tertiary: "rgba(255, 255, 255, 0.38)"
  divider: "rgba(3, 237, 249, 0.18)"
  agent:
    # Hot pink for agent-pushed content — the other defining neon in the palette
    border: "rgba(255, 126, 219, 0.55)"
  success: "#72f1b8"    # Electric green
  warning: "#fede5d"    # Electric yellow — "road ahead" not "amber alert"
  alert: "#fe4450"      # Hot neon red

animation:
  transition: fade
  speed: normal
  # Scale-in on card entry: a quick pop that feels energetic
  cardEntry: scale
  tickerScroll: fast

moods:
  urgent:
    borderColor: "#fe4450"
    fillColor: "rgba(254, 68, 80, 0.12)"
    pulse: true
    scale: 1.02
    animation: pulse
  celebratory:
    # Yellow reads as a spotlight in neon — distinct from the cyan and coral
    borderColor: "#fede5d"
    fillColor: "rgba(254, 227, 93, 0.1)"
    pulse: false
    scale: 1.0
    animation: glow
  success:
    borderColor: "#72f1b8"
    fillColor: "rgba(114, 241, 184, 0.1)"
    animation: none
  muted:
    opacity: 0.4
```

---

### System Grey

The silver chrome of Windows 98 and Windows NT — a love letter to an era when the UI was the product, beveled edges were a design philosophy, and `#C0C0C0` was the default background color of everything. Light theme. Sharp corners. Instant transitions. No animations. This is how millions of people spent their 1990s.

```yaml
version: "1.0"

meta:
  name: "System Grey"
  author: "landfall"
  description: "The silver chrome of Windows 98. Interface nostalgia at 1920x1080. No rounded corners were harmed in the making of this theme."
  tags: [light, retro, 90s, windows, interface, minimal]
  license: "MIT"

surface:
  background:
    type: solid
    # The iconic Windows silver. Not a design choice — a cultural artifact.
    value: "#C0C0C0"
  card:
    # Cards read as raised window panels in the classic UI metaphor
    fill: "rgba(240, 240, 240, 0.92)"
    border:
      # Classic Windows recessed border: the midpoint grey that creates the bevel illusion
      color: "#808080"
      # 2dp border: thick enough to read as chrome, not just a line
      width: 2
      style: solid
    # Windows 98 had zero border radius. This is non-negotiable.
    radius: 0
    blur: 0
    shadow: subtle

typography:
  # Space Grotesk echoes the humanist sans-serif of 90s system fonts: readable,
  # slightly technical, no personality wasted
  fontFamily: "Space Grotesk"
  scale: comfortable
  heading:
    weight: 700
  body:
    weight: 400
  letterSpacing: normal
  timeDisplay:
    fontFamily: "Space Grotesk"
    weight: 300

color:
  # Navy blue: the active title bar. The defining accent of Windows before XP Luna.
  accent: "#000080"
  text:
    primary: "#000000"    # Pure black — system fonts were black on grey
    secondary: "#444444"
    tertiary: "#808080"   # The visual language for "disabled" in every 90s dialog box
  divider: "#808080"
  agent:
    border: "#000080"
  success: "#008000"      # Classic HTML green
  warning: "#808000"      # Olive — the Windows warning hue before amber became standard
  alert: "#FF0000"        # No alpha, no softening. It's an error dialog.

animation:
  # Windows 98 had no transitions. The window was there. Then it wasn't.
  transition: instant
  speed: fast
  cardEntry: none
  tickerScroll: normal

moods:
  urgent:
    borderColor: "#FF0000"
    fillColor: "rgba(255, 0, 0, 0.08)"
    pulse: false
    scale: 1.0
    # No animations — urgency here is the blunt color, not motion
    animation: none
  celebratory:
    borderColor: "#000080"
    fillColor: "rgba(0, 0, 128, 0.06)"
    pulse: false
    scale: 1.0
    animation: none
  success:
    borderColor: "#008000"
    fillColor: "rgba(0, 128, 0, 0.06)"
    animation: none
  muted:
    # Greyed out: the Windows visual language for "unavailable"
    opacity: 0.5
```

---

### Electroclash

Early 2000s dark electro: the aesthetic of Fischerspooner, Adult., Miss Kittin, and the first wave of DFA Records. Cold black, chrome silver, electric blue. The production was clinical and the art direction was sleek in a way that was very deliberately not warm. Flat, hard, industrial — but glossy. The albums looked like vaguely threatening corporate stationery and sounded like a malfunctioning supercomputer enjoying itself.

```yaml
version: "1.0"

meta:
  name: "Electroclash"
  author: "landfall"
  description: "Cold black and chrome silver. Early 2000s dark electro. Sleek, flat, and deliberately not warm."
  tags: [dark, minimal, 2000s, electro, chrome, cold]
  license: "MIT"

surface:
  background:
    type: solid
    # Near-black with a very slight blue cast — colder than pure black, more clinical
    value: "#0A0B12"
  card:
    fill: "rgba(200, 210, 255, 0.04)"
    border:
      # Chrome silver: the material language of 2000s hardware design —
      # every device had a brushed metal bezel
      color: "rgba(180, 190, 220, 0.25)"
      width: 1
      style: solid
    # Just slightly rounded — the 2000s weren't as sharp as the 80s, not as soft as the 2010s
    radius: 2
    blur: 0
    # Cards recede slightly rather than floating — cold themes push depth inward
    shadow: subtle

typography:
  # Outfit is geometric and clean: 2000s design rejected warm humanist type
  fontFamily: "Outfit"
  scale: compact
  heading:
    weight: 600
  body:
    # Light weight on dark reads as sleek and slightly cold — this is intentional
    weight: 300
  letterSpacing: wide
  timeDisplay:
    # Orbitron at heavier weight — the 2000s liked a heftier sci-fi clock
    fontFamily: "Orbitron"
    weight: 400

color:
  # Electric blue: the 2000s electro accent. Blue LEDs, progress bars, Winamp skins.
  accent: "#0088FF"
  text:
    primary: "#D8DCF0"              # Off-white with a slight blue cast — not warm
    secondary: "rgba(200, 210, 240, 0.65)"
    tertiary: "rgba(180, 190, 220, 0.35)"
  divider: "rgba(100, 120, 200, 0.15)"
  agent:
    # Agent cards get a brighter blue border — the only vivid color in the scheme
    border: "rgba(0, 136, 255, 0.45)"
  success: "#00AACC"    # Cyan-tinted success: not warm green but cold blue-green
  warning: "#8855FF"    # Violet for warning: 2000s design used purple where others used amber
  alert: "#FF2255"      # Hot pink-red: aggressive but within the cold palette

animation:
  # Slide transitions: the 2000s media player era — panels that arrived from the side
  transition: slide
  speed: fast
  cardEntry: slide
  tickerScroll: fast

moods:
  urgent:
    borderColor: "#FF2255"
    fillColor: "rgba(255, 34, 85, 0.1)"
    pulse: true
    scale: 1.01
    animation: pulse
  celebratory:
    # Violet: the 2000s celebratory hue — not red, not gold, but electric purple
    borderColor: "#AA44FF"
    fillColor: "rgba(170, 68, 255, 0.1)"
    pulse: false
    scale: 1.0
    animation: glow
  success:
    borderColor: "#00AACC"
    fillColor: "rgba(0, 170, 204, 0.08)"
    animation: none
  muted:
    # Deeper fade — cold themes bury muted content more aggressively
    opacity: 0.38
```

---

### Colorful Pop

Y2K maximalism: the visual language of Lisa Frank folders, Lizzie McGuire outfits, TRL countdowns, and the default Delia's catalog color story. Bubblegum pink, electric cyan, neon lime — every color present and accounted for, none of them neutral. Rounded everything. Drop shadows that prove you have depth. The design philosophy of the early 2000s was that more was more, and more was also not quite enough.

References: the Lizzie McGuire color palette (hot pink `#e63466`, cyan `#00d4ff`, deep purple `#6d397b`), Y2K web design's candy brights, and Lisa Frank's neon-on-pastel approach to contrast.

```yaml
version: "1.0"

meta:
  name: "Colorful Pop"
  author: "landfall"
  description: "Bubblegum pink, electric cyan, neon lime. Y2K maximalism — Lisa Frank, Lizzie McGuire, and TRL in one dashboard."
  tags: [light, candy, 2000s, y2k, pop, vibrant, maximalist]
  license: "MIT"

surface:
  background:
    type: solid
    # Pale bubblegum: almost white, but the faintest pink warmth establishes the
    # palette before a single card is drawn. The Y2K background was never neutral.
    value: "#FFF0F8"
  card:
    # Clean white panels — the saturated borders do the chromatic heavy lifting
    fill: "rgba(255, 255, 255, 0.88)"
    border:
      # Electric cyan: the complementary neon to the hot-pink accent family.
      # Reference: the `#00d4ff` in the Lizzie McGuire palette, every mid-2000s hyperlink,
      # the default color of every progress bar that ever loaded a Flash game.
      color: "rgba(0, 187, 255, 0.72)"
      # 2dp: thick enough to read as a color statement across a room
      width: 2
      style: solid
    # High border radius: the bubbly, pill-like geometry of Y2K UI design.
    # Rounded corners were a statement in the era of Win98's sharp rectangles.
    radius: 16
    blur: 0
    # The early 2000s loved drop shadows — they proved you had depth, and depth
    # was considered a design achievement
    shadow: medium

typography:
  # DM Sans: open, friendly, approachable. The closest font in the registry
  # to the rounded humanist type of early 2000s pop design — the Nickelodeon
  # logo font energy without the trademark.
  fontFamily: "DM Sans"
  scale: comfortable
  heading:
    weight: 700
  body:
    weight: 400
  letterSpacing: normal
  timeDisplay:
    # Righteous: rounded retro with exactly the playful energy of the era.
    # Think: the Nickelodeon clock, the TRL countdown, the Disney Channel bug.
    fontFamily: "Righteous"
    weight: 400

color:
  # Hot magenta: the era's most iconic single color. Spice Girls. Destiny's Child
  # music videos. Every third item in a Delia's catalog. The default hyperlink
  # before anyone had opinions about hyperlinks.
  accent: "#FF0099"
  text:
    # Deep purple-black rather than pure black: black reads as severe on this
    # palette. Purple-black keeps the warmth of the overall scheme.
    primary: "#220033"
    secondary: "#7B2D8B"    # Mid purple: warm, not corporate
    tertiary: "#C490D1"     # Soft lavender: timestamps, secondary labels
  divider: "rgba(255, 0, 153, 0.18)"
  agent:
    # Agent cards get the cyan border to distinguish origin while staying in palette
    border: "rgba(0, 187, 255, 0.78)"
  success: "#00CC44"    # Bright green: readable on the pale background, clearly positive
  warning: "#FF6600"    # Burnt orange: every early-web warning bar, every "your trial expires" notice
  alert: "#FF0044"      # Vivid red that harmonizes with the hot-pink accent family

animation:
  # Scale transitions: "pop-in" is the correct Y2K animation vocabulary.
  # Elements appeared. They did not fade — they arrived.
  transition: scale
  speed: fast
  cardEntry: scale
  tickerScroll: fast

moods:
  urgent:
    borderColor: "#FF0044"
    fillColor: "rgba(255, 0, 68, 0.08)"
    pulse: true
    scale: 1.03
    animation: pulse
  celebratory:
    # Confetti is literally what this theme was built for
    borderColor: "#FF0099"
    fillColor: "rgba(255, 0, 153, 0.08)"
    pulse: false
    scale: 1.02
    animation: confetti
  success:
    # Lime-adjacent green: reads as a bright celebration on this light palette
    borderColor: "#00CC44"
    fillColor: "rgba(0, 204, 68, 0.08)"
    animation: none
  muted:
    opacity: 0.45
```

---

*ThemeSchema v1.0 — April 2026*
*Maintained by the Landfall project. Submit corrections and additions via GitHub issue or PR.*
