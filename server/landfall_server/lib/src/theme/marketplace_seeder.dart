import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../generated/profile/dashboard_profile.dart';
import '../generated/theme/landfall_theme.dart';
import 'theme_validator.dart';

/// Seeds marketplace theme and companion profile demo data.
///
/// Safe to call repeatedly — already-present slugs are skipped (idempotent).
/// Intended for startup and CI/testing environments.
class MarketplaceSeeder {
  static Future<void> seed(Session session) async {
    await _seedThemes(session);
    await _seedCompanionProfiles(session);
  }

  // ── theme seeding ────────────────────────────────────────────────────────────

  static Future<void> _seedThemes(Session session) async {
    for (final def in _marketplaceThemes) {
      final existing = await LandfallTheme.db.findFirstRow(
        session,
        where: (t) => t.slug.equals(def['slug'] as String),
      );
      if (existing != null) continue;

      final result = ThemeValidator.validate(def['yaml'] as String);
      if (!result.isValid) {
        session.log(
          'Marketplace seed theme "${def['slug']}" failed validation: '
          '${result.errors.map((e) => e.message).join(', ')}',
          level: LogLevel.error,
        );
        continue;
      }

      final resolvedJson = jsonEncode(result.resolvedTokens);

      await LandfallTheme.db.insertRow(
        session,
        LandfallTheme(
          slug: def['slug'] as String,
          name: def['name'] as String,
          schemaVersion: '1.0',
          author: def['author'] as String?,
          description: def['description'] as String?,
          tagsJson: jsonEncode(def['tags'] ?? []),
          tokensJson: resolvedJson,
          resolvedJson: resolvedJson,
          isBuiltIn: false,
          isMarketplace: true,
          priceUsd: def['priceUsd'] as int?,
          stripeProductId: def['stripeProductId'] as String?,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }
  }

  // ── companion profile seeding ────────────────────────────────────────────────

  static Future<void> _seedCompanionProfiles(Session session) async {
    final themes = await LandfallTheme.db.find(
      session,
      where: (t) => t.isMarketplace.equals(true),
    );

    // Build a set of theme slugs that already have a companion profile.
    final profiles = await DashboardProfile.db.find(session);
    final existingSlugs = profiles
        .map((p) => p.themeId)
        .whereType<String>()
        .toSet();

    var sortOrder = profiles.isEmpty
        ? 10
        : (profiles.map((p) => p.sortOrder).reduce((a, b) => a > b ? a : b) +
            10);

    for (final theme in themes) {
      if (existingSlugs.contains(theme.slug)) continue;

      await DashboardProfile.db.insertRow(
        session,
        DashboardProfile(
          name: theme.name,
          slug: _toProfileSlug(theme.slug),
          themeId: theme.slug,
          cardsJson: '[]',
          createdAt: DateTime.now().toUtc(),
          sortOrder: sortOrder,
        ),
      );
      sortOrder += 10;
    }
  }

  static String _toProfileSlug(String themeSlug) => 'companion-$themeSlug';

  // ── theme definitions ────────────────────────────────────────────────────────

  // Free themes (priceUsd: null = free).
  // Paid themes (priceUsd in cents, stripeProductId placeholder).

  static const _marketplaceThemes = [
    // ── Free themes ─────────────────────────────────────────────────────────

    {
      'slug': 'synthwave-84',
      'name': 'Synthwave \'84',
      'author': 'landfall',
      'description': '80s retro: hot magenta and cyan on deep violet-black. '
          'Grid lines, neon glows, total nostalgia.',
      'tags': ['dark', 'retro', '80s', 'neon', 'gaming'],
      'priceUsd': null,
      'stripeProductId': null,
      'yaml': '''
version: "1.0"
meta:
  name: "Synthwave '84"
  author: "landfall"
  description: "80s retro: hot magenta and cyan on deep violet-black."
  tags: [dark, retro, 80s, neon, gaming]
surface:
  background:
    type: solid
    value: "#0D0221"
  card:
    fill: "rgba(255,255,255,0.04)"
    border:
      color: "rgba(255,26,230,0.35)"
      width: 1.0
      style: solid
    radius: 2
    blur: 0
    shadow: none
typography:
  fontFamily: "JetBrains Mono"
  scale: compact
  heading:
    weight: 700
  body:
    weight: 400
  letterSpacing: wide
  timeDisplay:
    fontFamily: "Orbitron"
    weight: 200
color:
  accent: "#FF1AE6"
  text:
    primary: "#F0E6FF"
    secondary: "rgba(240,230,255,0.65)"
    tertiary: "rgba(240,230,255,0.35)"
  divider: "rgba(255,26,230,0.2)"
  agent:
    border: "rgba(0,255,255,0.35)"
  success: "#00FF88"
  warning: "#FFD600"
  alert: "#FF3B30"
animation:
  transition: fade
  speed: fast
  cardEntry: scale
  tickerScroll: fast
moods:
  urgent:
    borderColor: "rgba(255,59,48,0.9)"
    fillColor: "rgba(255,59,48,0.1)"
    pulse: true
    scale: 1.02
    animation: pulse
  celebratory:
    borderColor: "rgba(255,26,230,0.8)"
    fillColor: "rgba(255,26,230,0.08)"
    animation: glow
  muted:
    opacity: 0.45
''',
    },
    {
      'slug': 'system-grey',
      'name': 'System Grey',
      'author': 'landfall',
      'description': '90s interface: Win98 grey, compact UI, pixel-sharp borders. '
          'Built for nostalgia and readability.',
      'tags': ['light', 'retro', '90s', 'compact', 'minimal'],
      'priceUsd': null,
      'stripeProductId': null,
      'yaml': '''
version: "1.0"
meta:
  name: "System Grey"
  author: "landfall"
  description: "90s interface: Win98 grey, compact UI, pixel-sharp borders."
  tags: [light, retro, 90s, compact, minimal]
surface:
  background:
    type: solid
    value: "#C0C0C0"
  card:
    fill: "rgba(192,192,192,0.9)"
    border:
      color: "rgba(0,0,0,0.6)"
      width: 2.0
      style: solid
    radius: 0
    blur: 0
    shadow: medium
typography:
  fontFamily: "System"
  scale: compact
  heading:
    weight: 700
  body:
    weight: 400
  letterSpacing: normal
  timeDisplay:
    fontFamily: "System"
    weight: 700
color:
  accent: "#000080"
  text:
    primary: "#000000"
    secondary: "rgba(0,0,0,0.65)"
    tertiary: "rgba(0,0,0,0.4)"
  success: "#008000"
  warning: "#FF8C00"
  alert: "#FF0000"
animation:
  transition: instant
  speed: fast
  cardEntry: none
  tickerScroll: normal
moods:
  urgent:
    borderColor: "rgba(255,0,0,0.9)"
    fillColor: "rgba(255,0,0,0.1)"
    pulse: true
    scale: 1.01
    animation: pulse
  muted:
    opacity: 0.5
''',
    },
    {
      'slug': 'electroclash',
      'name': 'Electroclash',
      'author': 'landfall',
      'description': '2000s dark electro: electric blue on near-black. '
          'Minimal, digital, late-night energy.',
      'tags': ['dark', '2000s', 'electro', 'blue', 'minimal'],
      'priceUsd': null,
      'stripeProductId': null,
      'yaml': '''
version: "1.0"
meta:
  name: "Electroclash"
  author: "landfall"
  description: "2000s dark electro: electric blue on near-black."
  tags: [dark, 2000s, electro, blue, minimal]
surface:
  background:
    type: solid
    value: "#080A10"
  card:
    fill: "rgba(0,120,255,0.05)"
    border:
      color: "rgba(0,120,255,0.25)"
      width: 1.0
      style: solid
    radius: 2
    blur: 0
    shadow: none
typography:
  fontFamily: "Inter"
  scale: compact
  heading:
    weight: 600
  body:
    weight: 400
  letterSpacing: wide
  timeDisplay:
    fontFamily: "Orbitron"
    weight: 200
color:
  accent: "#0078FF"
  text:
    primary: "#C8D8FF"
    secondary: "rgba(200,216,255,0.6)"
    tertiary: "rgba(200,216,255,0.32)"
  divider: "rgba(0,120,255,0.18)"
  success: "#00C896"
  warning: "#FF9800"
  alert: "#FF2D55"
animation:
  transition: fade
  speed: fast
  cardEntry: fade
  tickerScroll: fast
moods:
  urgent:
    borderColor: "rgba(255,45,85,0.8)"
    fillColor: "rgba(255,45,85,0.08)"
    pulse: true
    scale: 1.01
    animation: pulse
  muted:
    opacity: 0.45
''',
    },
    {
      'slug': 'colorful-pop',
      'name': 'Colorful Pop',
      'author': 'landfall',
      'description': 'Y2K maximalism: bold primaries, bubblegum pastels, '
          'high energy. Every card its own party.',
      'tags': ['light', 'colorful', 'y2k', 'playful', 'vivid'],
      'priceUsd': null,
      'stripeProductId': null,
      'yaml': '''
version: "1.0"
meta:
  name: "Colorful Pop"
  author: "landfall"
  description: "Y2K maximalism: bold primaries, bubblegum pastels, high energy."
  tags: [light, colorful, y2k, playful, vivid]
surface:
  background:
    type: solid
    value: "#FFF0F5"
  card:
    fill: "rgba(255,255,255,0.85)"
    border:
      color: "rgba(255,20,147,0.4)"
      width: 2.0
      style: solid
    radius: 16
    blur: 0
    shadow: medium
typography:
  fontFamily: "System"
  scale: comfortable
  heading:
    weight: 700
  body:
    weight: 400
  letterSpacing: normal
  timeDisplay:
    fontFamily: "System"
    weight: 700
color:
  accent: "#FF1493"
  text:
    primary: "#1A0030"
    secondary: "rgba(26,0,48,0.65)"
    tertiary: "rgba(26,0,48,0.38)"
  success: "#00C853"
  warning: "#FF6D00"
  alert: "#D50000"
animation:
  transition: scale
  speed: normal
  cardEntry: scale
  tickerScroll: normal
moods:
  celebratory:
    borderColor: "rgba(255,20,147,0.8)"
    fillColor: "rgba(255,20,147,0.08)"
    animation: confetti
  muted:
    opacity: 0.5
''',
    },
    {
      'slug': 'midnight-rose',
      'name': 'Midnight Rose',
      'author': 'landfall',
      'description': 'Deep crimson rose on near-black. Moody, warm, '
          'and dramatic without shouting.',
      'tags': ['dark', 'warm', 'rose', 'moody', 'minimal'],
      'priceUsd': null,
      'stripeProductId': null,
      'yaml': '''
version: "1.0"
meta:
  name: "Midnight Rose"
  author: "landfall"
  description: "Deep crimson rose on near-black. Moody, warm, and dramatic."
  tags: [dark, warm, rose, moody, minimal]
surface:
  background:
    type: solid
    value: "#0F0608"
  card:
    fill: "rgba(180,30,60,0.06)"
    border:
      color: "rgba(180,30,60,0.22)"
      width: 1.0
      style: solid
    radius: 6
    blur: 0
    shadow: none
typography:
  fontFamily: "Lora"
  scale: comfortable
  heading:
    weight: 700
  body:
    weight: 400
  letterSpacing: normal
  timeDisplay:
    fontFamily: "Playfair Display"
    weight: 300
color:
  accent: "#E0204A"
  text:
    primary: "#FFE8EE"
    secondary: "rgba(255,232,238,0.62)"
    tertiary: "rgba(255,232,238,0.35)"
  divider: "rgba(224,32,74,0.18)"
  success: "#4ADE80"
  warning: "#FBBF24"
  alert: "#FF3B30"
animation:
  transition: fade
  speed: relaxed
  cardEntry: fade
  tickerScroll: slow
moods:
  urgent:
    borderColor: "rgba(255,59,48,0.75)"
    fillColor: "rgba(255,59,48,0.07)"
    pulse: true
    scale: 1.005
    animation: pulse
  celebratory:
    borderColor: "rgba(224,32,74,0.7)"
    fillColor: "rgba(224,32,74,0.07)"
    animation: glow
  muted:
    opacity: 0.45
''',
    },

    // ── Paid themes ──────────────────────────────────────────────────────────

    {
      'slug': 'aurora-borealis',
      'name': 'Aurora Borealis',
      'author': 'landfall',
      'description': 'Sweeping teal and violet aurora gradients on deep space black. '
          'Premium hand-tuned palette.',
      'tags': ['dark', 'premium', 'aurora', 'vivid', 'nature'],
      'priceUsd': 499,
      'stripeProductId': 'prod_seed_aurora_borealis',
      'yaml': '''
version: "1.0"
meta:
  name: "Aurora Borealis"
  author: "landfall"
  description: "Sweeping teal and violet aurora gradients on deep space black."
  tags: [dark, premium, aurora, vivid, nature]
surface:
  background:
    type: solid
    value: "#030810"
  card:
    fill: "rgba(0,210,180,0.05)"
    border:
      color: "rgba(0,210,180,0.28)"
      width: 1.0
      style: solid
    radius: 10
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
  accent: "#00D2B4"
  text:
    primary: "#D8FFF8"
    secondary: "rgba(216,255,248,0.62)"
    tertiary: "rgba(216,255,248,0.35)"
  divider: "rgba(0,210,180,0.15)"
  agent:
    border: "rgba(150,80,255,0.38)"
  success: "#00E676"
  warning: "#FFAB40"
  alert: "#FF5252"
animation:
  transition: fade
  speed: relaxed
  cardEntry: fade
  tickerScroll: slow
moods:
  urgent:
    borderColor: "rgba(255,82,82,0.75)"
    fillColor: "rgba(255,82,82,0.08)"
    pulse: true
    scale: 1.005
    animation: pulse
  celebratory:
    borderColor: "rgba(0,210,180,0.7)"
    fillColor: "rgba(0,210,180,0.07)"
    animation: glow
  muted:
    opacity: 0.45
''',
    },
    {
      'slug': 'carbon-fiber',
      'name': 'Carbon Fiber',
      'author': 'landfall',
      'description': 'Industrial-dark monochrome with precision grid lines. '
          'Technical, no-nonsense, built for data.',
      'tags': ['dark', 'premium', 'industrial', 'monochrome', 'technical'],
      'priceUsd': 299,
      'stripeProductId': 'prod_seed_carbon_fiber',
      'yaml': '''
version: "1.0"
meta:
  name: "Carbon Fiber"
  author: "landfall"
  description: "Industrial-dark monochrome with precision grid lines."
  tags: [dark, premium, industrial, monochrome, technical]
surface:
  background:
    type: solid
    value: "#0A0A0A"
  card:
    fill: "rgba(255,255,255,0.03)"
    border:
      color: "rgba(255,255,255,0.12)"
      width: 1.0
      style: solid
    radius: 2
    blur: 0
    shadow: none
typography:
  fontFamily: "JetBrains Mono"
  scale: compact
  heading:
    weight: 700
  body:
    weight: 400
  letterSpacing: normal
  timeDisplay:
    fontFamily: "JetBrains Mono"
    weight: 300
color:
  accent: "#E0E0E0"
  text:
    primary: "#EEEEEE"
    secondary: "rgba(238,238,238,0.55)"
    tertiary: "rgba(238,238,238,0.3)"
  success: "#66BB6A"
  warning: "#FFA726"
  alert: "#EF5350"
animation:
  transition: instant
  speed: fast
  cardEntry: none
  tickerScroll: normal
moods:
  urgent:
    borderColor: "rgba(239,83,80,0.8)"
    fillColor: "rgba(239,83,80,0.08)"
    pulse: true
    scale: 1.01
    animation: pulse
  muted:
    opacity: 0.4
''',
    },
    {
      'slug': 'solar-flare',
      'name': 'Solar Flare',
      'author': 'landfall',
      'description': 'Warm amber and deep space black. Sun-baked warmth '
          'meets cosmic depth. Premium palette.',
      'tags': ['dark', 'premium', 'warm', 'amber', 'space'],
      'priceUsd': 399,
      'stripeProductId': 'prod_seed_solar_flare',
      'yaml': '''
version: "1.0"
meta:
  name: "Solar Flare"
  author: "landfall"
  description: "Warm amber and deep space black. Sun-baked warmth meets cosmic depth."
  tags: [dark, premium, warm, amber, space]
surface:
  background:
    type: solid
    value: "#0C0800"
  card:
    fill: "rgba(255,160,0,0.05)"
    border:
      color: "rgba(255,160,0,0.22)"
      width: 1.0
      style: solid
    radius: 8
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
  accent: "#FFA000"
  text:
    primary: "#FFF8E1"
    secondary: "rgba(255,248,225,0.62)"
    tertiary: "rgba(255,248,225,0.35)"
  divider: "rgba(255,160,0,0.18)"
  success: "#69F0AE"
  warning: "#FF6F00"
  alert: "#FF3D00"
animation:
  transition: fade
  speed: normal
  cardEntry: fade
  tickerScroll: normal
moods:
  urgent:
    borderColor: "rgba(255,61,0,0.8)"
    fillColor: "rgba(255,61,0,0.08)"
    pulse: true
    scale: 1.01
    animation: pulse
  celebratory:
    borderColor: "rgba(255,160,0,0.75)"
    fillColor: "rgba(255,160,0,0.07)"
    animation: glow
  muted:
    opacity: 0.45
''',
    },
  ];
}
