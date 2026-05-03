import 'theme_info.dart';

/// Client-side marketplace entry: a [ThemeInfo] plus purchase metadata.
class MarketplaceThemeInfo {
  const MarketplaceThemeInfo({
    required this.theme,
    this.priceUsd,
    this.stripeProductId,
    required this.isOwned,
  });

  /// Full theme data (tokens, slug, name, etc).
  final ThemeInfo theme;

  /// Price in cents (e.g. 499 = $4.99). Null or 0 means free.
  final int? priceUsd;

  /// Stripe product ID for checkout integration. Null for free themes.
  final String? stripeProductId;

  /// Whether the currently authenticated user owns this theme.
  final bool isOwned;

  bool get isFree => (priceUsd ?? 0) == 0;

  /// Formatted price string, e.g. "$4.99" or "Free".
  String get displayPrice {
    if (isFree) return 'Free';
    final dollars = (priceUsd! / 100).toStringAsFixed(2);
    return '\$$dollars';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketplaceThemeInfo &&
          theme == other.theme &&
          priceUsd == other.priceUsd &&
          isOwned == other.isOwned;

  @override
  int get hashCode => Object.hash(theme, priceUsd, isOwned);
}
