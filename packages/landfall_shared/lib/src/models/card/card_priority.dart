/// Controls how long a card stays on the display when no explicit [expiresAt]
/// is set and [persistent] is false.
///
/// Default TTLs (user-configurable in Settings):
/// - [ephemeral]  → 2 hours   (alerts, time-sensitive notifications)
/// - [normal]     → 24 hours  (standard agent output, informational cards)
/// - [persistent] → never     (synonym for setting persistent: true on the card)
enum CardPriority {
  ephemeral,
  normal,
  persistent;

  /// The default TTL duration for this priority tier.
  /// Returns null for [persistent] (no automatic expiry).
  Duration? get defaultTtl => switch (this) {
        CardPriority.ephemeral => const Duration(hours: 2),
        CardPriority.normal => const Duration(hours: 24),
        CardPriority.persistent => null,
      };

  /// Whether this priority implies the card should never auto-expire.
  bool get neverExpires => this == CardPriority.persistent;
}
