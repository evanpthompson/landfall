import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/theme/widgets/theme_card.dart';

// ── fixtures ──────────────────────────────────────────────────────────────────

LandfallThemeTokens _tokens({String accent = '#7C3AED'}) =>
    LandfallThemeTokens(
      backgroundType: 'solid',
      backgroundValue: '#0d0d0d',
      cardFill: '#1a1a1a',
      cardBorderColor: '#333333',
      cardBorderWidth: 1.0,
      cardBorderStyle: 'solid',
      cardRadius: 8,
      cardBlur: 0,
      cardShadow: 'none',
      fontFamily: 'Inter',
      typographyScale: 'default',
      headingWeight: 600,
      bodyWeight: 400,
      letterSpacing: 'normal',
      timeDisplayFontFamily: 'Inter',
      timeDisplayWeight: 700,
      colorAccent: accent,
      colorAccentMuted: '#5b21b6',
      colorTextPrimary: '#ffffff',
      colorTextSecondary: '#aaaaaa',
      colorTextTertiary: '#888888',
      colorDivider: '#333333',
      colorAgentBorder: '#444444',
      colorSuccess: '#00ff00',
      colorWarning: '#ffff00',
      colorAlert: '#ff0000',
      animationTransition: 'fade',
      animationSpeed: 'normal',
      animationCardEntry: 'slide',
      animationTickerScroll: 'smooth',
      moodUrgentBorderColor: '#ff0000',
      moodUrgentFillColor: '#330000',
      moodUrgentPulse: true,
      moodUrgentScale: 1.02,
      moodUrgentAnimation: 'pulse',
      moodCelebratoryBorderColor: '#ffcc00',
      moodCelebratoryFillColor: '#332200',
      moodCelebratoryPulse: false,
      moodCelebratoryScale: 1.0,
      moodCelebratoryAnimation: 'confetti',
      moodSuccessBorderColor: '#00ff00',
      moodSuccessFillColor: '#003300',
      moodSuccessPulse: false,
      moodSuccessScale: 1.0,
      moodSuccessAnimation: 'none',
      moodMutedBorderColor: '#555555',
      moodMutedFillColor: '#1a1a1a',
      moodMutedPulse: false,
      moodMutedScale: 1.0,
      moodMutedAnimation: 'none',
      moodMutedOpacity: 0.5,
      photoTransition: 'drift',
    );

ThemeInfo _theme({
  int id = 1,
  String slug = 'default-dark',
  String name = 'Default Dark',
  bool isBuiltIn = true,
  String? author,
  String? description,
}) =>
    ThemeInfo(
      id: id,
      slug: slug,
      name: name,
      schemaVersion: '1.0',
      author: author,
      description: description,
      isBuiltIn: isBuiltIn,
      tokens: _tokens(),
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: LandfallTheme.dark,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('ThemeCard', () {
    testWidgets('renders the theme name', (tester) async {
      await tester.pumpWidget(_wrap(
        ThemeCard(
          theme: _theme(name: 'Neon Arcade'),
          isActive: false,
          onApply: () {},
        ),
      ));
      expect(find.text('Neon Arcade'), findsOneWidget);
    });

    testWidgets('renders the author when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        ThemeCard(
          theme: _theme(author: 'Jane Doe'),
          isActive: false,
          onApply: () {},
        ),
      ));
      expect(find.text('Jane Doe'), findsOneWidget);
    });

    testWidgets('does not render author line when absent', (tester) async {
      await tester.pumpWidget(_wrap(
        ThemeCard(theme: _theme(), isActive: false, onApply: () {}),
      ));
      // No author text — only the name should be there
      expect(find.text('Default Dark'), findsOneWidget);
    });

    testWidgets('shows Built-in badge for built-in themes', (tester) async {
      await tester.pumpWidget(_wrap(
        ThemeCard(theme: _theme(isBuiltIn: true), isActive: false, onApply: () {}),
      ));
      expect(find.text('Built-in'), findsOneWidget);
    });

    testWidgets('does not show Built-in badge for user themes', (tester) async {
      await tester.pumpWidget(_wrap(
        ThemeCard(
          theme: _theme(isBuiltIn: false),
          isActive: false,
          onApply: () {},
        ),
      ));
      expect(find.text('Built-in'), findsNothing);
    });

    testWidgets('shows active indicator when isActive is true', (tester) async {
      await tester.pumpWidget(_wrap(
        ThemeCard(theme: _theme(), isActive: true, onApply: () {}),
      ));
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('does not show active indicator when isActive is false',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ThemeCard(theme: _theme(), isActive: false, onApply: () {}),
      ));
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('shows Apply button when theme is not active', (tester) async {
      await tester.pumpWidget(_wrap(
        ThemeCard(theme: _theme(), isActive: false, onApply: () {}),
      ));
      expect(find.text('Apply'), findsOneWidget);
    });

    testWidgets('does not show Apply button when theme is active',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ThemeCard(theme: _theme(), isActive: true, onApply: () {}),
      ));
      expect(find.text('Apply'), findsNothing);
    });

    testWidgets('calls onApply when Apply button is tapped', (tester) async {
      var applied = false;
      await tester.pumpWidget(_wrap(
        ThemeCard(theme: _theme(), isActive: false, onApply: () => applied = true),
      ));

      await tester.tap(find.text('Apply'));
      await tester.pump();

      expect(applied, isTrue);
    });
  });
}
