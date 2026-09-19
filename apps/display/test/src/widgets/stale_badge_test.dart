import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/widgets/stale_badge.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: LandfallActiveTheme(
        tokens: LandfallThemeTokens.defaults(),
        child: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  group('formatStaleTimestamp', () {
    final now = DateTime(2026, 9, 19, 16, 30); // a Saturday

    test('shows a 12-hour time for something fetched today', () {
      expect(
        formatStaleTimestamp(DateTime(2026, 9, 19, 14, 5), now: now),
        '2:05 PM',
      );
    });

    test('renders midnight and noon as 12, not 0', () {
      expect(
        formatStaleTimestamp(DateTime(2026, 9, 19, 0, 7), now: now),
        '12:07 AM',
      );
      expect(
        formatStaleTimestamp(DateTime(2026, 9, 19, 12, 0), now: now),
        '12:00 PM',
      );
    });

    test('names the day once the reading is not from today', () {
      // "as of 2:05 PM" on Saturday reads as this afternoon when the reading
      // is actually from Thursday.
      expect(
        formatStaleTimestamp(DateTime(2026, 9, 17, 14, 5), now: now),
        'Thursday 2:05 PM',
      );
    });

    test('falls back to a date once a week has passed', () {
      expect(
        formatStaleTimestamp(DateTime(2026, 9, 1, 14, 5), now: now),
        '9/1',
      );
    });
  });

  group('StaleBadge', () {
    testWidgets('says when the data was last fetched', (tester) async {
      await tester.pumpWidget(
        _wrap(StaleBadge(fetchedAt: DateTime.now().subtract(
          const Duration(hours: 2),
        ))),
      );

      expect(find.textContaining('as of'), findsOneWidget);
    });
  });
}
