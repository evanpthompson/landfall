import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: LandfallTheme.dark,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('LandfallFocusable', () {
    testWidgets('renders child without focus ring when unfocused', (tester) async {
      await tester.pumpWidget(_wrap(
        LandfallFocusable(
          child: FilledButton(onPressed: () {}, child: const Text('content')),
        ),
      ));
      await tester.pump();

      expect(find.text('content'), findsOneWidget);

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.border, isNull);
    });

    testWidgets('shows focus ring when child gains keyboard focus', (tester) async {
      await tester.pumpWidget(_wrap(
        LandfallFocusable(
          child: FilledButton(
            autofocus: true,
            onPressed: () {},
            child: const Text('btn'),
          ),
        ),
      ));
      await tester.pump(); // autofocus settles

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.border, isNotNull);
    });

    testWidgets('wraps a FilledButton — ring renders when focus is requested',
        (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(_wrap(
        LandfallFocusable(
          child: FilledButton(
            focusNode: node,
            onPressed: () {},
            child: const Text('Action'),
          ),
        ),
      ));

      node.requestFocus();
      await tester.pump();

      expect(find.text('Action'), findsOneWidget);
      expect(node.hasFocus, isTrue);

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.border, isNotNull);
    });

    testWidgets('ring disappears when focus moves away', (tester) async {
      final nodeA = FocusNode();
      final nodeB = FocusNode();
      addTearDown(nodeA.dispose);
      addTearDown(nodeB.dispose);

      await tester.pumpWidget(_wrap(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LandfallFocusable(
              key: const Key('a'),
              child: FilledButton(
                focusNode: nodeA,
                onPressed: () {},
                child: const Text('A'),
              ),
            ),
            FilledButton(
              focusNode: nodeB,
              onPressed: () {},
              child: const Text('B'),
            ),
          ],
        ),
      ));

      nodeA.requestFocus();
      await tester.pump();

      // A is focused — ring visible.
      final containerA = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect((containerA.decoration as BoxDecoration?)?.border, isNotNull);

      nodeB.requestFocus();
      await tester.pump();

      // A lost focus — ring gone.
      final containerAfter = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect((containerAfter.decoration as BoxDecoration?)?.border, isNull);
    });

    testWidgets('golden — focused vs unfocused at 1920×1080', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final focusedNode = FocusNode();
      addTearDown(focusedNode.dispose);

      await tester.pumpWidget(MaterialApp(
        theme: LandfallTheme.dark,
        home: Scaffold(
          backgroundColor: LandfallColors.background,
          body: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LandfallFocusable(
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('Unfocused'),
                  ),
                ),
                const SizedBox(width: 40),
                LandfallFocusable(
                  child: FilledButton(
                    focusNode: focusedNode,
                    onPressed: () {},
                    child: const Text('Focused'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ));

      focusedNode.requestFocus();
      await tester.pump();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/landfall_focusable.png'),
      );
    });
  });
}
