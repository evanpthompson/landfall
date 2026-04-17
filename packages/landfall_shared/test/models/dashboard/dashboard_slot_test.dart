import 'package:test/test.dart';
import 'package:landfall_shared/landfall_shared.dart';

void main() {
  group('DashboardSlot', () {
    final slot = DashboardSlot(
      column: 0,
      row: 0,
      columnSpan: 3,
      rowSpan: 2,
    );

    test('stores column, row, columnSpan, rowSpan', () {
      expect(slot.column, 0);
      expect(slot.row, 0);
      expect(slot.columnSpan, 3);
      expect(slot.rowSpan, 2);
    });

    test('equality is value-based', () {
      final same = DashboardSlot(column: 0, row: 0, columnSpan: 3, rowSpan: 2);
      final diff = DashboardSlot(column: 1, row: 0, columnSpan: 3, rowSpan: 2);
      expect(slot, equals(same));
      expect(slot, isNot(equals(diff)));
    });

    test('hashCode is consistent with equality', () {
      final same = DashboardSlot(column: 0, row: 0, columnSpan: 3, rowSpan: 2);
      expect(slot.hashCode, same.hashCode);
    });

    test('copyWith overrides selected fields', () {
      final copy = slot.copyWith(column: 4, rowSpan: 1);
      expect(copy.column, 4);
      expect(copy.row, 0);
      expect(copy.columnSpan, 3);
      expect(copy.rowSpan, 1);
    });

    group('toJson / fromJson', () {
      test('round-trips correctly', () {
        final json = slot.toJson();
        final restored = DashboardSlot.fromJson(json);
        expect(restored, slot);
      });

      test('json contains expected keys', () {
        final json = slot.toJson();
        expect(json.keys, containsAll(['column', 'row', 'columnSpan', 'rowSpan']));
      });
    });

    group('validation', () {
      test('throws if column is negative', () {
        expect(
          () => DashboardSlot(column: -1, row: 0, columnSpan: 1, rowSpan: 1),
          throwsArgumentError,
        );
      });

      test('throws if row is negative', () {
        expect(
          () => DashboardSlot(column: 0, row: -1, columnSpan: 1, rowSpan: 1),
          throwsArgumentError,
        );
      });

      test('throws if columnSpan is zero or negative', () {
        expect(
          () => DashboardSlot(column: 0, row: 0, columnSpan: 0, rowSpan: 1),
          throwsArgumentError,
        );
      });

      test('throws if rowSpan is zero or negative', () {
        expect(
          () => DashboardSlot(column: 0, row: 0, columnSpan: 1, rowSpan: 0),
          throwsArgumentError,
        );
      });
    });
  });
}
