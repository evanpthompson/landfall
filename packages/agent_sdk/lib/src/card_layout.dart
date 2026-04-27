/// Size hint for how a card should be rendered on the display grid.
///
/// The display layout engine uses this as a preference, not a strict
/// constraint — final placement depends on available grid slots.
enum CardLayout {
  /// Occupies one grid cell. Good for compact info: a single metric, a count.
  small,

  /// Occupies two grid cells. The default for most agent-pushed cards.
  medium,

  /// Occupies four grid cells (2×2). Good for rich content: summaries, lists.
  large,

  /// Occupies the full display width. Reserved for high-priority alerts.
  full,

  /// Renders in the ghost ticker strip at the bottom of the display.
  ///
  /// Ticker cards are NOT placed in the card grid. They appear in a scrolling
  /// strip overlay and expire in 30 seconds by default. The [persistent] flag
  /// is invalid for ticker cards — use [LandfallClient.pushTicker] instead.
  ticker;
}
