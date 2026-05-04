import 'package:landfall_client/landfall_client.dart' as client hide LandfallTheme;
import 'package:landfall_shared/landfall_shared.dart';

/// Production [MarketplaceRepository] backed by [MarketplaceEndpoint].
class ServerpodMarketplaceRepository implements MarketplaceRepository {
  const ServerpodMarketplaceRepository(this._client);

  final client.Client _client;

  @override
  Future<List<MarketplaceThemeInfo>> listMarketplaceThemes() async {
    final entries = await _client.marketplace.listMarketplaceThemes();
    return entries.map(_toDomain).toList();
  }

  @override
  Future<MarketplaceThemeInfo> getMarketplaceTheme(int themeId) async {
    final entry = await _client.marketplace.getMarketplaceTheme(themeId);
    return _toDomain(entry);
  }

  @override
  Future<List<MarketplaceThemeInfo>> getOwnedThemes() async {
    final entries = await _client.marketplace.getOwnedThemes();
    return entries.map(_toDomain).toList();
  }

  static MarketplaceThemeInfo _toDomain(client.MarketplaceThemeInfo e) =>
      MarketplaceThemeInfo(
        theme: ThemeInfo.fromServerJson(
          id: e.id,
          slug: e.slug,
          name: e.name,
          schemaVersion: e.schemaVersion,
          author: e.author,
          description: e.description,
          previewUrl: e.previewUrl,
          tagsJson: e.tagsJson,
          isBuiltIn: e.isBuiltIn,
          resolvedJson: e.resolvedJson,
        ),
        priceUsd: e.priceUsd,
        stripeProductId: e.stripeProductId,
        isOwned: e.isOwned,
      );
}
