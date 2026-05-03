import 'package:landfall_shared/src/models/theme/marketplace_theme_info.dart';

/// Abstract interface for marketplace theme queries.
///
/// Implementations:
/// - [ServerpodMarketplaceRepository] — production, backed by [MarketplaceEndpoint]
abstract interface class MarketplaceRepository {
  /// Returns all marketplace themes, with ownership flags for the current user.
  Future<List<MarketplaceThemeInfo>> listMarketplaceThemes();

  /// Returns the marketplace entry for [themeId].
  ///
  /// Throws when [themeId] is unknown or not a marketplace theme.
  Future<MarketplaceThemeInfo> getMarketplaceTheme(int themeId);

  /// Returns all themes owned (purchased) by the current user.
  Future<List<MarketplaceThemeInfo>> getOwnedThemes();
}
