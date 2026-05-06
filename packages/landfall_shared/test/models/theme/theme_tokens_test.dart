import 'package:test/test.dart';
import 'package:landfall_shared/src/models/theme/theme_tokens.dart';

Map<String, dynamic> _defaultMap() => {
      'surface.background.type': 'solid',
      'surface.background.value': '#0D0D0F',
      'surface.card.fill': 'rgba(255,255,255,0.05)',
      'surface.card.border.color': 'rgba(255,255,255,0.1)',
      'surface.card.border.width': 1.0,
      'surface.card.border.style': 'solid',
      'surface.card.radius': 8,
      'surface.card.blur': 0,
      'surface.card.shadow': 'none',
      'typography.fontFamily': 'System',
      'typography.scale': 'comfortable',
      'typography.heading.weight': 600,
      'typography.body.weight': 400,
      'typography.letterSpacing': 'normal',
      'typography.timeDisplay.fontFamily': 'System',
      'typography.timeDisplay.weight': 200,
      'color.accent': '#4A9EFF',
      'color.accentMuted': 'rgba(74,158,255,0.2)',
      'color.text.primary': '#FFFFFF',
      'color.text.secondary': 'rgba(255,255,255,0.6)',
      'color.text.tertiary': 'rgba(255,255,255,0.35)',
      'color.divider': 'rgba(255,255,255,0.1)',
      'color.agent.border': 'rgba(74,158,255,0.3)',
      'color.success': '#34C759',
      'color.warning': '#FF9F0A',
      'color.alert': '#FF3B30',
      'animation.transition': 'fade',
      'animation.speed': 'normal',
      'animation.cardEntry': 'fade',
      'animation.tickerScroll': 'normal',
      'moods.urgent.borderColor': 'rgba(255,59,48,0.8)',
      'moods.urgent.fillColor': 'rgba(255,59,48,0.1)',
      'moods.urgent.pulse': true,
      'moods.urgent.scale': 1.01,
      'moods.urgent.animation': 'pulse',
      'moods.celebratory.borderColor': 'rgba(52,199,89,0.6)',
      'moods.celebratory.fillColor': 'rgba(52,199,89,0.08)',
      'moods.celebratory.pulse': false,
      'moods.celebratory.scale': 1.0,
      'moods.celebratory.animation': 'glow',
      'moods.success.borderColor': 'rgba(52,199,89,0.5)',
      'moods.success.fillColor': 'rgba(52,199,89,0.06)',
      'moods.success.pulse': false,
      'moods.success.scale': 1.0,
      'moods.success.animation': 'none',
      'moods.muted.borderColor': 'rgba(255,255,255,0.1)',
      'moods.muted.fillColor': 'rgba(255,255,255,0.05)',
      'moods.muted.pulse': false,
      'moods.muted.scale': 1.0,
      'moods.muted.animation': 'none',
      'moods.muted.opacity': 0.5,
    };

