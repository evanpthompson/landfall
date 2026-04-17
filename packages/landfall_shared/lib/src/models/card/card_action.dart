/// A tappable action rendered on a card.
///
/// Actions are optional. When present they appear as buttons or
/// icon controls below the card body. The [type] field determines
/// how the display handles the tap.
class CardAction {
  const CardAction({
    required this.id,
    required this.label,
    required this.type,
    this.payload,
  });

  /// Unique identifier for this action within the card.
  final String id;

  /// Human-readable label shown on the button.
  final String label;

  /// How the display handles this action when tapped.
  final CardActionType type;

  /// Optional data the action handler needs (e.g. a URL, a card ID).
  final String? payload;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'type': type.name,
        if (payload != null) 'payload': payload,
      };

  factory CardAction.fromJson(Map<String, dynamic> json) => CardAction(
        id: json['id'] as String,
        label: json['label'] as String,
        type: CardActionType.values.byName(json['type'] as String),
        payload: json['payload'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardAction &&
          id == other.id &&
          label == other.label &&
          type == other.type &&
          payload == other.payload;

  @override
  int get hashCode => Object.hash(id, label, type, payload);

  @override
  String toString() => 'CardAction(id: $id, label: $label, type: $type)';
}

/// The type of action a [CardAction] triggers.
enum CardActionType {
  /// Open a URL in the system browser.
  openUrl,

  /// Dismiss the card programmatically.
  dismiss,

  /// Trigger a webhook or custom handler registered by the agent.
  webhook,

  /// Navigate to a settings screen.
  openSettings,
}
