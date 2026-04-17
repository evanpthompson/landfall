import 'package:landfall_shared/src/models/card/card_action.dart';
import 'package:landfall_shared/src/models/card/card_layout.dart';
import 'package:landfall_shared/src/models/card/card_priority.dart';

/// The unified content model for Landfall.
///
/// Every piece of content on a Landfall display is a [Card] — whether it
/// originates from a built-in widget (clock, weather, calendar) or from
/// an external agent pushing content via the API.
///
/// ## Lifecycle
///
/// Cards are removed from the active display at the server's refresh cycle
/// (every 5 minutes) but retained in the database for card history. Expiry
/// is evaluated server-side, not via a client-side timer.
///
/// Expiry resolution order (most specific wins):
/// 1. [persistent] == true → never auto-expires
/// 2. [expiresAt] is set → expires at that exact timestamp
/// 3. Neither set → server applies [priority]'s default TTL
class Card {
  const Card({
    required this.id,
    required this.source,
    required this.title,
    required this.layout,
    required this.priority,
    required this.persistent,
    required this.createdAt,
    this.body,
    this.data,
    this.expiresAt,
    this.dismissedAt,
    this.actions,
  });

  /// Unique identifier for this card. Agent-pushed cards should use a
  /// stable ID to allow in-place updates (re-pushing with the same ID
  /// replaces the card rather than creating a duplicate).
  final String id;

  /// Identifies the origin of this card.
  ///
  /// Convention: `"system.<widget>"` for built-in widgets,
  /// `"agent.<name>"` for external agents.
  ///
  /// Examples: `"system.weather"`, `"agent.claude"`, `"skill.home_assistant"`
  final String source;

  /// Primary display text. Always present.
  final String title;

  /// Secondary display text. Optional.
  final String? body;

  /// Structured data for rich rendering templates.
  ///
  /// The display routes to a rendering template based on [source] and the
  /// shape of [data]. Agent-pushed cards without a matching template fall
  /// back to the [GenericAgentCard] renderer.
  final Map<String, dynamic>? data;

  /// Size hint for the display layout engine.
  final CardLayout layout;

  /// Controls default TTL when [expiresAt] is null and [persistent] is false.
  final CardPriority priority;

  /// When set, the card expires at exactly this time regardless of [priority].
  /// Null means apply the [priority] default TTL.
  final DateTime? expiresAt;

  /// When true, the card never auto-expires. It remains on the display until
  /// explicitly dismissed by the user or replaced by the agent (same [id]).
  ///
  /// Takes precedence over [expiresAt] and [priority].
  final bool persistent;

  /// Tappable actions rendered on the card. Optional.
  final List<CardAction>? actions;

  /// When this card was first created / pushed.
  final DateTime createdAt;

  /// Set when the user manually dismisses this card.
  /// A non-null value means the card is in history, not on the active display.
  final DateTime? dismissedAt;

  /// Whether this card is currently active (not dismissed, not expired).
  ///
  /// Note: expiry is authoritative on the server. This helper is for
  /// client-side display logic only and should not be used for data queries.
  bool isActive(DateTime now) {
    if (dismissedAt != null) return false;
    if (persistent) return true;
    if (expiresAt != null) return now.isBefore(expiresAt!);
    final ttl = priority.defaultTtl;
    if (ttl == null) return true;
    return now.isBefore(createdAt.add(ttl));
  }

  Card copyWith({
    String? id,
    String? source,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    CardLayout? layout,
    CardPriority? priority,
    DateTime? expiresAt,
    bool? persistent,
    List<CardAction>? actions,
    DateTime? createdAt,
    DateTime? dismissedAt,
  }) {
    return Card(
      id: id ?? this.id,
      source: source ?? this.source,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      layout: layout ?? this.layout,
      priority: priority ?? this.priority,
      expiresAt: expiresAt ?? this.expiresAt,
      persistent: persistent ?? this.persistent,
      actions: actions ?? this.actions,
      createdAt: createdAt ?? this.createdAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'title': title,
        if (body != null) 'body': body,
        if (data != null) 'data': data,
        'layout': layout.name,
        'priority': priority.name,
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
        'persistent': persistent,
        if (actions != null)
          'actions': actions!.map((a) => a.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        if (dismissedAt != null)
          'dismissedAt': dismissedAt!.toIso8601String(),
      };

  factory Card.fromJson(Map<String, dynamic> json) => Card(
        id: json['id'] as String,
        source: json['source'] as String,
        title: json['title'] as String,
        body: json['body'] as String?,
        data: json['data'] as Map<String, dynamic>?,
        layout: CardLayout.values.byName(json['layout'] as String),
        priority: CardPriority.values.byName(json['priority'] as String),
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
        persistent: json['persistent'] as bool? ?? false,
        actions: (json['actions'] as List<dynamic>?)
            ?.map((e) => CardAction.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        dismissedAt: json['dismissedAt'] != null
            ? DateTime.parse(json['dismissedAt'] as String)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Card &&
          id == other.id &&
          source == other.source &&
          title == other.title &&
          body == other.body &&
          layout == other.layout &&
          priority == other.priority &&
          expiresAt == other.expiresAt &&
          persistent == other.persistent &&
          createdAt == other.createdAt &&
          dismissedAt == other.dismissedAt;

  @override
  int get hashCode => Object.hash(
        id, source, title, body, layout, priority,
        expiresAt, persistent, createdAt, dismissedAt,
      );

  @override
  String toString() =>
      'Card(id: $id, source: $source, title: $title, priority: $priority, '
      'persistent: $persistent, expiresAt: $expiresAt)';
}