void main() {
  group('LandfallThemeTokens.fromMap', () {
    test('deserialises all fields from a valid map', () {
      final tokens = LandfallThemeTokens.fromMap(_defaultMap());
      expect(tokens.backgroundType, equals('solid'));
      expect(tokens.backgroundValue, equals('#0D0D0F'));
      expect(tokens.cardFill, equals('rgba(255,255,255,0.05)'));
      expect(tokens.cardRadius, equals(8));
      expect(tokens.cardBorderWidth, equals(1.0));
      expect(tokens.fontFamily, equals('System'));
      expect(tokens.headingWeight, equals(600));
      expect(tokens.colorAccent, equals('#4A9EFF'));
      expect(tokens.colorAccentMuted, equals('rgba(74,158,255,0.2)'));
      expect(tokens.colorSuccess, equals('#34C759'));
      expect(tokens.animationTransition, equals('fade'));
      expect(tokens.moodUrgentPulse, isTrue);
      expect(tokens.moodUrgentScale, equals(1.01));
      expect(tokens.moodCelebratoryAnimation, equals('glow'));
      expect(tokens.moodMutedOpacity, equals(0.5));
    });

    test('backgroundOverlay is null when not present in map', () {
      final tokens = LandfallThemeTokens.fromMap(_defaultMap());
      expect(tokens.backgroundOverlay, isNull);
    });

    test('backgroundOverlay is set when present in map', () {
      final m = Map<String, dynamic>.from(_defaultMap())
        ..['surface.background.overlay'] = 'rgba(0,0,0,0.3)';
      final tokens = LandfallThemeTokens.fromMap(m);
      expect(tokens.backgroundOverlay, equals('rgba(0,0,0,0.3)'));
    });

    test('integer-typed numeric values can be deserialized from int', () {
      final m = Map<String, dynamic>.from(_defaultMap())
        ..['surface.card.radius'] = 12;
      final tokens = LandfallThemeTokens.fromMap(m);
      expect(tokens.cardRadius, equals(12));
    });

    test('double-typed numeric values can be deserialized from double', () {
      final m = Map<String, dynamic>.from(_defaultMap())
        ..['moods.muted.opacity'] = 0.45;
      final tokens = LandfallThemeTokens.fromMap(m);
      expect(tokens.moodMutedOpacity, equals(0.45));
    });
  });

  group('LandfallThemeTokens.toMap', () {
    test('round-trip: fromMap(toMap()) returns equal token set', () {
      final original = LandfallThemeTokens.fromMap(_defaultMap());
      final roundTripped = LandfallThemeTokens.fromMap(original.toMap());
      expect(roundTripped, equals(original));
    });

    test('toMap includes all required keys', () {
      final tokens = LandfallThemeTokens.fromMap(_defaultMap());
      final map = tokens.toMap();
      for (final key in _defaultMap().keys) {
        if (key == 'surface.background.overlay') continue;
        expect(map.containsKey(key), isTrue,
            reason: 'toMap missing key: $key');
      }
    });

    test('backgroundOverlay omitted from toMap when null', () {
      final tokens = LandfallThemeTokens.fromMap(_defaultMap());
      expect(tokens.backgroundOverlay, isNull);
      expect(tokens.toMap().containsKey('surface.background.overlay'), isFalse);
    });

    test('backgroundOverlay included in toMap when set', () {
      final m = Map<String, dynamic>.from(_defaultMap())
        ..['surface.background.overlay'] = 'rgba(0,0,0,0.3)';
      final tokens = LandfallThemeTokens.fromMap(m);
      expect(tokens.toMap()['surface.background.overlay'],
          equals('rgba(0,0,0,0.3)'));
    });
  });

  group('LandfallThemeTokens.defaults', () {
    test('returns a valid token set', () {
      final d = LandfallThemeTokens.defaults();
      expect(d.backgroundValue, equals('#0D0D0F'));
      expect(d.cardFill, equals('#1A1A1F'));
      expect(d.cardBorderColor, equals('#2C2C35'));
      expect(d.cardBorderWidth, equals(1.5));
      expect(d.cardRadius, equals(8));
      expect(d.colorTextPrimary, equals('#F2F2F7'));
      expect(d.colorTextSecondary, equals('#8E8E9A'));
      expect(d.colorTextTertiary, equals('#5A5A6A'));
      expect(d.colorAccent, equals('#4F8EF7'));
    });

    test('defaults are stable across calls', () {
      expect(LandfallThemeTokens.defaults(), equals(LandfallThemeTokens.defaults()));
    });
  });

  group('LandfallThemeTokens.copyWith', () {
    test('copyWith overrides specified fields', () {
      final d = LandfallThemeTokens.defaults();
      final copy = d.copyWith(cardBorderColor: '#FF0000', cardRadius: 12);
      expect(copy.cardBorderColor, equals('#FF0000'));
      expect(copy.cardRadius, equals(12));
    });

    test('copyWith preserves unspecified fields', () {
      final d = LandfallThemeTokens.defaults();
      final copy = d.copyWith(cardBorderColor: '#FF0000');
      expect(copy.backgroundValue, equals(d.backgroundValue));
      expect(copy.colorTextPrimary, equals(d.colorTextPrimary));
      expect(copy.moodMutedOpacity, equals(d.moodMutedOpacity));
    });
  });

  group('equality', () {
    test('two tokens with same accent/background are equal', () {
      final a = LandfallThemeTokens.fromMap(_defaultMap());
      final b = LandfallThemeTokens.fromMap(_defaultMap());
      expect(a, equals(b));
    });

    test('tokens with different accent are not equal', () {
      final a = LandfallThemeTokens.fromMap(_defaultMap());
      final b = LandfallThemeTokens.fromMap(
        Map<String, dynamic>.from(_defaultMap())..['color.accent'] = '#FF0000',
      );
      expect(a, isNot(equals(b)));
    });
  });
}
