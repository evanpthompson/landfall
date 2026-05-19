import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/auth/widgets/landfall_button.dart';

Widget _host({required bool isLoading, ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? LandfallTheme.dark,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 240,
          child: LandfallButton(
            label: 'Send code',
            isLoading: isLoading,
            onPressed: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('LandfallButton', () {
    testWidgets('renders label when not loading', (tester) async {
      await tester.pumpWidget(_host(isLoading: false));
      expect(find.text('Send code'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders spinner and disables when loading', (tester) async {
      await tester.pumpWidget(_host(isLoading: true));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets(
      'theme change does not crash AnimatedDefaultTextStyle.lerp',
      (tester) async {
        // Regression: the button previously set fontWeight via the child
        // `Text(style: const TextStyle(...))`, which has inherit:true. The
        // surrounding AnimatedDefaultTextStyle held an inherit:false style
        // from the theme. Anything that re-themed the button mid-frame (a
        // resize triggering a MediaQuery rebuild, a theme swap) crashed
        // lerp with "Failed to interpolate TextStyles with different
        // inherit values".
        // Force AnimatedDefaultTextStyle.didUpdateWidget to see a brand-new
        // TextStyle by swapping the surrounding theme. The bug triggers when
        // the new style and the in-progress lerp result disagree on inherit.
        await tester.pumpWidget(_host(isLoading: false, theme: ThemeData.light()));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpWidget(_host(isLoading: false, theme: LandfallTheme.dark));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
