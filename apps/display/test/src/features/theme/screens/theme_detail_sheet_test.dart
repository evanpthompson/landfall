import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/features/theme/screens/theme_detail_sheet.dart';

// ── fixtures ──────────────────────────────────────────────────────────────────

LandfallThemeTokens _tokens() => const LandfallThemeTokens(
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
      colorAccent: '#00ffcc',
      colorAccentMuted: '#00aa88',
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

MarketplaceThemeInfo _entry({
  int priceUsd = 499,
  bool isOwned = false,
  String? description,
  String? author,
}) =>
    MarketplaceThemeInfo(
      theme: ThemeInfo(
        id: 42,
        slug: 'neon-arcade',
        name: 'Neon Arcade',
        schemaVersion: '1.0',
        author: author,
        description: description,
        isBuiltIn: false,
        tokens: _tokens(),
      ),
      priceUsd: priceUsd,
      isOwned: isOwned,
    );

Future<void> _show(WidgetTester tester, MarketplaceThemeInfo entry,
    {VoidCallback? onApply, VoidCallback? onPurchase}) async {
  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) {
      return Scaffold(
        body: ElevatedButton(
          onPressed: () => ThemeDetailSheet.show(
            context,
            entry: entry,
            onApply: onApply,
            onPurchase: onPurchase,
          ),
          child: const Text('open'),
        ),
      );
    }),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('ThemeDetailSheet', () {
    testWidgets('shows theme name', (tester) async {
      await _show(tester, _entry());
      expect(find.text('Neon Arcade'), findsOneWidget);
    });

    testWidgets('shows author when present', (tester) async {
      await _show(tester, _entry(author: 'studio-x'));
      expect(find.text('studio-x'), findsOneWidget);
    });

    testWidgets('shows description when present', (tester) async {
      await _show(tester, _entry(description: 'A neon theme for night owls.'));
      expect(find.text('A neon theme for night owls.'), findsOneWidget);
    });

    testWidgets('shows price for paid unowned theme', (tester) async {
      await _show(tester, _entry(priceUsd: 499));
      expect(find.text('\$4.99'), findsOneWidget);
    });

    testWidgets('shows Free label for free theme', (tester) async {
      await _show(tester, _entry(priceUsd: 0));
      expect(find.text('Free'), findsOneWidget);
    });

    testWidgets('shows Apply button for owned theme', (tester) async {
      await _show(tester, _entry(isOwned: true));
      expect(find.text('Apply'), findsOneWidget);
    });

    testWidgets('shows Purchase button for paid unowned theme', (tester) async {
      await _show(tester, _entry(priceUsd: 499));
      expect(find.text('Purchase'), findsOneWidget);
    });

    testWidgets('does not show Purchase button for owned theme', (tester) async {
      await _show(tester, _entry(isOwned: true));
      expect(find.text('Purchase'), findsNothing);
    });

    testWidgets('Apply button calls onApply', (tester) async {
      var called = false;
      await _show(tester, _entry(isOwned: true), onApply: () => called = true);
      await tester.tap(find.text('Apply'));
      expect(called, isTrue);
    });

    testWidgets('Purchase button calls onPurchase', (tester) async {
      var called = false;
      await _show(tester, _entry(priceUsd: 499),
          onPurchase: () => called = true);
      await tester.tap(find.text('Purchase'));
      expect(called, isTrue);
    });

    testWidgets('shows Apply button for free unowned theme', (tester) async {
      await _show(tester, _entry(priceUsd: 0));
      expect(find.text('Apply'), findsOneWidget);
    });
  });
}
