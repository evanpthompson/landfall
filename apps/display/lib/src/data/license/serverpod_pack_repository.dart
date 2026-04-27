import 'package:landfall_client/landfall_client.dart';
import 'package:landfall_shared/landfall_shared.dart';

/// Production [PackRepository] backed by [PackEndpoint].
class ServerpodPackRepository implements PackRepository {
  const ServerpodPackRepository(this._client);

  final Client _client;

  @override
  Future<List<IntegrationPackInfo>> listPacks() async {
    final packs = await _client.pack.listPacks();
    return packs.map(_fromResponse).toList();
  }

  @override
  Future<List<IntegrationPackInfo>> getOwnedPacks() async {
    final packs = await _client.pack.getOwnedPacks();
    return packs.map(_fromResponse).toList();
  }

  IntegrationPackInfo _fromResponse(PackInfoResponse r) {
    return IntegrationPackInfo(
      packId: r.packId,
      name: r.name,
      description: r.description,
      version: r.version,
      priceUsd: r.priceUsd,
      authorName: r.authorName,
      iconUrl: r.iconUrl,
      isOwned: r.isOwned,
    );
  }
}
