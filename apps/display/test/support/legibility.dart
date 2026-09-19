// Shared assertions for "can this be read from the sofa?".
//
// Every card on the wall gets the same two questions asked of it, at the size
// the shipped layout actually gives it: is any of its text below the floor,
// and does it overflow once the text is that big. Those two pull against each
// other, which is exactly why they belong in one helper — fixing one by
// breaking the other is the failure mode.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

/// Slot sizes from the shipped weekday layout on a 1920x1080 panel: the grid
/// area is 5/6 of the width in a 12x8 cell grid, less the 12 px gutter each
/// side of a card.
class CardSlot {
  static const double _cellW = (1920 * 5 / 6) / 12;
  static const double _cellH = 1080 / 8;
  static const double _gap = 12;

  static Size of({required int columns, required int rows}) => Size(
        columns * _cellW - _gap * 2,
        rows * _cellH - _gap * 2,
      );

  static Size get clock => of(columns: 3, rows: 2);
  static Size get weather => of(columns: 6, rows: 2);
  static Size get calendar => of(columns: 6, rows: 4);
  static Size get photos => of(columns: 6, rows: 4);
}

Widget wrapInSlot(Widget card, Size slot) => MaterialApp(
      theme: LandfallTheme.dark,
      home: LandfallActiveTheme(
        tokens: LandfallThemeTokens.defaults(),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: slot.width,
              height: slot.height,
              child: card,
            ),
          ),
        ),
      ),
    );

/// Pumps [card] at [slot] and asserts every visible label is at or above the
/// legibility floor and that nothing overflowed getting there.
Future<void> expectLegibleAtSlot(
  WidgetTester tester,
  Widget card,
  Size slot, {
  double floor = LandfallTypography.minChromeFontSize,
}) async {
  await tester.binding.setSurfaceSize(const Size(1920, 1080));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(wrapInSlot(card, slot));
  await tester.pump();

  final texts = tester.widgetList<Text>(find.byType(Text)).where((t) {
    final data = t.data;
    return data != null && data.trim().isNotEmpty;
  });

  expect(texts, isNotEmpty, reason: 'the card rendered no text at all');

  for (final text in texts) {
    final size = text.style?.fontSize;
    expect(
      size,
      isNotNull,
      reason: '"${text.data}" inherits its size instead of declaring one',
    );
    expect(
      size,
      greaterThanOrEqualTo(floor),
      reason: '"${text.data}" renders at ${size}px, below the ${floor}px floor',
    );
  }

  expect(
    tester.takeException(),
    isNull,
    reason: 'the card overflowed its real slot at this type size',
  );
}
