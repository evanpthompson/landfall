import 'package:test/test.dart';
import 'package:landfall_shared/landfall_shared.dart';

void main() {
  group('DashboardLayout', () {
    late DashboardSlot slot1;
    late DashboardSlot slot2;
    late DashboardLayout layout;

    setUp(() {
      slot1 = DashboardSlot(column: 0, row: 0, columnSpan: 3, rowSpan: 2);
      slot2 = DashboardSlot(column: 3, row: 0, columnSpan: 9, rowSpan: 4);
      layout = DashboardLayout(
        id: 'layout-default',
        name: 'Default',
        cards: [
          CardConfig(id: 'slot_clock', source: 'system.clock', slot: slot1),
          CardConfig(id: 'slot_weather', source: 'system.weather', slot: slot2),
        ],
      );
    });

    test('stores id, name, cards, columns, rows', () {
      expect(layout.id, 'layout-default');
      expect(layout.name, 'Default');
      expect(layout.cards.length, 2);
      expect(layout.columns, 12);
      expect(layout.rows, 8);
    });

    test('defaults to 12 columns and 8 rows', () {
      const minimal = DashboardLayout(id: 'x', name: 'X', cards: []);
      expect(minimal.columns, 12);
      expect(minimal.rows, 8);
    });

    test('accepts custom columns and rows', () {
      const custom = DashboardLayout(
        id: 'x',
        name: 'X',
        cards: [],
        columns: 6,
        rows: 4,
      );
      expect(custom.columns, 6);
      expect(custom.rows, 4);
    });

    test('equality is value-based', () {
      final same = DashboardLayout(
        id: 'layout-default',
        name: 'Default',
        cards: [
          CardConfig(id: 'slot_clock', source: 'system.clock', slot: slot1),
          CardConfig(id: 'slot_weather', source: 'system.weather', slot: slot2),
        ],
      );
      const diff = DashboardLayout(id: 'layout-other', name: 'Other', cards: []);
      expect(layout, equals(same));
      expect(layout, isNot(equals(diff)));
    });

    test('hashCode is consistent with equality', () {
      final same = DashboardLayout(
        id: 'layout-default',
        name: 'Default',
        cards: [
          CardConfig(id: 'slot_clock', source: 'system.clock', slot: slot1),
          CardConfig(id: 'slot_weather', source: 'system.weather', slot: slot2),
        ],
      );
      expect(layout.hashCode, same.hashCode);
    });

    group('toJson / fromJson', () {
      test('round-trips correctly', () {
        final json = layout.toJson();
        final restored = DashboardLayout.fromJson(json);
        expect(restored, layout);
      });

      test('round-trips an empty layout', () {
        const empty = DashboardLayout(id: 'empty', name: 'Empty', cards: []);
        final restored = DashboardLayout.fromJson(empty.toJson());
        expect(restored, empty);
      });

      test('json contains expected keys', () {
        final json = layout.toJson();
        expect(
          json.keys,
          containsAll(['id', 'name', 'cards', 'columns', 'rows']),
        );
      });
    });

    group('visibleCards', () {
      test('returns only visible cards', () {
        final withHidden = DashboardLayout(
          id: 'x',
          name: 'X',
          cards: [
            CardConfig(id: 'slot_clock', source: 'system.clock', slot: slot1),
            CardConfig(
              id: 'slot_weather',
              source: 'system.weather',
              slot: slot2,
              visible: false,
            ),
          ],
        );
        expect(withHidden.visibleCards.length, 1);
        expect(withHidden.visibleCards.first.id, 'slot_clock');
      });

      test('returns all cards when all are visible', () {
        expect(layout.visibleCards.length, 2);
      });

      test('returns empty list when all cards are hidden', () {
        final allHidden = DashboardLayout(
          id: 'x',
          name: 'X',
          cards: [
            CardConfig(
              id: 'slot_clock',
              source: 'system.clock',
              slot: slot1,
              visible: false,
            ),
          ],
        );
        expect(allHidden.visibleCards, isEmpty);
      });
    });

    group('defaultLayout', () {
      test('returns a non-empty layout', () {
        final def = DashboardLayout.defaultLayout();
        expect(def.cards, isNotEmpty);
        expect(def.name, isNotEmpty);
      });

      test('includes a clock card', () {
        final def = DashboardLayout.defaultLayout();
        final clockCards = def.cards.where((c) => c.source == 'system.clock');
        expect(clockCards, isNotEmpty);
      });

      test('all slots fit within the declared grid', () {
        final def = DashboardLayout.defaultLayout();
        for (final card in def.cards) {
          expect(
            card.slot.column + card.slot.columnSpan,
            lessThanOrEqualTo(def.columns),
            reason: '${card.id} extends past column boundary',
          );
          expect(
            card.slot.row + card.slot.rowSpan,
            lessThanOrEqualTo(def.rows),
            reason: '${card.id} extends past row boundary',
          );
        }
      });
    });
  });
}
