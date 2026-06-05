import 'package:display/src/features/display/widgets/settings_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  FocusNode node,
  VoidCallback onTap,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SettingsPill(
          focusNode: node,
          onTap: onTap,
          onFocusGained: () {},
        ),
      ),
    ),
  );
  node.requestFocus();
  await tester.pump();
}

void main() {
  testWidgets('Fire TV OK (select) activates the focused pill', (tester) async {
    var tapped = 0;
    final node = FocusNode();
    addTearDown(node.dispose);

    await _pump(tester, node, () => tapped++);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('Enter and Space also activate the pill (desktop)',
      (tester) async {
    var tapped = 0;
    final node = FocusNode();
    addTearDown(node.dispose);

    await _pump(tester, node, () => tapped++);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(tapped, 2);
  });

  testWidgets('an unrelated key does not activate the pill', (tester) async {
    var tapped = 0;
    final node = FocusNode();
    addTearDown(node.dispose);

    await _pump(tester, node, () => tapped++);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(tapped, 0);
  });

  testWidgets('tapping the pill activates it', (tester) async {
    var tapped = 0;
    final node = FocusNode();
    addTearDown(node.dispose);

    await _pump(tester, node, () => tapped++);
    await tester.tap(find.byType(SettingsPill));
    await tester.pump();

    expect(tapped, 1);
  });
}
