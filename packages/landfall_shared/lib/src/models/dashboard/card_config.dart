import 'package:landfall_shared/src/models/card/card_mood.dart';
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
///
/// [locked] prevents drag and resize in the layout editor. Locked cards can
/// only be moved after explicitly unlocking from the card HUD.
///
/// [mood] declares the semantic state of this card. System cards always use
/// [CardMood.normal]. Agent-pushed cards carry the mood set at push time.
/// The active theme maps moods to visual treatment (border colour, fill,
/// pulse animation, etc.).
///
/// [displayConfig] holds card-type-specific display parameters documented in
/// `docs/layout-schema.md`. Validated server-side against each source's
/// registered config schema. For system cards the map is always type-safe;
/// for agent cards the map may be empty.
class CardConfig {
  const CardConfig({
    required this.id,
    required this.source,
    required this.slot,
    this.visible = true,
    this.locked = false,
    this.mood = CardMood.normal,
    this.displayConfig = const {},
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

  /// Whether this card is locked against drag and resize in the layout editor.
  ///
  /// Locked cards display a lock badge in the editor and ignore pan/resize
  /// gestures. Unlocking requires an explicit action in the card HUD.
  final bool locked;

  /// Semantic mood — how the theme should visually render this card.
  ///
  /// Agents declare mood when pushing; system cards are always [CardMood.normal].
  /// The active theme maps each mood value to border colour, fill, animations,
  /// and scale via the `moods.*` token set.
  final CardMood mood;

  /// Card-type-specific display parameters.
  ///
  /// Each system card source defines its own accepted keys and value types,
  /// documented in `docs/layout-schema.md` under `displayConfig by card type`.
  /// Unknown keys are silently ignored by the renderer.
  final Map<String, dynamic> displayConfig;

  CardConfig copyWith({
    String? id,
    String? source,
    DashboardSlot? slot,
    bool? visible,
    bool? locked,
    CardMood? mood,
    Map<String, dynamic>? displayConfig,
  }) {
    return CardConfig(
      id: id ?? this.id,
      source: source ?? this.source,
      slot: slot ?? this.slot,
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
      mood: mood ?? this.mood,
      displayConfig: displayConfig ?? this.displayConfig,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'slot': slot.toJson(),
        'visible': visible,
        'locked': locked,
        'mood': mood.name,
        'displayConfig': displayConfig,
      };

  factory CardConfig.fromJson(Map<String, dynamic> json) => CardConfig(
        id: json['id'] as String,
        source: json['source'] as String,
        slot: DashboardSlot.fromJson(json['slot'] as Map<String, dynamic>),
        visible: json['visible'] as bool? ?? true,
        locked: json['locked'] as bool? ?? false,
        mood: json['mood'] != null
            ? CardMood.values.byName(json['mood'] as String)
            : CardMood.normal,
        displayConfig:
            (json['displayConfig'] as Map<String, dynamic>?) ?? const {},
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardConfig &&
          id == other.id &&
          source == other.source &&
          slot == other.slot &&
          visible == other.visible &&
          locked == other.locked &&
          mood == other.mood &&
          _mapsEqual(displayConfig, other.displayConfig);

  @override
  int get hashCode =>
      Object.hash(id, source, slot, visible, locked, mood, displayConfig);

  @override
  String toString() =>
      'CardConfig(id: $id, source: $source, slot: $slot, '
      'visible: $visible, locked: $locked, mood: ${mood.name})';

  static bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
