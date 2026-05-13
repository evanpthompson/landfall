import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:display/src/features/calendar/widgets/calendar_card.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(Widget child) => MaterialApp(
      theme: LandfallTheme.dark,
      home: Scaffold(body: SizedBox(width: 800, height: 600, child: child)),
    );

CalendarEventEntity _event({
  required int id,
  required DateTime startTime,
  DateTime? endTime,
  String title = 'Team Standup',
  String calendarName = 'Work',
  bool isAllDay = false,
}) =>
    CalendarEventEntity(
      id: id,
      credentialId: 1,
      calendarId: 'primary',
      calendarName: calendarName,
      externalEventId: 'ext_$id',
      title: title,
      startTime: startTime,
      endTime: endTime ?? startTime.add(const Duration(hours: 1)),
      isAllDay: isAllDay,
    );

// Events anchored to this week (Mon–Sun) and this month for view tests.
List<CalendarEventEntity> _thisWeekEvents() {
  final now = DateTime.now();
  // Monday of the current week
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return [
    _event(
      id: 1,
      startTime: DateTime(monday.year, monday.month, monday.day, 9, 0).toUtc(),
      title: 'Monday Meeting',
    ),
    _event(
      id: 2,
      startTime: DateTime(monday.year, monday.month, monday.day + 2, 14, 0)
          .toUtc(),
      title: 'Wednesday Workshop',
      calendarName: 'Personal',
    ),
    _event(
      id: 3,
      startTime: DateTime(monday.year, monday.month, monday.day + 4, 10, 30)
          .toUtc(),
      title: 'Friday Review',
    ),
  ];
}

List<CalendarEventEntity> _thisMonthEvents() {
  final now = DateTime.now();
  return [
    _event(id: 1, startTime: DateTime.utc(now.year, now.month, 1, 9, 0)),
    _event(id: 2, startTime: DateTime.utc(now.year, now.month, 1, 14, 0)),
    _event(id: 3, startTime: DateTime.utc(now.year, now.month, 1, 16, 0)),
    _event(id: 4, startTime: DateTime.utc(now.year, now.month, 1, 18, 0)),
    _event(id: 5, startTime: DateTime.utc(now.year, now.month, 15, 9, 0)),
  ];
}

// ---------------------------------------------------------------------------
// Daily view
// ---------------------------------------------------------------------------

