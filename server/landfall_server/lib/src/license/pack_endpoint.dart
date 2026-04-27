import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Manages the integration pack marketplace catalog and per-user ownership.
class PackEndpoint extends Endpoint {
  /// Returns all active packs in the catalog, with ownership flags for the
  /// authenticated user. Anonymous sessions see all packs as unowned.
  Future<List<PackInfoResponse>> listPacks(Session session) async {
    final packs = await IntegrationPack.db.find(
      session,
      where: (t) => t.isActive.equals(true),
      orderBy: (t) => t.name,
    );

    final ownedIds = await _ownedPackIds(session);

    return packs
        .map(
          (p) => PackInfoResponse(
            packId: p.packId,
            name: p.name,
            description: p.description,
            version: p.version,
            priceUsd: p.priceUsd,
            authorName: p.authorName,
            iconUrl: p.iconUrl,
            stripePaymentLink: p.stripePaymentLink,
            isOwned: ownedIds.contains(p.packId),
          ),
        )
        .toList();
  }

  /// Returns packs owned by the authenticated user.
  ///
  /// Returns an empty list for anonymous sessions.
  Future<List<PackInfoResponse>> getOwnedPacks(Session session) async {
    final userId = session.authenticated?.userIdentifier;
    if (userId == null) return [];

    final owned = await OwnedPack.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );

    if (owned.isEmpty) return [];

    final packIds = owned.map((o) => o.packId).toSet();
    final packs = await IntegrationPack.db.find(
      session,
      where: (t) => t.isActive.equals(true),
    );

    return packs
        .where((p) => packIds.contains(p.packId))
        .map(
          (p) => PackInfoResponse(
            packId: p.packId,
            name: p.name,
            description: p.description,
            version: p.version,
            priceUsd: p.priceUsd,
            authorName: p.authorName,
            iconUrl: p.iconUrl,
            stripePaymentLink: p.stripePaymentLink,
            isOwned: true,
          ),
        )
        .toList();
  }

  Future<Set<String>> _ownedPackIds(Session session) async {
    final userId = session.authenticated?.userIdentifier;
    if (userId == null) return {};

    final owned = await OwnedPack.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );
    return owned.map((o) => o.packId).toSet();
  }
}
