import 'card_layout.dart';
import 'card_priority.dart';

/// A card that has been pushed to or retrieved from a Landfall display.
///
/// Returned by [LandfallClient.push], [LandfallClient.update], and entries
/// in [LandfallClient.listCards].
class PushedCard {
  const PushedCard({
    required this.cardId,
    required this.source,
    required this.title,
    required this.layout,
    required this.priority,
    required this.persistent,
    required this.createdAt,
    this.body,
    this.expiresAt,
    this.dismissedAt,
  });

  /// The stable external ID for this card. Pass to [LandfallClient.update]
  /// or [LandfallClient.dismiss] to target this card.
  final String cardId;

  final String source;
  final String title;
  final String? body;
  final CardLayout layout;
  final CardPriority priority;

  /// Explicit expiry timestamp, if set on push.
  final DateTime? expiresAt;

  final bool persistent;
  final DateTime createdAt;

  /// Non-null if this card has been dismissed by the user.
  final DateTime? dismissedAt;

  /// Whether this card is currently active (not dismissed, not expired).
  ///
  /// Expiry is authoritative server-side — this is a client-side helper only.
  bool isActive(DateTime now) {
    if (dismissedAt != null) return false;
    if (persistent) return true;
    if (expiresAt != null) return now.isBefore(expiresAt!);
    return true;
  }

  factory PushedCard.fromJson(Map<String, dynamic> json) {
    final layoutName = json['layout'] as String? ?? 'medium';
    final priorityName = json['priority'] as String? ?? 'normal';
    return PushedCard(
      cardId: json['externalId'] as String,
      source: json['source'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      layout: CardLayout.values.firstWhere(
        (l) => l.name == layoutName,
        orElse: () => CardLayout.medium,
      ),
      priority: CardPriority.values.firstWhere(
        (p) => p.name == priorityName,
        orElse: () => CardPriority.normal,
      ),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      persistent: json['persistent'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      dismissedAt: json['dismissedAt'] != null
          ? DateTime.parse(json['dismissedAt'] as String)
          : null,
    );
  }

  @override
  String toString() =>
      'PushedCard(cardId: $cardId, source: $source, title: $title, '
      'priority: $priority, persistent: $persistent)';
}
