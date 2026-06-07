import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/features/settings/widgets/layout_editor.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// 12×8 grid with two side-by-side cards.
///   card_a: col 0, row 0, span 4×2  (top-left)
///   card_b: col 4, row 0, span 4×2  (right of card_a)
DashboardLayout _layout({bool firstLocked = false}) => DashboardLayout(
      id: 'test',
      name: 'Test',
      columns: 12,
      rows: 8,
      cards: [
        CardConfig(
          id: 'card_a',
          source: 'system.clock',
          slot: DashboardSlot(column: 0, row: 0, columnSpan: 4, rowSpan: 2),
          locked: firstLocked,
        ),
        CardConfig(
          id: 'card_b',
          source: 'system.weather',
          slot: DashboardSlot(column: 4, row: 0, columnSpan: 4, rowSpan: 2),
        ),
      ],
    );

Widget _wrap(
  DashboardLayout layout, {
  ValueChanged<DashboardLayout>? onChanged,
  ValueChanged<bool>? onMoveModeChanged,
}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1200,
          height: 800,
          child: LayoutEditor(
            layout: layout,
            onLayoutChanged: onChanged ?? (_) {},
            leanback: true,
            onMoveModeChanged: onMoveModeChanged,
          ),
        ),
      ),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('LayoutEditor — leanback D-pad', () {
    group('initial focus', () {
      testWidgets('first card is autofocused on build', (tester) async {
        await tester.pumpWidget(_wrap(_layout()));
        await tester.pump();

        expect(
          find.byKey(const ValueKey('lb_focus_ring_card_a')),
          findsOneWidget,
        );
      });

      testWidgets('second card does not have initial focus', (tester) async {
        await tester.pumpWidget(_wrap(_layout()));
        await tester.pump();

        expect(
          find.byKey(const ValueKey('lb_focus_ring_card_b')),
          findsNothing,
        );
      });
    });

    group('browse → move mode', () {
      testWidgets('OK key on focused card enters move mode', (tester) async {
        await tester.pumpWidget(_wrap(_layout()));
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.select);
        await tester.pump();

        expect(
          find.byKey(const ValueKey('lb_move_mode_card_a')),
          findsOneWidget,
        );
      });

      testWidgets('OK key on a locked card does not enter move mode',
          (tester) async {
        await tester.pumpWidget(_wrap(_layout(firstLocked: true)));
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.select);
        await tester.pump();

        expect(
          find.byKey(const ValueKey('lb_move_mode_card_a')),
          findsNothing,
        );
      });

      testWidgets('onMoveModeChanged fires true when entering move mode',
          (tester) async {
        final events = <bool>[];
        await tester.pumpWidget(
          _wrap(_layout(), onMoveModeChanged: events.add),
        );
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.select);
        await tester.pump();

        expect(events, [true]);
      });
    });

    group('move mode — arrow keys', () {
      testWidgets('arrowRight shifts card one column to the right',
          (tester) async {
        DashboardLayout? result;
        await tester.pumpWidget(_wrap(_layout(), onChanged: (l) => result = l));
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.select); // enter move mode
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.select); // confirm
        await tester.pump();

        expect(result, isNotNull);
        final movedCard =
            result!.cards.firstWhere((c) => c.id == 'card_a');
        expect(movedCard.slot.column, 1);
      });

      testWidgets('arrowLeft shifts card one column to the left — clamps at 0',
          (tester) async {
        DashboardLayout? result;
        await tester.pumpWidget(_wrap(_layout(), onChanged: (l) => result = l));
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.select);
        await tester.pump();

        // card_a starts at column 0 — can't go further left
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.select);
        await tester.pump();

        // onLayoutChanged only fires when the position actually changed
        expect(result, isNull);
      });

      testWidgets('arrowDown shifts card one row down', (tester) async {
        DashboardLayout? result;
        await tester.pumpWidget(_wrap(_layout(), onChanged: (l) => result = l));
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.select);
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.select);
        await tester.pump();

        expect(result, isNotNull);
        final movedCard = result!.cards.firstWhere((c) => c.id == 'card_a');
        expect(movedCard.slot.row, 1);
      });

      testWidgets('arrowUp clamps at row 0', (tester) async {
        DashboardLayout? result;
        await tester.pumpWidget(_wrap(_layout(), onChanged: (l) => result = l));
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.select);
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.select);
        await tester.pump();

        expect(result, isNull);
      });
    });

    group('confirming a move', () {
      testWidgets('OK in move mode with changed position calls onLayoutChanged',
          (tester) async {
        DashboardLayout? result;
        await tester.pumpWidget(_wrap(_layout(), onChanged: (l) => result = l));
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.select); // enter move
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.select); // confirm
        await tester.pump();

        expect(result, isNotNull);
      });

      testWidgets('OK in move mode with unchanged position does not call onLayoutChanged',
          (tester) async {
        DashboardLayout? result;
        await tester.pumpWidget(_wrap(_layout(), onChanged: (l) => result = l));
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.select); // enter move
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.select); // confirm immediately
        await tester.pump();

        expect(result, isNull);
      });

      testWidgets('move mode indicator disappears after confirm', (tester) async {
        await tester.pumpWidget(_wrap(_layout()));
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.select);
        await tester.pump();
        expect(find.byKey(const ValueKey('lb_move_mode_card_a')), findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.select);
        await tester.pump();
        expect(find.byKey(const ValueKey('lb_move_mode_card_a')), findsNothing);
      });

      testWidgets('onMoveModeChanged fires false after confirm', (tester) async {
        final events = <bool>[];
        await tester.pumpWidget(_wrap(_layout(), onMoveModeChanged: events.add));
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.select);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.select);
        await tester.pump();

        expect(events, [true, false]);
      });
    });

    group('cancelling a move', () {
      testWidgets('Escape in move mode cancels without calling onLayoutChanged',
          (tester) async {
        DashboardLayout? result;
        await tester.pumpWidget(_wrap(_layout(), onChanged: (l) => result = l));
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.select);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape); // cancel
        await tester.pump();

        expect(result, isNull);
        expect(find.byKey(const ValueKey('lb_move_mode_card_a')), findsNothing);
      });

      testWidgets('onMoveModeChanged fires false after cancel', (tester) async {
        final events = <bool>[];
        await tester.pumpWidget(_wrap(_layout(), onMoveModeChanged: events.add));
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.select);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();

        expect(events, [true, false]);
      });
    });

    group('spatial browse navigation', () {
      testWidgets('arrowRight from card_a moves focus to card_b', (tester) async {
        await tester.pumpWidget(_wrap(_layout()));
        await tester.pump();

        // card_a is autofocused
        expect(find.byKey(const ValueKey('lb_focus_ring_card_a')), findsOneWidget);
        expect(find.byKey(const ValueKey('lb_focus_ring_card_b')), findsNothing);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();

        expect(find.byKey(const ValueKey('lb_focus_ring_card_a')), findsNothing);
        expect(find.byKey(const ValueKey('lb_focus_ring_card_b')), findsOneWidget);
      });

      testWidgets('arrowLeft from card_b returns focus to card_a', (tester) async {
        await tester.pumpWidget(_wrap(_layout()));
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight); // focus card_b
        await tester.pump();
        expect(find.byKey(const ValueKey('lb_focus_ring_card_b')), findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();

        expect(find.byKey(const ValueKey('lb_focus_ring_card_a')), findsOneWidget);
        expect(find.byKey(const ValueKey('lb_focus_ring_card_b')), findsNothing);
      });

      testWidgets('arrowRight at rightmost card does not move focus', (tester) async {
        await tester.pumpWidget(_wrap(_layout()));
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight); // to card_b
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight); // no card further right
        await tester.pump();

        // card_b still focused
        expect(find.byKey(const ValueKey('lb_focus_ring_card_b')), findsOneWidget);
      });
    });
  });
}
