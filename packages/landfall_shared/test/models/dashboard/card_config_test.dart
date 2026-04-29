import 'package:test/test.dart';
import 'package:landfall_shared/landfall_shared.dart';

void main() {
  group('CardConfig', () {
    late DashboardSlot slot;
    late CardConfig config;

    setUp(() {
      slot = DashboardSlot(column: 0, row: 0, columnSpan: 3, rowSpan: 2);
      config = CardConfig(
        id: 'slot_clock',
        source: 'system.clock',
        slot: slot,
      );
    });

    test('defaults visible to true', () {
      expect(config.visible, isTrue);
    });

    test('defaults locked to false', () {
      expect(config.locked, isFalse);
    });

    test('defaults mood to normal', () {
      expect(config.mood, CardMood.normal);
    });

    test('defaults displayConfig to empty map', () {
      expect(config.displayConfig, isEmpty);
    });

    test('can be created with visible = false', () {
      final hidden = CardConfig(
        id: 'slot_clock',
        source: 'system.clock',
        slot: slot,
        visible: false,
      );
      expect(hidden.visible, isFalse);
    });

    test('can be created with locked = true', () {
      final locked = CardConfig(
        id: 'slot_clock',
        source: 'system.clock',
        slot: slot,
        locked: true,
      );
      expect(locked.locked, isTrue);
    });

    test('can be created with a non-normal mood', () {
      final urgent = CardConfig(
        id: 'slot_clock',
        source: 'system.clock',
        slot: slot,
        mood: CardMood.urgent,
      );
      expect(urgent.mood, CardMood.urgent);
    });

    test('can be created with displayConfig', () {
      final withConfig = CardConfig(
        id: 'slot_clock',
        source: 'system.clock',
        slot: slot,
        displayConfig: {'showSeconds': false, 'showDate': true},
      );
      expect(withConfig.displayConfig['showSeconds'], isFalse);
      expect(withConfig.displayConfig['showDate'], isTrue);
    });

    test('equality is value-based', () {
      final same = CardConfig(id: 'slot_clock', source: 'system.clock', slot: slot);
      final diff = CardConfig(id: 'slot_weather', source: 'system.weather', slot: slot);
      expect(config, equals(same));
      expect(config, isNot(equals(diff)));
    });

    test('equality distinguishes locked state', () {
      final locked = CardConfig(
        id: 'slot_clock',
        source: 'system.clock',
        slot: slot,
        locked: true,
      );
      expect(config, isNot(equals(locked)));
    });

    test('equality distinguishes mood', () {
      final urgent = CardConfig(
        id: 'slot_clock',
        source: 'system.clock',
        slot: slot,
        mood: CardMood.urgent,
      );
      expect(config, isNot(equals(urgent)));
    });

    test('equality distinguishes displayConfig', () {
      final withConfig = CardConfig(
        id: 'slot_clock',
        source: 'system.clock',
        slot: slot,
        displayConfig: {'showSeconds': true},
      );
      expect(config, isNot(equals(withConfig)));
    });

    test('hashCode is consistent with equality', () {
      final same = CardConfig(id: 'slot_clock', source: 'system.clock', slot: slot);
      expect(config.hashCode, same.hashCode);
    });

    test('copyWith overrides selected fields', () {
      final copy = config.copyWith(source: 'system.weather', visible: false);
      expect(copy.id, 'slot_clock');
      expect(copy.source, 'system.weather');
      expect(copy.visible, isFalse);
      expect(copy.slot, slot);
      expect(copy.locked, isFalse);
      expect(copy.mood, CardMood.normal);
      expect(copy.displayConfig, isEmpty);
    });

    test('copyWith overrides locked', () {
      final locked = config.copyWith(locked: true);
      expect(locked.locked, isTrue);
      expect(locked.id, config.id);
    });

    test('copyWith overrides mood', () {
      final success = config.copyWith(mood: CardMood.success);
      expect(success.mood, CardMood.success);
    });

    test('copyWith overrides displayConfig', () {
      final withConfig = config.copyWith(displayConfig: {'showDate': false});
      expect(withConfig.displayConfig['showDate'], isFalse);
    });

    group('toJson / fromJson', () {
      test('round-trips defaults correctly', () {
        final json = config.toJson();
        final restored = CardConfig.fromJson(json);
        expect(restored, config);
      });

      test('round-trips with visible = false', () {
        final hidden = CardConfig(
          id: 'slot_clock',
          source: 'system.clock',
          slot: slot,
          visible: false,
        );
        expect(CardConfig.fromJson(hidden.toJson()), hidden);
      });

      test('round-trips with locked = true', () {
        final locked = CardConfig(
          id: 'slot_clock',
          source: 'system.clock',
          slot: slot,
          locked: true,
        );
        expect(CardConfig.fromJson(locked.toJson()), locked);
      });

      test('round-trips all CardMood values', () {
        for (final mood in CardMood.values) {
          final card = CardConfig(
            id: 'slot_clock',
            source: 'system.clock',
            slot: slot,
            mood: mood,
          );
          expect(CardConfig.fromJson(card.toJson()), card);
        }
      });

      test('round-trips displayConfig', () {
        final withConfig = CardConfig(
          id: 'slot_clock',
          source: 'system.clock',
          slot: slot,
          displayConfig: {'showSeconds': false, 'showDate': true, 'scale': 1.5},
        );
        final restored = CardConfig.fromJson(withConfig.toJson());
        expect(restored.displayConfig['showSeconds'], isFalse);
        expect(restored.displayConfig['showDate'], isTrue);
        expect(restored.displayConfig['scale'], 1.5);
      });

      test('json contains all expected keys', () {
        final json = config.toJson();
        expect(
          json.keys,
          containsAll(['id', 'source', 'slot', 'visible', 'locked', 'mood', 'displayConfig']),
        );
      });

      test('mood is serialized as its name string', () {
        final urgent = config.copyWith(mood: CardMood.urgent);
        expect(urgent.toJson()['mood'], 'urgent');
      });

      group('backward compatibility — missing fields default correctly', () {
        test('missing locked defaults to false', () {
          final json = config.toJson()..remove('locked');
          expect(CardConfig.fromJson(json).locked, isFalse);
        });

        test('missing mood defaults to normal', () {
          final json = config.toJson()..remove('mood');
          expect(CardConfig.fromJson(json).mood, CardMood.normal);
        });

        test('missing displayConfig defaults to empty map', () {
          final json = config.toJson()..remove('displayConfig');
          expect(CardConfig.fromJson(json).displayConfig, isEmpty);
        });
      });
    });
  });
}
