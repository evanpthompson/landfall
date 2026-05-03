import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/features/theme/widgets/marketplace_theme_card.dart';

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
    );

ThemeInfo _theme({String name = 'Neon Arcade', String? author}) => ThemeInfo(
      id: 1,
      slug: 'neon-arcade',
      name: name,
      schemaVersion: '1.0',
      author: author,
      isBuiltIn: false,
      tokens: _tokens(),
    );

MarketplaceThemeInfo _mktTheme({
  int priceUsd = 499,
  bool isOwned = false,
  String? author,
}) =>
    MarketplaceThemeInfo(
      theme: _theme(author: author),
      priceUsd: priceUsd,
      isOwned: isOwned,
    );

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 300, height: 300, child: child),
      ),
    );

void main() {
  group('MarketplaceThemeCard', () {
    testWidgets('renders the theme name', (tester) async {
      await tester.pumpWidget(_wrap(MarketplaceThemeCard(
        entry: _mktTheme(),
        onTap: () {},
      )));
      expect(find.text('Neon Arcade'), findsOneWidget);
    });

    testWidgets('renders author when provided', (tester) async {
      await tester.pumpWidget(_wrap(MarketplaceThemeCard(
        entry: _mktTheme(author: 'studio-x'),
        onTap: () {},
      )));
      expect(find.text('studio-x'), findsOneWidget);
    });

    testWidgets('does not render author when absent', (tester) async {
      await tester.pumpWidget(_wrap(MarketplaceThemeCard(
        entry: _mktTheme(),
        onTap: () {},
      )));
      // No author text node beyond the theme name
      expect(find.text('studio-x'), findsNothing);
    });

    testWidgets('shows formatted price for paid themes', (tester) async {
      await tester.pumpWidget(_wrap(MarketplaceThemeCard(
        entry: _mktTheme(priceUsd: 499),
        onTap: () {},
      )));
      expect(find.text('\$4.99'), findsOneWidget);
    });

    testWidgets('shows Free label when priceUsd is 0', (tester) async {
      await tester.pumpWidget(_wrap(MarketplaceThemeCard(
        entry: _mktTheme(priceUsd: 0),
        onTap: () {},
      )));
      expect(find.text('Free'), findsOneWidget);
    });

    testWidgets('shows Owned badge when isOwned is true', (tester) async {
      await tester.pumpWidget(_wrap(MarketplaceThemeCard(
        entry: _mktTheme(isOwned: true),
        onTap: () {},
      )));
      expect(find.text('Owned'), findsOneWidget);
    });

    testWidgets('does not show Owned badge when not owned', (tester) async {
      await tester.pumpWidget(_wrap(MarketplaceThemeCard(
        entry: _mktTheme(),
        onTap: () {},
      )));
      expect(find.text('Owned'), findsNothing);
    });

    testWidgets('calls onTap when card is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(MarketplaceThemeCard(
        entry: _mktTheme(),
        onTap: () => tapped = true,
      )));
      await tester.tap(find.byType(MarketplaceThemeCard));
      expect(tapped, isTrue);
    });
  });

  group('MarketplaceThemeInfo helpers', () {
    test('isFree is true when priceUsd is 0', () {
      expect(
        MarketplaceThemeInfo(
                theme: _theme(), priceUsd: 0, isOwned: false)
            .isFree,
        isTrue,
      );
    });

    test('isFree is true when priceUsd is null', () {
      expect(
        MarketplaceThemeInfo(theme: _theme(), isOwned: false).isFree,
        isTrue,
      );
    });

    test('isFree is false when priceUsd > 0', () {
      expect(
        MarketplaceThemeInfo(
                theme: _theme(), priceUsd: 499, isOwned: false)
            .isFree,
        isFalse,
      );
    });

    test('displayPrice returns Free for 0-price theme', () {
      expect(
        MarketplaceThemeInfo(theme: _theme(), priceUsd: 0, isOwned: false)
            .displayPrice,
        equals('Free'),
      );
    });

    test('displayPrice formats cents as dollars', () {
      expect(
        MarketplaceThemeInfo(theme: _theme(), priceUsd: 499, isOwned: false)
            .displayPrice,
        equals('\$4.99'),
      );
    });

    test('displayPrice formats 1000 cents as \$10.00', () {
      expect(
        MarketplaceThemeInfo(theme: _theme(), priceUsd: 1000, isOwned: false)
            .displayPrice,
        equals('\$10.00'),
      );
    });
  });
}
