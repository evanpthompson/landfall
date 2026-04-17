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

    test('can be created with visible = false', () {
      final hidden = CardConfig(
        id: 'slot_clock',
        source: 'system.clock',
        slot: slot,
        visible: false,
      );
      expect(hidden.visible, isFalse);
    });

    test('equality is value-based', () {
      final same = CardConfig(id: 'slot_clock', source: 'system.clock', slot: slot);
      final diff = CardConfig(id: 'slot_weather', source: 'system.weather', slot: slot);
      expect(config, equals(same));
      expect(config, isNot(equals(diff)));
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
    });

    group('toJson / fromJson', () {
      test('round-trips correctly', () {
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
        final restored = CardConfig.fromJson(hidden.toJson());
        expect(restored, hidden);
      });

      test('json contains expected keys', () {
        final json = config.toJson();
        expect(json.keys, containsAll(['id', 'source', 'slot', 'visible']));
      });
    });
  });
}
