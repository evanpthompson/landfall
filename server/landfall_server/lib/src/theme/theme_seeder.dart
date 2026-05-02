import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../generated/theme/landfall_theme.dart';
import 'theme_validator.dart';

/// Seeds the 5 built-in themes into the database on server startup.
///
/// Existing built-in rows are upserted (slug is the unique key) so the seeder
/// is safe to call repeatedly. User-imported themes are never touched.
class ThemeSeeder {
  static Future<void> seed(Session session) async {
    for (final def in _builtInThemes) {
      final existing = await LandfallTheme.db.findFirstRow(
        session,
        where: (t) => t.slug.equals(def['slug'] as String),
      );
      if (existing != null) continue;

      final result = ThemeValidator.validate(def['yaml'] as String);
      if (!result.isValid) {
        session.log(
          'Built-in theme "${def['slug']}" failed validation: '
          '${result.errors.map((e) => e.message).join(', ')}',
          level: LogLevel.error,
        );
        continue;
      }

      final raw = ThemeValidator.validate(def['yaml'] as String);
      final tokensJson = jsonEncode(raw.resolvedTokens);

      await LandfallTheme.db.insertRow(
        session,
        LandfallTheme(
          slug: def['slug'] as String,
          name: def['name'] as String,
          schemaVersion: '1.0',
          author: def['author'] as String?,
          description: def['description'] as String?,
          tagsJson: jsonEncode(def['tags'] ?? []),
          tokensJson: tokensJson,
          resolvedJson: tokensJson,
          isBuiltIn: true,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }
  }

  static const _builtInThemes = [
    {
      'slug': 'default-dark',
      'name': 'Default Dark',
      'author': 'landfall',
      'description': 'Clean dark theme. The default for all new displays.',
      'tags': ['dark', 'minimal', 'default'],
      'yaml': '''
version: "1.0"
meta:
  name: "Default Dark"
  author: "landfall"
  description: "Clean dark theme. The default for all new displays."
  tags: [dark, minimal, default]
surface:
  background:
    type: solid
    value: "#0D0D0F"
  card:
    fill: "rgba(255,255,255,0.05)"
    border:
      color: "rgba(255,255,255,0.1)"
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
  accent: "#4A9EFF"
  text:
    primary: "#FFFFFF"
    secondary: "rgba(255,255,255,0.6)"
    tertiary: "rgba(255,255,255,0.35)"
  success: "#34C759"
  warning: "#FF9F0A"
  alert: "#FF3B30"
animation:
  transition: fade
  speed: normal
  cardEntry: fade
  tickerScroll: normal
''',
    },
    {
      'slug': 'default-light',
      'name': 'Default Light',
      'author': 'landfall',
      'description': 'Clean light theme for bright environments.',
      'tags': ['light', 'minimal', 'default'],
      'yaml': '''
version: "1.0"
meta:
  name: "Default Light"
  author: "landfall"
  description: "Clean light theme for bright environments."
  tags: [light, minimal, default]
surface:
  background:
    type: solid
    value: "#F5F5F7"
  card:
    fill: "rgba(0,0,0,0.04)"
    border:
      color: "rgba(0,0,0,0.1)"
      width: 1.0
      style: solid
    radius: 8
    blur: 0
    shadow: subtle
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
  accent: "#007AFF"
  text:
    primary: "#1C1C1E"
    secondary: "rgba(28,28,30,0.6)"
    tertiary: "rgba(28,28,30,0.35)"
  success: "#34C759"
  warning: "#FF9F0A"
  alert: "#FF3B30"
animation:
  transition: fade
  speed: normal
  cardEntry: fade
  tickerScroll: normal
moods:
  urgent:
    borderColor: "rgba(255,59,48,0.8)"
    fillColor: "rgba(255,59,48,0.08)"
    pulse: true
    scale: 1.01
    animation: pulse
  muted:
    opacity: 0.45
''',
    },
    {
      'slug': 'neon-arcade',
      'name': 'Neon Arcade',
      'author': 'landfall',
      'description': 'High-contrast neon on deep black. High energy.',
      'tags': ['vibrant', 'dark', 'gaming', 'entertainment', 'neon'],
      'yaml': '''
version: "1.0"
meta:
  name: "Neon Arcade"
  author: "landfall"
  description: "High-contrast neon on deep black. High energy."
  tags: [vibrant, dark, gaming, entertainment, neon]
surface:
  background:
    type: solid
    value: "#050508"
  card:
    fill: "rgba(255,255,255,0.04)"
    border:
      color: "rgba(0,255,180,0.3)"
      width: 1.5
      style: solid
    radius: 4
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
  accent: "#00FFB4"
  text:
    primary: "#E8FFF9"
    secondary: "rgba(0,255,180,0.7)"
    tertiary: "rgba(255,255,255,0.3)"
  divider: "rgba(0,255,180,0.15)"
  agent:
    border: "rgba(0,255,180,0.4)"
  success: "#00FF88"
  warning: "#FFB800"
  alert: "#FF3366"
animation:
  transition: fade
  speed: fast
  cardEntry: scale
  tickerScroll: fast
moods:
  urgent:
    borderColor: "#FF3366"
    fillColor: "rgba(255,51,102,0.12)"
    pulse: true
    scale: 1.02
    animation: pulse
  celebratory:
    borderColor: "#00FF88"
    fillColor: "rgba(0,255,136,0.1)"
    animation: glow
  muted:
    opacity: 0.45
''',
    },
    {
      'slug': 'deep-blue',
      'name': 'Deep Blue',
      'author': 'landfall',
      'description': 'Calm and focused. Cool navy palette with a cyan accent.',
      'tags': ['dark', 'minimal', 'focus', 'blue'],
      'yaml': '''
version: "1.0"
meta:
  name: "Deep Blue"
  author: "landfall"
  description: "Calm and focused. Cool navy palette with a cyan accent."
  tags: [dark, minimal, focus, blue]
surface:
  background:
    type: solid
    value: "#080C14"
  card:
    fill: "rgba(255,255,255,0.04)"
    border:
      color: "rgba(100,160,220,0.2)"
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
    secondary: "rgba(226,239,249,0.6)"
    tertiary: "rgba(226,239,249,0.35)"
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
    borderColor: "rgba(248,113,113,0.7)"
    fillColor: "rgba(248,113,113,0.08)"
    pulse: true
    scale: 1.005
    animation: pulse
  celebratory:
    borderColor: "rgba(74,222,128,0.6)"
    fillColor: "rgba(74,222,128,0.07)"
    animation: glow
  success:
    borderColor: "rgba(74,222,128,0.45)"
    fillColor: "rgba(74,222,128,0.05)"
  muted:
    opacity: 0.45
''',
    },
    {
      'slug': 'warm-editorial',
      'name': 'Warm Editorial',
      'author': 'landfall',
      'description': 'Warm off-white background with a print/magazine aesthetic.',
      'tags': ['light', 'warm', 'editorial', 'serif'],
      'yaml': '''
version: "1.0"
meta:
  name: "Warm Editorial"
  author: "landfall"
  description: "Warm off-white background with a print/magazine aesthetic."
  tags: [light, warm, editorial, serif]
surface:
  background:
    type: solid
    value: "#FAF7F2"
  card:
    fill: "rgba(0,0,0,0.03)"
    border:
      color: "rgba(0,0,0,0.08)"
      width: 1.0
      style: solid
    radius: 4
    blur: 0
    shadow: subtle
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
    weight: 400
color:
  accent: "#C05621"
  text:
    primary: "#2D2D2D"
    secondary: "rgba(45,45,45,0.65)"
    tertiary: "rgba(45,45,45,0.38)"
  success: "#276749"
  warning: "#C05621"
  alert: "#C53030"
animation:
  transition: fade
  speed: relaxed
  cardEntry: fade
  tickerScroll: slow
moods:
  urgent:
    borderColor: "rgba(197,48,48,0.8)"
    fillColor: "rgba(197,48,48,0.06)"
    pulse: true
    scale: 1.005
    animation: pulse
  celebratory:
    borderColor: "rgba(39,103,73,0.7)"
    fillColor: "rgba(39,103,73,0.06)"
    animation: glow
  muted:
    opacity: 0.5
''',
    },
  ];
}
