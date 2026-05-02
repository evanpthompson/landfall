import 'package:flutter/material.dart';
import 'package:landfall_shared/landfall_shared.dart' hide Card;

/// Wraps [child] with mood-driven visual treatment derived from [tokens].
///
/// Applies to any card in the grid:
///   - [CardMood.urgent] / [CardMood.celebratory] / [CardMood.success] —
///     uniform scale transform when the token value is above 1.0
///   - [CardMood.muted] — opacity reduction per [LandfallThemeTokens.moodMutedOpacity]
///   - [CardMood.normal] — pass-through, no extra decoration
///
/// Border and fill colour overrides for each mood are exposed via
/// [CardMoodDecoration.borderColor] and [CardMoodDecoration.fillColor] so the
/// card renderer can read them directly without querying this widget.
class CardMoodDecoration extends StatelessWidget {
  const CardMoodDecoration({
    super.key,
    required this.mood,
    required this.tokens,
    required this.child,
  });

  final CardMood mood;
  final LandfallThemeTokens tokens;
  final Widget child;

  /// The border colour override for [mood], or null for [CardMood.normal].
  Color? get borderColor {
    final hex = switch (mood) {
      CardMood.urgent => tokens.moodUrgentBorderColor,
      CardMood.celebratory => tokens.moodCelebratoryBorderColor,
      CardMood.success => tokens.moodSuccessBorderColor,
      CardMood.muted => tokens.moodMutedBorderColor,
      CardMood.normal => null,
    };
    return hex == null ? null : _parseHex(hex);
  }

  /// The fill colour override for [mood], or null for [CardMood.normal].
  Color? get fillColor {
    final hex = switch (mood) {
      CardMood.urgent => tokens.moodUrgentFillColor,
      CardMood.celebratory => tokens.moodCelebratoryFillColor,
      CardMood.success => tokens.moodSuccessFillColor,
      CardMood.muted => tokens.moodMutedFillColor,
      CardMood.normal => null,
    };
    return hex == null ? null : _parseHex(hex);
  }

  @override
  Widget build(BuildContext context) {
    Widget result = child;

    // Opacity — only muted reduces below 1.0
    if (mood == CardMood.muted) {
      result = Opacity(opacity: tokens.moodMutedOpacity, child: result);
    }

    // Scale — applied when token is meaningfully above 1.0
    final scale = _scaleFor(mood);
    if (scale > 1.0) {
      result = Transform.scale(
        key: const Key('card_mood_scale'),
        scale: scale,
        child: result,
      );
    }

    return result;
  }

  double _scaleFor(CardMood mood) => switch (mood) {
        CardMood.urgent => tokens.moodUrgentScale,
        CardMood.celebratory => tokens.moodCelebratoryScale,
        CardMood.success => tokens.moodSuccessScale,
        CardMood.muted || CardMood.normal => 1.0,
      };

  static Color _parseHex(String hex) {
    final clean = hex.replaceFirst('#', '');
    final value = int.tryParse(
      clean.length == 6 ? 'FF$clean' : clean,
      radix: 16,
    );
    return Color(value ?? 0xFF1a1a1a);
  }
}
