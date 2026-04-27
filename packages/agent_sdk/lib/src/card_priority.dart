/// Controls how long a card stays on the display when no explicit expiry is set.
///
/// Default TTLs (user-configurable in Landfall Settings):
/// - [ephemeral]  → 2 hours   (alerts, time-sensitive notifications)
/// - [normal]     → 24 hours  (standard agent output, informational cards)
/// - [persistent] → never     (synonym for calling [CardDraftBuilder.persistent])
enum CardPriority {
  ephemeral,
  normal,
  persistent,
}
