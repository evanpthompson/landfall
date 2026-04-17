import 'package:landfall_shared/src/models/dashboard/dashboard_slot.dart';

/// Configuration for a card placed at a specific slot on the display grid.
///
/// [id] uniquely identifies this card position within a [DashboardLayout].
/// [source] identifies the card type: `"system.clock"`, `"system.weather"`,
/// `"system.calendar"`, etc.
///
/// [visible] is a soft toggle — hidden cards remain in the layout but are
/// not rendered. This allows the user to temporarily disable a card without
/// losing its slot configuration.
class CardConfig {
  const CardConfig({
    required this.id,
    required this.source,
    required this.slot,
    this.visible = true,
  });

  /// Unique identifier for this card within its layout.
  ///
  /// Convention: `slot_<widget>` — e.g., `slot_clock`, `slot_weather_1`.
  final String id;

  /// The card type rendered in this slot.
  ///
  /// Convention: `"system.<widget>"` for built-in cards,
  /// `"agent.<name>"` for agent-pushed sources.
  final String source;

  /// The grid slot this card occupies.
  final DashboardSlot slot;

  /// Whether this card is currently visible on the display.
  ///
  /// Hidden cards retain their slot; toggling [visible] back to true
  /// restores the card without reconfiguring the slot.
  final bool visible;

  CardConfig copyWith({
    String? id,
    String? source,
    DashboardSlot? slot,
    bool? visible,
  }) {
    return CardConfig(
      id: id ?? this.id,
      source: source ?? this.source,
      slot: slot ?? this.slot,
      visible: visible ?? this.visible,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'slot': slot.toJson(),
        'visible': visible,
      };

  factory CardConfig.fromJson(Map<String, dynamic> json) => CardConfig(
        id: json['id'] as String,
        source: json['source'] as String,
        slot: DashboardSlot.fromJson(json['slot'] as Map<String, dynamic>),
        visible: json['visible'] as bool? ?? true,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardConfig &&
          id == other.id &&
          source == other.source &&
          slot == other.slot &&
          visible == other.visible;

  @override
  int get hashCode => Object.hash(id, source, slot, visible);

  @override
  String toString() =>
      'CardConfig(id: $id, source: $source, slot: $slot, visible: $visible)';
}