void main() {
  group('CalendarCard — daily view (default)', () {
    testWidgets('shows UPCOMING heading', (tester) async {
      await tester.pumpWidget(_wrap(CalendarCard(events: const [])));
      expect(find.text('CALENDAR — TODAY'), findsOneWidget);
    });

    testWidgets('renders event title in daily list', (tester) async {
      final now = DateTime.now().toUtc();
      await tester.pumpWidget(_wrap(CalendarCard(
        events: [_event(id: 1, startTime: now, title: 'Daily Event')],
      )));
      expect(find.text('Daily Event'), findsOneWidget);
    });

    testWidgets('daily view is default when displayConfig is empty',
        (tester) async {
      await tester.pumpWidget(_wrap(CalendarCard(
        events: const [],
        displayConfig: const {},
      )));
      expect(find.text('CALENDAR — TODAY'), findsOneWidget);
    });
  });

  // ── Weekly view ────────────────────────────────────────────────────────────

  group('CalendarCard — weekly view', () {
    testWidgets('renders Mon–Sun column headers', (tester) async {
      await tester.pumpWidget(_wrap(CalendarCard(
        events: _thisWeekEvents(),
        displayConfig: const {'view': 'weekly'},
      )));
      await tester.pump();

      expect(find.text('MON'), findsOneWidget);
      expect(find.text('TUE'), findsOneWidget);
      expect(find.text('WED'), findsOneWidget);
      expect(find.text('THU'), findsOneWidget);
      expect(find.text('FRI'), findsOneWidget);
      expect(find.text('SAT'), findsOneWidget);
      expect(find.text('SUN'), findsOneWidget);
    });

    testWidgets('renders event title in correct day column', (tester) async {
      await tester.pumpWidget(_wrap(CalendarCard(
        events: _thisWeekEvents(),
        displayConfig: const {'view': 'weekly'},
      )));
      await tester.pump();

      expect(find.text('Monday Meeting'), findsOneWidget);
      expect(find.text('Wednesday Workshop'), findsOneWidget);
      expect(find.text('Friday Review'), findsOneWidget);
    });

    testWidgets('shows WEEK heading', (tester) async {
      await tester.pumpWidget(_wrap(CalendarCard(
        events: const [],
        displayConfig: const {'view': 'weekly'},
      )));
      await tester.pump();

      expect(find.text('CALENDAR — THIS WEEK'), findsOneWidget);
    });

    testWidgets('does not show daily heading in weekly mode', (tester) async {
      await tester.pumpWidget(_wrap(CalendarCard(
        events: const [],
        displayConfig: const {'view': 'weekly'},
      )));
      await tester.pump();

      expect(find.text('CALENDAR — TODAY'), findsNothing);
    });

    testWidgets('golden — weekly view', (tester) async {
      await tester.pumpWidget(_wrap(CalendarCard(
        events: _thisWeekEvents(),
        displayConfig: const {'view': 'weekly'},
      )));
      await tester.pump();

      await expectLater(
        find.byType(CalendarCard),
        matchesGoldenFile('goldens/calendar_card_weekly.png'),
      );
    });
  });

  // ── Monthly view ───────────────────────────────────────────────────────────

  group('CalendarCard — monthly view', () {
    testWidgets('renders day-of-week header row', (tester) async {
      await tester.pumpWidget(_wrap(CalendarCard(
        events: const [],
        displayConfig: const {'view': 'monthly'},
      )));
      await tester.pump();

      // All 7 day abbreviations appear in the header
      expect(find.text('M'), findsWidgets);
      expect(find.text('T'), findsWidgets);
      expect(find.text('W'), findsOneWidget);
      expect(find.text('F'), findsWidgets);
      expect(find.text('S'), findsWidgets);
    });

    testWidgets('renders day number 1 in the grid', (tester) async {
      await tester.pumpWidget(_wrap(CalendarCard(
        events: const [],
        displayConfig: const {'view': 'monthly'},
      )));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('renders current month name in heading', (tester) async {
      final now = DateTime.now();
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      await tester.pumpWidget(_wrap(CalendarCard(
        events: const [],
        displayConfig: const {'view': 'monthly'},
      )));
      await tester.pump();

      expect(find.text(months[now.month - 1].toUpperCase()), findsOneWidget);
    });

    testWidgets('does not show UPCOMING heading in monthly mode', (tester) async {
      await tester.pumpWidget(_wrap(CalendarCard(
        events: const [],
        displayConfig: const {'view': 'monthly'},
      )));
      await tester.pump();

      expect(find.text('UPCOMING'), findsNothing);
    });

    testWidgets('shows +N more label when a day has more than 3 events',
        (tester) async {
      await tester.pumpWidget(_wrap(CalendarCard(
        events: _thisMonthEvents(),
        displayConfig: const {'view': 'monthly'},
      )));
      await tester.pump();

      // Day 1 has 4 events → shows first 3 dots + "+1 more"
      expect(find.textContaining('+1'), findsOneWidget);
    });

    testWidgets('golden — monthly view', (tester) async {
      await tester.pumpWidget(_wrap(CalendarCard(
        events: _thisMonthEvents(),
        displayConfig: const {'view': 'monthly'},
      )));
      await tester.pump();

      await expectLater(
        find.byType(CalendarCard),
        matchesGoldenFile('goldens/calendar_card_monthly.png'),
      );
    });
  });

  // ── Resize safety (BUG-05) ─────────────────────────────────────────────────

  group('CalendarCard — resize safety', () {
    testWidgets('does not overflow in a 200x200 slot (daily)', (tester) async {
      final now = DateTime(2024, 3, 11, 9, 0);
      await tester.pumpWidget(MaterialApp(
        theme: LandfallTheme.dark,
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: CalendarCard(
              events: [_event(id: 1, startTime: now, title: 'Standup')],
              displayConfig: const {'view': 'daily'},
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow in a 200x200 slot (weekly)', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: LandfallTheme.dark,
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: CalendarCard(
              events: _thisWeekEvents(),
              displayConfig: const {'view': 'weekly'},
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow in a 200x200 slot (monthly)',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: LandfallTheme.dark,
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: CalendarCard(
              events: _thisWeekEvents(),
              displayConfig: const {'view': 'monthly'},
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });

  // ── Daily golden ───────────────────────────────────────────────────────────

  group('CalendarCard — daily golden', () {
    testWidgets('golden — daily view', (tester) async {
      // Fixed past date: Mon 11 Mar 2024, 09:00 local time.
      // Using a past date ensures the label is always "Mon, Mar 11" (never
      // "Today" or "Tomorrow"), making the golden stable regardless of when
      // or where the test runs.
      final base = DateTime(2024, 3, 11, 9, 0);
      await tester.pumpWidget(_wrap(CalendarCard(
        events: [
          _event(id: 1, startTime: base, title: 'Morning Standup'),
          _event(
            id: 2,
            startTime: base.add(const Duration(hours: 2)),
            title: 'Design Review',
            calendarName: 'Team',
          ),
        ],
        displayConfig: const {'view': 'daily'},
      )));
      await tester.pump();

      await expectLater(
        find.byType(CalendarCard),
        matchesGoldenFile('goldens/calendar_card_daily.png'),
      );
    });
  });
}
