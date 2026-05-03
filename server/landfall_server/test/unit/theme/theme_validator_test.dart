import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import 'package:landfall_server/src/theme/theme_validator.dart';

String _minimal({
  String version = '1.0',
  String name = 'My Theme',
}) =>
    '''
version: "$version"
meta:
  name: "$name"
''';

void main() {
  group('ThemeValidator.validate', () {
    group('valid themes', () {
      test('minimal valid theme passes', () {
        final result = ThemeValidator.validate(_minimal());
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('full valid theme passes', () {
        const yaml = '''
version: "1.0"
meta:
  name: "Deep Blue"
  author: "testuser"
  description: "A calm focused theme."
  tags: [dark, minimal]

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
  muted:
    opacity: 0.45
''';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isTrue, reason: result.errors.join('\n'));
      });

      test('3-digit hex color is valid', () {
        final yaml = '${_minimal()}color:\n  accent: "#FFF"\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isTrue);
      });

      test('description at exactly 200 characters is valid', () {
        final desc = 'A' * 200;
        final yaml = 'version: "1.0"\nmeta:\n  name: "X"\n  description: "$desc"\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isTrue);
      });

      test('card.radius at boundary value 0 is valid', () {
        final yaml = '${_minimal()}surface:\n  card:\n    radius: 0\n';
        expect(ThemeValidator.validate(yaml).isValid, isTrue);
      });

      test('card.radius at boundary value 24 is valid', () {
        final yaml = '${_minimal()}surface:\n  card:\n    radius: 24\n';
        expect(ThemeValidator.validate(yaml).isValid, isTrue);
      });

      test('card.blur at boundary value 20 is valid', () {
        final yaml = '${_minimal()}surface:\n  card:\n    blur: 20\n';
        expect(ThemeValidator.validate(yaml).isValid, isTrue);
      });

      test('muted.opacity at boundary value 0.3 is valid', () {
        final yaml = '${_minimal()}moods:\n  muted:\n    opacity: 0.3\n';
        expect(ThemeValidator.validate(yaml).isValid, isTrue);
      });

      test('muted.opacity at boundary value 0.8 is valid', () {
        final yaml = '${_minimal()}moods:\n  muted:\n    opacity: 0.8\n';
        expect(ThemeValidator.validate(yaml).isValid, isTrue);
      });
    });

    group('version field', () {
      test('missing version is an error', () {
        const yaml = 'meta:\n  name: "My Theme"\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
        expect(result.errors.any((e) => e.tokenPath == 'version'), isTrue);
      });

      test('unrecognised version is an error', () {
        final result = ThemeValidator.validate(_minimal(version: '2.0'));
        expect(result.isValid, isFalse);
        expect(result.errors.any((e) => e.tokenPath == 'version'), isTrue);
      });

      test('version with extra whitespace is an error', () {
        final result = ThemeValidator.validate(_minimal(version: ' 1.0 '));
        expect(result.isValid, isFalse);
      });
    });

    group('meta.name', () {
      test('missing meta.name is an error', () {
        const yaml = 'version: "1.0"\nmeta:\n  author: "x"\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
        expect(result.errors.any((e) => e.tokenPath == 'meta.name'), isTrue);
      });

      test('meta.name of 61 characters is an error', () {
        final name = 'A' * 61;
        final result = ThemeValidator.validate(_minimal(name: name));
        expect(result.isValid, isFalse);
        expect(result.errors.any((e) => e.tokenPath == 'meta.name'), isTrue);
      });

      test('meta.name at exactly 60 characters is valid', () {
        final result = ThemeValidator.validate(_minimal(name: 'A' * 60));
        expect(result.isValid, isTrue);
      });
    });

    group('meta.description', () {
      test('description of 201 characters is an error', () {
        final desc = 'A' * 201;
        final yaml =
            'version: "1.0"\nmeta:\n  name: "X"\n  description: "$desc"\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
        expect(
            result.errors.any((e) => e.tokenPath == 'meta.description'),
            isTrue);
      });
    });

    group('color token validation', () {
      test('invalid hex color is an error', () {
        final yaml = '${_minimal()}color:\n  accent: "GGGGGG"\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
        expect(
            result.errors.any((e) => e.tokenPath == 'color.accent'), isTrue);
      });

      test('hex without leading # is an error', () {
        final yaml = '${_minimal()}color:\n  accent: "4A9EFF"\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
      });

      test('valid rgba is accepted', () {
        final yaml =
            '${_minimal()}surface:\n  card:\n    fill: "rgba(255, 255, 255, 0.05)"\n';
        expect(ThemeValidator.validate(yaml).isValid, isTrue);
      });

      test('rgba with alpha > 1.0 is an error', () {
        final yaml =
            '${_minimal()}surface:\n  card:\n    fill: "rgba(255, 255, 255, 1.5)"\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
        expect(
            result.errors.any((e) => e.tokenPath == 'surface.card.fill'),
            isTrue);
      });

      test('rgba with channel > 255 is an error', () {
        final yaml =
            '${_minimal()}surface:\n  card:\n    fill: "rgba(300, 0, 0, 0.5)"\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
      });
    });

    group('enum token validation', () {
      test('invalid background type is an error', () {
        final yaml =
            '${_minimal()}surface:\n  background:\n    type: sparkle\n    value: "#000"\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
        expect(
            result.errors
                .any((e) => e.tokenPath == 'surface.background.type'),
            isTrue);
      });

      test('invalid typography scale is an error', () {
        final yaml = '${_minimal()}typography:\n  scale: huge\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
        expect(
            result.errors.any((e) => e.tokenPath == 'typography.scale'),
            isTrue);
      });

      test('invalid animation transition is an error', () {
        final yaml = '${_minimal()}animation:\n  transition: warp\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
        expect(
            result.errors
                .any((e) => e.tokenPath == 'animation.transition'),
            isTrue);
      });

      test('invalid card border style is an error', () {
        final yaml =
            '${_minimal()}surface:\n  card:\n    border:\n      style: dotted\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
      });
    });

    group('numeric range validation', () {
      test('card.radius above 24 is an error', () {
        final yaml = '${_minimal()}surface:\n  card:\n    radius: 25\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
        expect(
            result.errors
                .any((e) => e.tokenPath == 'surface.card.radius'),
            isTrue);
      });

      test('card.radius below 0 is an error', () {
        final yaml = '${_minimal()}surface:\n  card:\n    radius: -1\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
      });

      test('card.blur above 20 is an error', () {
        final yaml = '${_minimal()}surface:\n  card:\n    blur: 21\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
        expect(
            result.errors
                .any((e) => e.tokenPath == 'surface.card.blur'),
            isTrue);
      });

      test('card.border.width above 3.0 is an error', () {
        final yaml =
            '${_minimal()}surface:\n  card:\n    border:\n      width: 3.1\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
      });

      test('heading.weight not a multiple of 100 is an error', () {
        final yaml =
            '${_minimal()}typography:\n  heading:\n    weight: 550\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
        expect(
            result.errors
                .any((e) => e.tokenPath == 'typography.heading.weight'),
            isTrue);
      });

      test('heading.weight below 300 is an error', () {
        final yaml =
            '${_minimal()}typography:\n  heading:\n    weight: 200\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
      });

      test('heading.weight above 800 is an error', () {
        final yaml =
            '${_minimal()}typography:\n  heading:\n    weight: 900\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
      });

      test('muted.opacity below 0.3 is an error', () {
        final yaml =
            '${_minimal()}moods:\n  muted:\n    opacity: 0.29\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
        expect(
            result.errors
                .any((e) => e.tokenPath == 'moods.muted.opacity'),
            isTrue);
      });

      test('muted.opacity above 0.8 is an error', () {
        final yaml =
            '${_minimal()}moods:\n  muted:\n    opacity: 0.81\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
      });

      test('urgent.scale below 0.95 is an error', () {
        final yaml =
            '${_minimal()}moods:\n  urgent:\n    scale: 0.94\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
        expect(
            result.errors
                .any((e) => e.tokenPath == 'moods.urgent.scale'),
            isTrue);
      });

      test('urgent.scale above 1.10 is an error', () {
        final yaml =
            '${_minimal()}moods:\n  urgent:\n    scale: 1.11\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
      });
    });

    group('derived value resolution', () {
      test('resolvedTokens fills accentMuted when not set', () {
        final yaml = '${_minimal()}color:\n  accent: "#4A9EFF"\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isTrue);
        expect(result.resolvedTokens!['color.accentMuted'], isNotNull);
      });

      test('resolvedTokens fills divider when not set', () {
        final yaml =
            '${_minimal()}color:\n  text:\n    primary: "#FFFFFF"\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isTrue);
        expect(result.resolvedTokens!['color.divider'], isNotNull);
      });

      test('resolvedTokens fills agent.border when not set', () {
        final yaml = '${_minimal()}color:\n  accent: "#4A9EFF"\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isTrue);
        expect(result.resolvedTokens!['color.agent.border'], isNotNull);
      });

      test('explicit accentMuted overrides derived value', () {
        const explicit = 'rgba(100, 100, 100, 0.5)';
        final yaml =
            '${_minimal()}color:\n  accent: "#4A9EFF"\n  accentMuted: "$explicit"\n';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isTrue);
        expect(result.resolvedTokens!['color.accentMuted'], equals(explicit));
      });

      test('all required default tokens are present in resolvedTokens', () {
        final result = ThemeValidator.validate(_minimal());
        expect(result.isValid, isTrue);
        final tokens = result.resolvedTokens!;
        for (final key in ThemeValidator.requiredResolvedKeys) {
          expect(tokens.containsKey(key), isTrue,
              reason: 'missing resolved key: $key');
        }
      });
    });

    group('multiple errors', () {
      test('all errors are collected, not just the first', () {
        final yaml = '''
version: "2.0"
meta:
  name: "${'A' * 61}"
color:
  accent: "NOTAHEX"
''';
        final result = ThemeValidator.validate(yaml);
        expect(result.isValid, isFalse);
        expect(result.errors.length, greaterThanOrEqualTo(3));
      });
    });
  });

  group('ThemeValidator.verifySha256', () {
    // Helper: compute the expected sha256 of content with the sha256 line stripped.
    String _sha256Of(String content) {
      final stripped = content
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('sha256:'))
          .join('\n');
      return sha256.convert(utf8.encode(stripped)).toString();
    }

    test('returns null when sha256 field is present and matches', () {
      final base = 'version: "1.0"\nmeta:\n  name: "Test"\n';
      final hash = _sha256Of('sha256: placeholder\n$base');
      final content = 'sha256: $hash\n$base';
      expect(ThemeValidator.verifySha256(content), isNull);
    });

    test('returns error when sha256 field is absent', () {
      const content = 'version: "1.0"\nmeta:\n  name: "Test"\n';
      final result = ThemeValidator.verifySha256(content);
      expect(result, isNotNull);
      expect(result, contains('sha256'));
    });

    test('returns error when sha256 field is present but wrong', () {
      const content =
          'sha256: 0000000000000000000000000000000000000000000000000000000000000000\n'
          'version: "1.0"\nmeta:\n  name: "Test"\n';
      final result = ThemeValidator.verifySha256(content);
      expect(result, isNotNull);
      expect(result!.toLowerCase(), contains('integrity'));
    });

    test('sha256 field position (top or inline) does not affect result', () {
      final base = 'version: "1.0"\nmeta:\n  name: "Inline"\n';
      final hash = _sha256Of('$base\nsha256: placeholder');
      final contentInline = '$base\nsha256: $hash';
      expect(ThemeValidator.verifySha256(contentInline), isNull);
    });
  });
}
