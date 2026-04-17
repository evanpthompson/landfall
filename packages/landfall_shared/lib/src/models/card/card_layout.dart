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
  full;

  /// Whether this layout spans more than a single cell.
  bool get isMultiCell => this != CardLayout.small;
}
