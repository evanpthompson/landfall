import 'card_action.dart';
import 'card_layout.dart';
import 'card_priority.dart';

/// An immutable card payload ready to push to Landfall.
///
/// Build one with [CardDraft.build]:
///
/// ```dart
/// final draft = CardDraft.build()
///   .title('Flight DEN→LAX dropped to \$287')
///   .body('Round trip, June 14. Price valid ~4 hours.')
///   .priority(CardPriority.ephemeral)
///   .expires(const Duration(hours: 4));
/// ```
class CardDraft {
  const CardDraft._({
    required this.title,
    required this.source,
    this.body,
    this.data,
    this.layout = CardLayout.medium,
    this.priority = CardPriority.normal,
    this.expiresAt,
    this.isPersistent = false,
    this.cardId,
    this.actions,
  });

  /// Primary display text. Required.
  final String title;

  /// Agent source identifier. Convention: `"agent.<name>"`.
  final String source;

  final String? body;
  final Map<String, dynamic>? data;
  final CardLayout layout;
  final CardPriority priority;

  /// Explicit expiry timestamp. When set, overrides [priority] default TTL.
  final DateTime? expiresAt;

  /// When true the card never auto-expires. Survives all default TTLs.
  final bool isPersistent;

  /// Stable identifier for this card slot. Re-pushing with the same [cardId]
  /// updates the card in-place rather than creating a duplicate.
  final String? cardId;

  final List<CardAction>? actions;

  /// Returns a new [CardDraftBuilder] for constructing a [CardDraft].
  static CardDraftBuilder build() => CardDraftBuilder._();

  Map<String, dynamic> toRequestJson() => {
        '__className__': 'CardPushRequest',
        'source': source,
        'title': title,
        if (body != null) 'body': body,
        if (data != null) 'dataJson': _encodeData(data!),
        'layout': layout.name,
        'priority': priority.name,
        if (expiresAt != null) 'expiresAt': expiresAt!.toUtc().toIso8601String(),
        if (isPersistent) 'persistent': true,
        if (cardId != null) 'externalId': cardId,
        if (actions != null)
          'actionsJson': _encodeActions(actions!),
      };

  static String _encodeData(Map<String, dynamic> data) {
    final sb = StringBuffer('{');
    var first = true;
    data.forEach((k, v) {
      if (!first) sb.write(',');
      sb.write('"${_escape(k)}":${_encodeValue(v)}');
      first = false;
    });
    sb.write('}');
    return sb.toString();
  }

  static String _encodeActions(List<CardAction> actions) {
    final parts = actions.map((a) {
      final j = a.toJson();
      return _encodeMap(j);
    }).join(',');
    return '[$parts]';
  }

  static String _encodeMap(Map<String, dynamic> m) {
    final sb = StringBuffer('{');
    var first = true;
    m.forEach((k, v) {
      if (!first) sb.write(',');
      sb.write('"${_escape(k)}":${_encodeValue(v)}');
      first = false;
    });
    sb.write('}');
    return sb.toString();
  }

  static String _encodeValue(dynamic v) {
    if (v == null) return 'null';
    if (v is bool) return v ? 'true' : 'false';
    if (v is num) return v.toString();
    if (v is String) return '"${_escape(v)}"';
    if (v is Map<String, dynamic>) return _encodeMap(v);
    if (v is List) {
      return '[${v.map(_encodeValue).join(',')}]';
    }
    return '"${_escape(v.toString())}"';
  }

  static String _escape(String s) =>
      s.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
}

/// Fluent builder for [CardDraft].
///
/// Obtain one via [CardDraft.build]. All setters return `this` for chaining.
/// Call [CardDraftBuilder.call] or the implicit `build()` to get a [CardDraft].
///
/// The only required field is [CardDraftBuilder.title]. [CardDraftBuilder.source]
/// defaults to `'agent.sdk'` if not set.
class CardDraftBuilder {
  CardDraftBuilder._();

  String? _title;
  String _source = 'agent.sdk';
  String? _body;
  Map<String, dynamic>? _data;
  CardLayout _layout = CardLayout.medium;
  CardPriority _priority = CardPriority.normal;
  DateTime? _expiresAt;
  bool _isPersistent = false;
  String? _cardId;
  List<CardAction>? _actions;

  CardDraftBuilder title(String value) {
    _title = value;
    return this;
  }

  /// Sets the agent source identifier. Default: `'agent.sdk'`.
  ///
  /// Convention: `"agent.<name>"` — e.g. `"agent.myapp"`.
  CardDraftBuilder source(String value) {
    _source = value;
    return this;
  }

  CardDraftBuilder body(String value) {
    _body = value;
    return this;
  }

  CardDraftBuilder data(Map<String, dynamic> value) {
    _data = value;
    return this;
  }

  CardDraftBuilder layout(CardLayout value) {
    _layout = value;
    return this;
  }

  CardDraftBuilder priority(CardPriority value) {
    _priority = value;
    return this;
  }

  /// Sets expiry relative to now. Overrides [priority] default TTL.
  CardDraftBuilder expires(Duration ttl) {
    _expiresAt = DateTime.now().toUtc().add(ttl);
    return this;
  }

  /// Sets an explicit expiry timestamp.
  CardDraftBuilder expiresAt(DateTime value) {
    _expiresAt = value.toUtc();
    return this;
  }

  /// The card never auto-expires. Stays until dismissed or replaced.
  CardDraftBuilder persistent() {
    _isPersistent = true;
    return this;
  }

  /// Stable slot identifier. Re-pushing with the same ID updates in-place.
  CardDraftBuilder cardId(String value) {
    _cardId = value;
    return this;
  }

  CardDraftBuilder actions(List<CardAction> value) {
    _actions = value;
    return this;
  }

  /// Builds the [CardDraft]. Throws if [title] was not set.
  CardDraft call() {
    if (_title == null) throw StateError('CardDraftBuilder: title is required.');
    return CardDraft._(
      title: _title!,
      source: _source,
      body: _body,
      data: _data,
      layout: _layout,
      priority: _priority,
      expiresAt: _expiresAt,
      isPersistent: _isPersistent,
      cardId: _cardId,
      actions: _actions,
    );
  }
}
