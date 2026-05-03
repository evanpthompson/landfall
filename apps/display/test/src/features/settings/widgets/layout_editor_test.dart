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
          .whereType<AnimatedPositioned>()
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

  // --- Toolbar ---------------------------------------------------------------

  group('toolbar', () {
    testWidgets('toolbar is present', (tester) async {
      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));
      expect(find.byKey(const ValueKey('editor_toolbar')), findsOneWidget);
    });

    testWidgets('toolbar contains snap toggle (default on)', (tester) async {
      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));
      expect(find.byKey(const ValueKey('toolbar_snap_toggle')), findsOneWidget);
    });

    testWidgets('toolbar contains preview toggle', (tester) async {
      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));
      expect(find.byKey(const ValueKey('toolbar_preview_toggle')), findsOneWidget);
    });

    testWidgets('toolbar contains reset button when onReset provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: LayoutEditor(
                layout: _twoCardLayout(),
                onLayoutChanged: (_) {},
                onReset: () {},
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('toolbar_reset')), findsOneWidget);
    });

    testWidgets('toolbar reset button not shown when onReset is null', (tester) async {
      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));
      expect(find.byKey(const ValueKey('toolbar_reset')), findsNothing);
    });

    testWidgets('toolbar contains select-all button', (tester) async {
      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));
      expect(find.byKey(const ValueKey('toolbar_select_all')), findsOneWidget);
    });
  });

  // --- Select all ------------------------------------------------------------

  group('select all', () {
    testWidgets('select-all sheet appears on tap', (tester) async {
      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));

      await tester.tap(find.byKey(const ValueKey('toolbar_select_all')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('select_all_sheet')), findsOneWidget);
    });

    testWidgets('lock all sets all cards locked', (tester) async {
      DashboardLayout? updated;
      await tester.pumpWidget(_wrapLayout(
        _twoCardLayout(),
        onChanged: (l) => updated = l,
      ));

      await tester.tap(find.byKey(const ValueKey('toolbar_select_all')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('select_all_lock_all')));
      await tester.pump();

      expect(updated, isNotNull);
      expect(updated!.cards.every((c) => c.locked), isTrue);
    });

    testWidgets('unlock all clears locked on all cards', (tester) async {
      DashboardLayout? updated;
      final lockedLayout = DashboardLayout(
        id: 'test',
        name: 'Test',
        columns: 12,
        rows: 8,
        cards: [
          CardConfig(
            id: 'card_a',
            source: 'system.clock',
            slot: DashboardSlot(column: 0, row: 0, columnSpan: 4, rowSpan: 2),
            locked: true,
          ),
          CardConfig(
            id: 'card_b',
            source: 'system.weather',
            slot: DashboardSlot(column: 4, row: 0, columnSpan: 4, rowSpan: 2),
            locked: true,
          ),
        ],
      );

      await tester.pumpWidget(_wrapLayout(lockedLayout, onChanged: (l) => updated = l));

      await tester.tap(find.byKey(const ValueKey('toolbar_select_all')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('select_all_unlock_all')));
      await tester.pump();

      expect(updated, isNotNull);
      expect(updated!.cards.every((c) => !c.locked), isTrue);
    });

    testWidgets('hide all sets visible=false on all cards', (tester) async {
      DashboardLayout? updated;
      await tester.pumpWidget(_wrapLayout(
        _twoCardLayout(),
        onChanged: (l) => updated = l,
      ));

      await tester.tap(find.byKey(const ValueKey('toolbar_select_all')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('select_all_hide_all')));
      await tester.pump();

      expect(updated, isNotNull);
      expect(updated!.cards.every((c) => !c.visible), isTrue);
    });

    testWidgets('show all sets visible=true on all cards', (tester) async {
      DashboardLayout? updated;
      final hiddenLayout = DashboardLayout(
        id: 'test',
        name: 'Test',
        columns: 12,
        rows: 8,
        cards: [
          CardConfig(
            id: 'card_a',
            source: 'system.clock',
            slot: DashboardSlot(column: 0, row: 0, columnSpan: 4, rowSpan: 2),
            visible: false,
          ),
          CardConfig(
            id: 'card_b',
            source: 'system.weather',
            slot: DashboardSlot(column: 4, row: 0, columnSpan: 4, rowSpan: 2),
            visible: false,
          ),
        ],
      );

      await tester.pumpWidget(_wrapLayout(hiddenLayout, onChanged: (l) => updated = l));

      await tester.tap(find.byKey(const ValueKey('toolbar_select_all')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('select_all_show_all')));
      await tester.pump();

      expect(updated, isNotNull);
      expect(updated!.cards.every((c) => c.visible), isTrue);
    });
  });

  // --- Snap toggle -----------------------------------------------------------

  group('snap toggle', () {
    testWidgets('snap is enabled by default', (tester) async {
      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));

      // The snap toggle should show the "on" icon (grid_on)
      final toggle = find.byKey(const ValueKey('toolbar_snap_toggle'));
      expect(toggle, findsOneWidget);
      // Verify the icon reflects snap-on state
      expect(find.byIcon(Icons.grid_on), findsOneWidget);
    });

    testWidgets('tapping snap toggle disables snap', (tester) async {
      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));

      await tester.tap(find.byKey(const ValueKey('toolbar_snap_toggle')));
      await tester.pump();

      // Icon should change to grid_off
      expect(find.byIcon(Icons.grid_off), findsOneWidget);
    });

    testWidgets('snap on: drag 60px stays at original column (floor of 0.6 = 0)', (tester) async {
      // 1200px canvas, 12 columns → cellW = 100px.
      // Delta-based: rawCol = startCol + 60/100 = 0.6 → floor(0.6) = 0 → no commit.
      DashboardLayout? updated;
      final layout = DashboardLayout(
        id: 'snap_test',
        name: 'Snap',
        columns: 12,
        rows: 8,
        cards: [
          CardConfig(
            id: 'card_snap',
            source: 'system.clock',
            slot: DashboardSlot(column: 0, row: 0, columnSpan: 2, rowSpan: 2),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: LayoutEditor(
                layout: layout,
                onLayoutChanged: (l) => updated = l,
              ),
            ),
          ),
        ),
      );

      final tile = find.byKey(const ValueKey('card_tile_card_snap'));
      await tester.drag(tile, const Offset(60, 0));
      await tester.pump();

      // No commit — floor(0.6) = 0 = slot.column
      expect(updated?.cards.first.slot.column ?? 0, equals(0));
    });

    testWidgets('snap off: drag 60px advances to next column (round of 0.6 = 1)', (tester) async {
      // Delta-based: rawCol = startCol + 60/100 = 0.6 → round(0.6) = 1 → commit col 1.
      DashboardLayout? updated;
      final layout = DashboardLayout(
        id: 'snap_test',
        name: 'Snap',
        columns: 12,
        rows: 8,
        cards: [
          CardConfig(
            id: 'card_snap',
            source: 'system.clock',
            slot: DashboardSlot(column: 0, row: 0, columnSpan: 2, rowSpan: 2),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: LayoutEditor(
                layout: layout,
                onLayoutChanged: (l) => updated = l,
              ),
            ),
          ),
        ),
      );

      // Disable snap
      await tester.tap(find.byKey(const ValueKey('toolbar_snap_toggle')));
      await tester.pump();

      final tile = find.byKey(const ValueKey('card_tile_card_snap'));
      await tester.drag(tile, const Offset(60, 0));
      await tester.pump();

      // round(0.6) = 1 → commit to column 1
      expect(updated?.cards.first.slot.column, equals(1));
    });
  });

  // --- Overlap detection -----------------------------------------------------

  group('overlap detection', () {
    testWidgets('ghost shows amber color when proposed slot overlaps another card',
        (tester) async {
      // card_a is at col 0..3, card_b is at col 4..7 (both row 0..1).
      // If we drag card_a to col 3, it would span cols 3..6, overlapping card_b (col 4..7).
      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));

      final cardA = find.byKey(const ValueKey('card_tile_card_a'));

      // Start drag and move card_a right into card_b's space.
      // Delta: rawCol = 0 + 350/cellW → floor > 3 → overlaps card_b (col 4..7).
      final gesture = await tester.startGesture(tester.getCenter(cardA));
      // Move in two steps so pan start fires before we check the ghost.
      await gesture.moveBy(const Offset(20, 0)); // exceed slop (18px)
      await tester.pump();
      await gesture.moveBy(const Offset(330, 0)); // total 350px — into overlap
      await tester.pump();

      expect(find.byKey(const ValueKey('drag_ghost_overlap')), findsOneWidget);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('ghost shows accent color when proposed slot is clear', (tester) async {
      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));

      final cardA = find.byKey(const ValueKey('card_tile_card_a'));

      // Move card_a slightly down (row direction, no horizontal overlap).
      final gesture = await tester.startGesture(tester.getCenter(cardA));
      await gesture.moveBy(const Offset(0, 20)); // exceed slop
      await tester.pump();
      await gesture.moveBy(const Offset(0, 90)); // total ~110px down
      await tester.pump();

      expect(find.byKey(const ValueKey('drag_ghost_clear')), findsOneWidget);

      await gesture.up();
      await tester.pump();
    });
  });

  // --- Preview mode ----------------------------------------------------------

  group('preview mode', () {
    testWidgets('preview toggle enters preview mode', (tester) async {
      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));

      await tester.tap(find.byKey(const ValueKey('toolbar_preview_toggle')));
      await tester.pump();

      expect(find.byKey(const ValueKey('preview_mode_indicator')), findsOneWidget);
    });

    testWidgets('in preview mode resize handles are not visible', (tester) async {
      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));

      // Confirm resize handle is present before preview mode
      expect(
          find.byKey(const ValueKey('resize_handle_card_a')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('toolbar_preview_toggle')));
      await tester.pump();

      expect(
          find.byKey(const ValueKey('resize_handle_card_a')), findsNothing);
    });

    testWidgets('tapping a card in preview mode exits preview', (tester) async {
      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));

      await tester.tap(find.byKey(const ValueKey('toolbar_preview_toggle')));
      await tester.pump();

      // Tap a card — should exit preview mode
      await tester.tap(find.byKey(const ValueKey('card_tile_card_a')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('preview_mode_indicator')), findsNothing);
    });

    testWidgets('in preview mode drag does nothing', (tester) async {
      var callCount = 0;
      await tester.pumpWidget(
        _wrapLayout(_twoCardLayout(), onChanged: (_) => callCount++),
      );

      await tester.tap(find.byKey(const ValueKey('toolbar_preview_toggle')));
      await tester.pump();

      final cardA = find.byKey(const ValueKey('card_tile_card_a'));
      await tester.drag(cardA, const Offset(200, 100));
      await tester.pump();

      expect(callCount, 0);
    });
  });

  // --- Animated transitions --------------------------------------------------

  group('animated transitions', () {
    testWidgets('card tiles use AnimatedPositioned', (tester) async {
      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));

      // AnimatedPositioned widgets should exist for card tiles
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('card_stack')),
          matching: find.byType(AnimatedPositioned),
        ),
        findsWidgets,
      );
    });
  });

  // --- Golden tests ----------------------------------------------------------

  group('golden tests', () {
    testWidgets('selected card state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));
      await tester.tap(find.byKey(const ValueKey('card_tile_card_a')));
      await tester.pumpAndSettle();
      // Close the HUD to keep the golden clean — selection highlight persists
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(LayoutEditor),
        matchesGoldenFile('goldens/layout_editor_selected.png'),
      );
    });

    testWidgets('locked card state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final lockedLayout = DashboardLayout(
        id: 'golden',
        name: 'Golden',
        columns: 12,
        rows: 8,
        cards: [
          CardConfig(
            id: 'card_locked',
            source: 'system.clock',
            slot: DashboardSlot(column: 0, row: 0, columnSpan: 4, rowSpan: 2),
            locked: true,
          ),
          CardConfig(
            id: 'card_unlocked',
            source: 'system.weather',
            slot: DashboardSlot(column: 4, row: 0, columnSpan: 4, rowSpan: 2),
          ),
        ],
      );

      await tester.pumpWidget(_wrapLayout(lockedLayout));
      await tester.pump();

      await expectLater(
        find.byType(LayoutEditor),
        matchesGoldenFile('goldens/layout_editor_locked.png'),
      );
    });

    testWidgets('preview mode state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrapLayout(_twoCardLayout()));
      await tester.tap(find.byKey(const ValueKey('toolbar_preview_toggle')));
      await tester.pump();

      await expectLater(
        find.byType(LayoutEditor),
        matchesGoldenFile('goldens/layout_editor_preview.png'),
      );
    });
  });
}
