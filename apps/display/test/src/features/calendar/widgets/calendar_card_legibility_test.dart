// Landfall is read from a sofa, not a desk. These tests pin the type scale of
// the calendar card at the size it actually occupies on the wall — the 6x4
// slot the weekday layout gives it on a 1920x1080 panel — so a future tweak
// cannot quietly shrink an event title back to 10 px, and so bigger type
// cannot silently start overflowing its cell.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/calendar/widgets/calendar_card.dart';

/// The calendar's real slot: 6 of 12 columns and 4 of 8 rows of the grid area
/// (5/6 of 1920 wide), less the 12 px gutter on each side.
const _slot = Size(776, 516);

CalendarEventEntity _event(
  int id,
  String title,
  DateTime start, {
  String calendar = 'Work',
}) =>
    CalendarEventEntity(
      id: id,
      credentialId: 1,
      calendarId: 'primary',
      calendarName: calendar,
      externalEventId: 'evt-$id',
      title: title,
      startTime: start,
      endTime: start.add(const Duration(hours: 1)),
      isAllDay: false,
    );

List<CalendarEventEntity> _events() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return [
    _event(1, 'Sprint planning', today.add(const Duration(hours: 15))),
    _event(2, '1:1 with Sarah', today.add(const Duration(hours: 16, minutes: 30))),
    _event(3, 'Dinner with the Hendersons next door',
        today.add(const Duration(hours: 19)), calendar: 'Family'),
    _event(4, 'Dentist', today.add(const Duration(days: 2, hours: 9)),
        calendar: 'Family'),
    _event(5, 'Quarterly review', today.add(const Duration(days: 4, hours: 13))),
    _event(6, 'Flight to Denver', today.add(const Duration(days: 7, hours: 6))),
  ];
}

Widget _wrap(Widget child) => MaterialApp(
      theme: LandfallTheme.dark,
      home: LandfallActiveTheme(
        tokens: LandfallThemeTokens.defaults(),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: _slot.width,
              height: _slot.height,
              child: child,
            ),
          ),
        ),
      ),
    );

Iterable<Text> _visibleText(WidgetTester tester) =>
    tester.widgetList<Text>(find.byType(Text)).where((t) {
      final data = t.data;
      return data != null && data.trim().isNotEmpty;
    });

void main() {
  const views = ['daily', 'weekly', 'monthly', 'biweekly'];

  for (final view in views) {
    group('CalendarCard — $view view at its real slot size', () {
      testWidgets('every label is at or above the legibility floor',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(1920, 1080));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_wrap(
          CalendarCard(events: _events(), displayConfig: {'view': view}),
        ));
        await tester.pump();

        for (final text in _visibleText(tester)) {
          final size = text.style?.fontSize;
          expect(
            size,
            isNotNull,
            reason: '"${text.data}" has no explicit size, so it inherits '
                'whatever the ambient theme happens to be',
          );
          expect(
            size,
            greaterThanOrEqualTo(LandfallTypography.minChromeFontSize),
            reason: '"${text.data}" renders at ${size}px — unreadable from '
                'across a room',
          );
        }
      });

      testWidgets('nothing overflows once the type is that big',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(1920, 1080));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_wrap(
          CalendarCard(events: _events(), displayConfig: {'view': view}),
        ));
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('event titles are content-sized, not chrome-sized',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(
      CalendarCard(events: _events(), displayConfig: const {'view': 'daily'}),
    ));
    await tester.pump();

    final title = tester.widgetList<Text>(find.text('Sprint planning')).first;
    expect(
      title.style?.fontSize,
      greaterThanOrEqualTo(26),
      reason: 'the event title is the reason the card exists',
    );
  });

  testWidgets('the month grid scales its dates to the cell, not to 12 px',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(
      CalendarCard(events: _events(), displayConfig: const {'view': 'monthly'}),
    ));
    await tester.pump();

    final today = DateTime.now().day.toString();
    final dateText = tester.widgetList<Text>(find.text(today)).first;
    expect(
      dateText.style?.fontSize,
      greaterThanOrEqualTo(LandfallTypography.minContentFontSize),
      reason: 'which square is today is the whole point of a month view',
    );
  });
}
