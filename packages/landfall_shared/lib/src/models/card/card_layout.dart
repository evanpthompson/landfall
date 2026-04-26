/// Size hint for how a card should be rendered on the display grid.
///
/// The display layout engine uses this as a preference, not a strict
/// constraint — final placement depends on available grid slots.
enum CardLayout {
  /// Occupies one grid cell. Good for compact info: time, single metric.
  small,

  /// Occupies two grid cells. The default for most agent-pushed cards.
  medium,

  /// Occupies four grid cells (2×2). Good for rich content: calendar, photos.
  large,

  /// Occupies the full display width. Reserved for high-priority alerts
  /// or immersive content.
  full,

  /// Renders in the ghost ticker strip at the bottom of the display.
  ///
  /// Ticker cards are NOT placed in the card grid. They route to a separate
  /// FIFO buffer (cap: 10) and scroll across a fixed strip overlay. Default
  /// TTL is 30 seconds. The [persistent] flag is invalid for ticker cards
  /// and is rejected server-side.
  ticker;

  /// Whether this layout spans more than a single grid cell.
  bool get isMultiCell =>
      this != CardLayout.small && this != CardLayout.ticker;

  /// Whether this layout renders in the ticker strip rather than the grid.
  bool get isTickerLayout => this == CardLayout.ticker;
}
