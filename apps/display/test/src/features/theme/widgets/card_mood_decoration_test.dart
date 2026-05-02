import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/features/theme/widgets/card_mood_decoration.dart';

// ── fixtures ──────────────────────────────────────────────────────────────────

LandfallThemeTokens _tokens({
  double urgentScale = 1.04,
  bool urgentPulse = true,
  double celebratoryScale = 1.02,
  double successScale = 1.0,
  double mutedOpacity = 0.45,
}) =>
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
      colorAccent: '#7C3AED',
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
      moodUrgentPulse: urgentPulse,
      moodUrgentScale: urgentScale,
      moodUrgentAnimation: 'pulse',
      moodCelebratoryBorderColor: '#ffcc00',
      moodCelebratoryFillColor: '#332200',
      moodCelebratoryPulse: false,
      moodCelebratoryScale: celebratoryScale,
      moodCelebratoryAnimation: 'confetti',
      moodSuccessBorderColor: '#00ff00',
      moodSuccessFillColor: '#003300',
      moodSuccessPulse: false,
      moodSuccessScale: successScale,
      moodSuccessAnimation: 'none',
      moodMutedBorderColor: '#555555',
      moodMutedFillColor: '#1a1a1a',
      moodMutedPulse: false,
      moodMutedScale: 1.0,
      moodMutedAnimation: 'none',
      moodMutedOpacity: mutedOpacity,
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: LandfallTheme.dark,
      home: Scaffold(body: Center(child: child)),
    );

Widget _mood(CardMood mood, LandfallThemeTokens tokens) =>
    CardMoodDecoration(
      mood: mood,
      tokens: tokens,
      child: const Text('card content'),
    );

// ── helpers ───────────────────────────────────────────────────────────────────

const _scaleKey = Key('card_mood_scale');

/// Returns the scale [Transform] inserted by [CardMoodDecoration], if any.
Transform? _findMoodScale(WidgetTester tester) {
  final finder = find.byKey(_scaleKey);
  if (tester.any(finder)) return tester.widget<Transform>(finder);
  return null;
}

/// Returns the scale factor from a uniform scale [Matrix4].
double _extractScale(Matrix4 m) => m.storage[0];

void main() {
  group('CardMoodDecoration', () {
    testWidgets('always renders the child', (tester) async {
      for (final mood in CardMood.values) {
        await tester.pumpWidget(_wrap(_mood(mood, _tokens())));
        expect(find.text('card content'), findsOneWidget,
            reason: 'child missing for mood $mood');
      }
    });

    // ── normal ──────────────────────────────────────────────────────────────

    group('normal mood', () {
      testWidgets('does not apply Opacity', (tester) async {
        await tester.pumpWidget(_wrap(_mood(CardMood.normal, _tokens())));
        // Opacity(opacity: 1.0) may appear from the theme; we check ours is not
        // reducing it below 1.
        final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
        for (final o in opacities) {
          expect(o.opacity, 1.0,
              reason: 'normal mood must not reduce opacity');
        }
      });

      testWidgets('does not apply non-unit scale Transform', (tester) async {
        await tester.pumpWidget(_wrap(_mood(CardMood.normal, _tokens())));
        expect(_findMoodScale(tester), isNull);
      });
    });

    // ── urgent ──────────────────────────────────────────────────────────────

    group('urgent mood', () {
      testWidgets('applies scale from tokens', (tester) async {
        await tester.pumpWidget(
          _wrap(_mood(CardMood.urgent, _tokens(urgentScale: 1.04))),
        );
        final t = _findMoodScale(tester);
        expect(t, isNotNull, reason: 'urgent should apply a scale Transform');
        expect(_extractScale(t!.transform), closeTo(1.04, 0.001));
      });

      testWidgets('does not apply Opacity', (tester) async {
        await tester.pumpWidget(_wrap(_mood(CardMood.urgent, _tokens())));
        final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
        for (final o in opacities) {
          expect(o.opacity, 1.0);
        }
      });
    });

    // ── celebratory ──────────────────────────────────────────────────────────

    group('celebratory mood', () {
      testWidgets('applies scale from tokens', (tester) async {
        await tester.pumpWidget(
          _wrap(_mood(CardMood.celebratory, _tokens(celebratoryScale: 1.02))),
        );
        final t = _findMoodScale(tester);
        expect(t, isNotNull);
        expect(_extractScale(t!.transform), closeTo(1.02, 0.001));
      });
    });

    // ── success ──────────────────────────────────────────────────────────────

    group('success mood', () {
      testWidgets('applies no transform when scale is 1.0', (tester) async {
        await tester.pumpWidget(
          _wrap(_mood(CardMood.success, _tokens(successScale: 1.0))),
        );
        expect(_findMoodScale(tester), isNull);
      });

      testWidgets('applies scale when token is above 1.0', (tester) async {
        await tester.pumpWidget(
          _wrap(_mood(CardMood.success, _tokens(successScale: 1.03))),
        );
        final t = _findMoodScale(tester);
        expect(t, isNotNull);
        expect(_extractScale(t!.transform), closeTo(1.03, 0.001));
      });
    });

    // ── muted ────────────────────────────────────────────────────────────────

    group('muted mood', () {
      testWidgets('applies Opacity from tokens', (tester) async {
        await tester.pumpWidget(
          _wrap(_mood(CardMood.muted, _tokens(mutedOpacity: 0.45))),
        );
        final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
        final ours = opacities.where((o) => o.opacity < 1.0).toList();
        expect(ours, hasLength(1));
        expect(ours.first.opacity, closeTo(0.45, 0.001));
      });

      testWidgets('does not apply non-unit scale Transform', (tester) async {
        await tester.pumpWidget(_wrap(_mood(CardMood.muted, _tokens())));
        expect(_findMoodScale(tester), isNull);
      });
    });
  });
}
