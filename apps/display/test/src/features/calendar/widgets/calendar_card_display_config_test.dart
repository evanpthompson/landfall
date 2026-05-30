import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/features/settings/widgets/layout_editor.dart';

// ---------------------------------------------------------------------------
// Helpers (mirror the pattern used in card_hud_display_config_test.dart)
// ---------------------------------------------------------------------------

DashboardLayout _calendarLayout({Map<String, dynamic> displayConfig = const {}}) =>
    DashboardLayout(
      id: 'test',
      name: 'Test',
      columns: 12,
      rows: 8,
      cards: [
        CardConfig(
          id: 'card_a',
          source: 'system.calendar',
          slot: DashboardSlot(column: 0, row: 0, columnSpan: 4, rowSpan: 2),
          displayConfig: displayConfig,
        ),
      ],
    );

Widget _wrapLayout(
  DashboardLayout layout, {
  ValueChanged<DashboardLayout>? onChanged,
}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1200,
          height: 800,
          child: LayoutEditor(
            layout: layout,
            onLayoutChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    );

Future<void> _openHud(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('card_tile_card_a')));
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Card HUD — system.calendar display config section', () {
    testWidgets('shows view-mode chips when source is system.calendar',
        (tester) async {
      await tester.pumpWidget(_wrapLayout(_calendarLayout()));
      await _openHud(tester);

      expect(find.byKey(const ValueKey('hud_calendar_view_biweekly')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('hud_calendar_view_daily')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('hud_calendar_view_weekly')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('hud_calendar_view_monthly')),
          findsOneWidget);
    });

    testWidgets('2 Weeks chip is selected by default', (tester) async {
      await tester.pumpWidget(_wrapLayout(_calendarLayout()));
      await _openHud(tester);

      final chip = tester.widget<FilterChip>(
        find.descendant(
          of: find.byKey(const ValueKey('hud_calendar_view_biweekly')),
          matching: find.byType(FilterChip),
        ),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('Daily chip is not selected by default', (tester) async {
      await tester.pumpWidget(_wrapLayout(_calendarLayout()));
      await _openHud(tester);

      final chip = tester.widget<FilterChip>(
        find.descendant(
          of: find.byKey(const ValueKey('hud_calendar_view_daily')),
          matching: find.byType(FilterChip),
        ),
      );
      expect(chip.selected, isFalse);
    });

    testWidgets('tapping 2 Weeks chip emits displayConfig view=biweekly',
        (tester) async {
      DashboardLayout? emitted;
      await tester.pumpWidget(_wrapLayout(
        _calendarLayout(displayConfig: const {'view': 'daily'}),
        onChanged: (l) => emitted = l,
      ));
      await _openHud(tester);

      await tester
          .tap(find.byKey(const ValueKey('hud_calendar_view_biweekly')));
      await tester.pumpAndSettle();

      expect(emitted, isNotNull);
      expect(emitted!.cards.first.displayConfig['view'], equals('biweekly'));
    });

    testWidgets('2 Weeks chip is selected when view=biweekly in displayConfig',
        (tester) async {
      await tester.pumpWidget(
          _wrapLayout(_calendarLayout(displayConfig: const {'view': 'biweekly'})));
      await _openHud(tester);

      final chip = tester.widget<FilterChip>(
        find.descendant(
          of: find.byKey(const ValueKey('hud_calendar_view_biweekly')),
          matching: find.byType(FilterChip),
        ),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('tapping Weekly chip emits displayConfig view=weekly',
        (tester) async {
      DashboardLayout? emitted;
      await tester.pumpWidget(_wrapLayout(
        _calendarLayout(),
        onChanged: (l) => emitted = l,
      ));
      await _openHud(tester);

      await tester
          .tap(find.byKey(const ValueKey('hud_calendar_view_weekly')));
      await tester.pumpAndSettle();

      expect(emitted, isNotNull);
      expect(emitted!.cards.first.displayConfig['view'], equals('weekly'));
    });

    testWidgets('tapping Monthly chip emits displayConfig view=monthly',
        (tester) async {
      DashboardLayout? emitted;
      await tester.pumpWidget(_wrapLayout(
        _calendarLayout(),
        onChanged: (l) => emitted = l,
      ));
      await _openHud(tester);

      await tester
          .tap(find.byKey(const ValueKey('hud_calendar_view_monthly')));
      await tester.pumpAndSettle();

      expect(emitted!.cards.first.displayConfig['view'], equals('monthly'));
    });

    testWidgets('tapping Daily chip emits displayConfig view=daily',
        (tester) async {
      DashboardLayout? emitted;
      await tester.pumpWidget(_wrapLayout(
        _calendarLayout(displayConfig: const {'view': 'weekly'}),
        onChanged: (l) => emitted = l,
      ));
      await _openHud(tester);

      await tester
          .tap(find.byKey(const ValueKey('hud_calendar_view_daily')));
      await tester.pumpAndSettle();

      expect(emitted!.cards.first.displayConfig['view'], equals('daily'));
    });

    testWidgets('Weekly chip is selected when view=weekly in displayConfig',
        (tester) async {
      await tester.pumpWidget(
          _wrapLayout(_calendarLayout(displayConfig: const {'view': 'weekly'})));
      await _openHud(tester);

      final chip = tester.widget<FilterChip>(
        find.descendant(
          of: find.byKey(const ValueKey('hud_calendar_view_weekly')),
          matching: find.byType(FilterChip),
        ),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('Monthly chip is selected when view=monthly in displayConfig',
        (tester) async {
      await tester.pumpWidget(
          _wrapLayout(_calendarLayout(displayConfig: const {'view': 'monthly'})));
      await _openHud(tester);

      final chip = tester.widget<FilterChip>(
        find.descendant(
          of: find.byKey(const ValueKey('hud_calendar_view_monthly')),
          matching: find.byType(FilterChip),
        ),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('calendar section does not appear for non-calendar sources',
        (tester) async {
      final layout = DashboardLayout(
        id: 'test',
        name: 'Test',
        columns: 12,
        rows: 8,
        cards: [
          CardConfig(
            id: 'card_a',
            source: 'system.clock',
            slot: DashboardSlot(column: 0, row: 0, columnSpan: 4, rowSpan: 2),
          ),
        ],
      );
      await tester.pumpWidget(_wrapLayout(layout));
      await _openHud(tester);

      expect(find.byKey(const ValueKey('hud_calendar_view_daily')),
          findsNothing);
    });
  });
}
