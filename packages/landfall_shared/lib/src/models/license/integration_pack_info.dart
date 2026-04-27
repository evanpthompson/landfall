/// Metadata for an integration pack in the marketplace.
///
/// [isOwned] is set by the server when the response is scoped to an
/// authenticated user — it reflects whether that user has purchased the pack
/// or received it as part of a Founding Member entitlement.
class IntegrationPackInfo {
  const IntegrationPackInfo({
    required this.packId,
    required this.name,
    required this.description,
    required this.version,
    required this.priceUsd,
    required this.authorName,
    this.iconUrl,
    required this.isOwned,
  });

  final String packId;
  final String name;
  final String description;
  final String version;
  final double priceUsd;
  final String authorName;
  final String? iconUrl;
  final bool isOwned;

  IntegrationPackInfo copyWith({
    String? packId,
    String? name,
    String? description,
    String? version,
    double? priceUsd,
    String? authorName,
    String? iconUrl,
    bool? isOwned,
  }) {
    return IntegrationPackInfo(
      packId: packId ?? this.packId,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      priceUsd: priceUsd ?? this.priceUsd,
      authorName: authorName ?? this.authorName,
      iconUrl: iconUrl ?? this.iconUrl,
      isOwned: isOwned ?? this.isOwned,
    );
  }
}
