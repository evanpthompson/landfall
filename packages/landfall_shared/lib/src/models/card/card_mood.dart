/// Semantic mood for a card — declares the nature of the content, not its
/// visual appearance. The active theme maps each mood to its visual treatment.
///
/// Agents set the mood when pushing a card. System cards always use [normal].
/// Profile card filters can allowlist specific moods via [ProfileCardFilter].
enum CardMood {
  /// Default — no special treatment. Used by all system cards and agent cards
  /// that do not declare a semantic state.
  normal,

  /// Requires attention. Use for problems, failures, or time-sensitive alerts.
  urgent,

  /// Positive outcome. Use for goals achieved, tasks completed, or good news.
  success,

  /// High-energy positive. Use for milestones, celebrations, or notable events.
  celebratory,

  /// Low-priority background awareness. Use for informational content that
  /// should not compete visually with higher-priority cards.
  muted,
}
