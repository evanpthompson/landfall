import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/features/settings/widgets/layout_editor.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

DashboardLayout _twoCardLayout({bool firstLocked = false}) => DashboardLayout(
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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // --- Select mode -----------------------------------------------------------

  group('tap selects card (does not toggle visibility)', () {
    testWidgets('tapping a card shows selection highlight', (tester) async {
      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));

      expect(find.byKey(const ValueKey('selection_highlight_card_a')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('card_tile_card_a')));
      await tester.pump();

      expect(find.byKey(const ValueKey('selection_highlight_card_a')), findsOneWidget);
    });

    testWidgets('tapping a card does not call onLayoutChanged', (tester) async {
      var callCount = 0;
      await tester.pumpWidget(_wrapLayout(
        _twoCardLayout(),
        onChanged: (_) => callCount++,
      ));

      await tester.tap(find.byKey(const ValueKey('card_tile_card_a')));
      await tester.pump();

      expect(callCount, 0);
    });

    testWidgets('tapping a second card deselects the first', (tester) async {
      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));

      // Select card_a (opens HUD modal)
      await tester.tap(find.byKey(const ValueKey('card_tile_card_a')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('selection_highlight_card_a')), findsOneWidget);

      // Dismiss the HUD, then tap card_b
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('card_tile_card_b')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('selection_highlight_card_a')), findsNothing);
      expect(find.byKey(const ValueKey('selection_highlight_card_b')), findsOneWidget);
    });
  });

  // --- Dragged card z-order (UX-01) ------------------------------------------

  group('dragged card renders on top (UX-01)', () {
    testWidgets('dragged card tile is the last child in the Stack during drag', (tester) async {
      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));

      // Start a drag on card_a but don't release — we want to check mid-drag state.
      final cardA = find.byKey(const ValueKey('card_tile_card_a'));
      final gesture = await tester.startGesture(tester.getCenter(cardA));
      await gesture.moveBy(const Offset(20, 20));
      await tester.pump();

      // Find the main card stack and inspect child order
      final stack = find.byKey(const ValueKey('card_stack'));
      final stackWidget = tester.widget<Stack>(stack);
      final children = stackWidget.children;

      final tileKeys = children
          .whereType<Positioned>()
          .map((p) => p.key)
          .whereType<ValueKey<String>>()
          .where((k) => k.value.startsWith('card_tile_'))
          .toList();

      expect(tileKeys.last.value, 'card_tile_card_a');

      await gesture.up();
      await tester.pump();
    });
  });

  // --- Card HUD --------------------------------------------------------------

  group('card HUD', () {
    testWidgets('HUD appears as bottom sheet when card is selected', (tester) async {
      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));

      await tester.tap(find.byKey(const ValueKey('card_tile_card_a')));
      await tester.pumpAndSettle();

      // HUD sheet should be visible
      expect(find.byKey(const ValueKey('card_hud')), findsOneWidget);
    });

    testWidgets('HUD contains visibility toggle', (tester) async {
      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));

      await tester.tap(find.byKey(const ValueKey('card_tile_card_a')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('hud_visibility_toggle')), findsOneWidget);
    });

    testWidgets('HUD visibility toggle calls onLayoutChanged with toggled visible', (tester) async {
      DashboardLayout? updated;
      await tester.pumpWidget(_wrapLayout(
        _twoCardLayout(),
        onChanged: (l) => updated = l,
      ));

      await tester.tap(find.byKey(const ValueKey('card_tile_card_a')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('hud_visibility_toggle')));
      await tester.pump();

      expect(updated, isNotNull);
      final cardA = updated!.cards.firstWhere((c) => c.id == 'card_a');
      expect(cardA.visible, false);
    });

    testWidgets('HUD contains lock toggle', (tester) async {
      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));

      await tester.tap(find.byKey(const ValueKey('card_tile_card_a')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('hud_lock_toggle')), findsOneWidget);
    });

    testWidgets('HUD lock toggle calls onLayoutChanged with toggled locked', (tester) async {
      DashboardLayout? updated;
      await tester.pumpWidget(_wrapLayout(
        _twoCardLayout(),
        onChanged: (l) => updated = l,
      ));

      await tester.tap(find.byKey(const ValueKey('card_tile_card_a')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('hud_lock_toggle')));
      await tester.pump();

      expect(updated, isNotNull);
      final cardA = updated!.cards.firstWhere((c) => c.id == 'card_a');
      expect(cardA.locked, true);
    });

    testWidgets('HUD bring-to-front reorders card to end of cards list', (tester) async {
      DashboardLayout? updated;
      await tester.pumpWidget(_wrapLayout(
        _twoCardLayout(),
        onChanged: (l) => updated = l,
      ));

      // card_a is index 0; bring it to front
      await tester.tap(find.byKey(const ValueKey('card_tile_card_a')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('hud_bring_to_front')));
      await tester.pump();

      expect(updated, isNotNull);
      expect(updated!.cards.last.id, 'card_a');
    });

    testWidgets('HUD send-to-back reorders card to index 0', (tester) async {
      DashboardLayout? updated;
      await tester.pumpWidget(_wrapLayout(
        _twoCardLayout(),
        onChanged: (l) => updated = l,
      ));

      // card_b is index 1; send it to back
      await tester.tap(find.byKey(const ValueKey('card_tile_card_b')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('hud_send_to_back')));
      await tester.pump();

      expect(updated, isNotNull);
      expect(updated!.cards.first.id, 'card_b');
    });

    testWidgets('HUD delete button removes card from layout', (tester) async {
      DashboardLayout? updated;
      await tester.pumpWidget(_wrapLayout(
        _twoCardLayout(),
        onChanged: (l) => updated = l,
      ));

      await tester.tap(find.byKey(const ValueKey('card_tile_card_a')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('hud_delete')));
      await tester.pumpAndSettle();

      // Confirmation dialog
      await tester.tap(find.byKey(const ValueKey('hud_delete_confirm')));
      await tester.pump();

      expect(updated, isNotNull);
      expect(updated!.cards.any((c) => c.id == 'card_a'), false);
    });
  });

  // --- Lock enforcement ------------------------------------------------------

  group('locked card ignores drag and resize', () {
    testWidgets('locked card does not start a drag', (tester) async {
      var callCount = 0;
      final lockedLayout = DashboardLayout(
        id: 'test',
        name: 'Test',
        columns: 12,
        rows: 8,
        cards: [
          CardConfig(
            id: 'card_locked',
            source: 'system.clock',
            slot: DashboardSlot(column: 0, row: 0, columnSpan: 4, rowSpan: 2),
            locked: true,
          ),
        ],
      );

      await tester.pumpWidget(_wrapLayout(
        lockedLayout,
        onChanged: (_) => callCount++,
      ));

      // Try to drag the locked card
      final tile = find.byKey(const ValueKey('card_tile_card_locked'));
      await tester.drag(tile, const Offset(200, 100));
      await tester.pump();

      // No layout change should have been triggered
      expect(callCount, 0);
    });

    testWidgets('locked card does not show resize handle', (tester) async {
      final lockedLayout = DashboardLayout(
        id: 'test',
        name: 'Test',
        columns: 12,
        rows: 8,
        cards: [
          CardConfig(
            id: 'card_locked',
            source: 'system.clock',
            slot: DashboardSlot(column: 0, row: 0, columnSpan: 4, rowSpan: 2),
            locked: true,
          ),
        ],
      );

      await tester.pumpWidget(_wrapLayout(lockedLayout));

      expect(find.byKey(const ValueKey('resize_handle_card_locked')), findsNothing);
    });
  });

  // --- Lock badge ------------------------------------------------------------

  group('lock badge', () {
    testWidgets('locked card shows lock badge', (tester) async {
      final lockedLayout = DashboardLayout(
        id: 'test',
        name: 'Test',
        columns: 12,
        rows: 8,
        cards: [
          CardConfig(
            id: 'card_locked',
            source: 'system.clock',
            slot: DashboardSlot(column: 0, row: 0, columnSpan: 4, rowSpan: 2),
            locked: true,
          ),
        ],
      );

      await tester.pumpWidget(_wrapLayout(lockedLayout));

      expect(find.byKey(const ValueKey('lock_badge_card_locked')), findsOneWidget);
    });

    testWidgets('unlocked card does not show lock badge', (tester) async {
      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));

      expect(find.byKey(const ValueKey('lock_badge_card_a')), findsNothing);
    });
  });
}
