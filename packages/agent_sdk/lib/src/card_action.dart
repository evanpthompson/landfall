/// A tappable action rendered on a card.
class CardAction {
  const CardAction({
    required this.id,
    required this.label,
    required this.type,
    this.payload,
    this.requireConfirm = false,
  });

  final String id;
  final String label;
  final CardActionType type;

  /// Optional data for the action handler (e.g. a URL, a card ID).
  final String? payload;

  /// When true the display shows a confirmation dialog before executing.
  final bool requireConfirm;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'type': type.name,
        if (payload != null) 'payload': payload,
        if (requireConfirm) 'requireConfirm': requireConfirm,
      };
}

/// How the display handles a [CardAction] when tapped.
enum CardActionType {
  /// Open a URL in the system browser.
  openUrl,

  /// Dismiss the card.
  dismiss,

  /// Trigger a webhook registered by the agent.
  webhook,

  /// Navigate to a Landfall settings screen.
  openSettings,
}
