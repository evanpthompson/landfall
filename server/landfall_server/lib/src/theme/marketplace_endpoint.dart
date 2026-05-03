import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../profile/profile_endpoint.dart' show NotFoundException;

/// Marketplace-specific theme queries.
///
/// Complements [ThemeEndpoint] with purchase-awareness. All read methods work
/// unauthenticated; ownership flags are silently false when the caller is not
/// authenticated.
class MarketplaceEndpoint extends Endpoint {
  /// Returns all themes where [LandfallTheme.isMarketplace] is true, ordered
  /// by name. Each entry carries an [MarketplaceThemeInfo.isOwned] flag based
  /// on the authenticated caller's purchase history.
  Future<List<MarketplaceThemeInfo>> listMarketplaceThemes(
    Session session,
  ) async {
    final themes = await LandfallTheme.db.find(
      session,
      where: (t) => t.isMarketplace.equals(true),
      orderBy: (t) => t.name,
    );

    final ownedIds = await _ownedThemeIds(session);

    return themes
        .map((t) => _toInfo(t, isOwned: ownedIds.contains(t.id)))
        .toList();
  }

  /// Returns the marketplace entry for [themeId].
  ///
  /// Throws [NotFoundException] when [themeId] is unknown or is not a
  /// marketplace theme.
  Future<MarketplaceThemeInfo> getMarketplaceTheme(
    Session session,
    int themeId,
  ) async {
    final theme = await LandfallTheme.db.findById(session, themeId);
    if (theme == null || !theme.isMarketplace) {
      throw NotFoundException('Marketplace theme id=$themeId not found.');
    }

    final ownedIds = await _ownedThemeIds(session);
    return _toInfo(theme, isOwned: ownedIds.contains(theme.id));
  }

  /// Returns all marketplace themes owned (purchased) by the authenticated
  /// caller. Returns an empty list for unauthenticated sessions.
  Future<List<MarketplaceThemeInfo>> getOwnedThemes(Session session) async {
    final userId = session.authenticated?.userIdentifier;
    if (userId == null) return [];

    final purchases = await ThemePurchase.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );
    if (purchases.isEmpty) return [];

    final themeIds = purchases.map((p) => p.themeId).toList();
    final themes = await LandfallTheme.db.find(
      session,
      where: (t) => t.id.inSet(themeIds.toSet()),
      orderBy: (t) => t.name,
    );

    return themes.map((t) => _toInfo(t, isOwned: true)).toList();
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

  Future<Set<int>> _ownedThemeIds(Session session) async {
    final userId = session.authenticated?.userIdentifier;
    if (userId == null) return {};

    final purchases = await ThemePurchase.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );
    return purchases.map((p) => p.themeId).toSet();
  }

  static MarketplaceThemeInfo _toInfo(
    LandfallTheme theme, {
    required bool isOwned,
  }) =>
      MarketplaceThemeInfo(
        id: theme.id!,
        slug: theme.slug,
        name: theme.name,
        schemaVersion: theme.schemaVersion,
        author: theme.author,
        description: theme.description,
        previewUrl: theme.previewUrl,
        tagsJson: theme.tagsJson,
        resolvedJson: theme.resolvedJson,
        priceUsd: theme.priceUsd,
        stripeProductId: theme.stripeProductId,
        isBuiltIn: theme.isBuiltIn,
        createdAt: theme.createdAt,
        isOwned: isOwned,
      );
}
