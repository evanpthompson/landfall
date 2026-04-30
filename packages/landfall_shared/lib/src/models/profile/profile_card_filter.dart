import 'package:landfall_shared/src/models/card/card_mood.dart';

/// Restricts which agent cards appear when a profile is active.
///
/// All fields are optional. A null value means "no restriction on this
/// dimension". An empty list for [allowedMoods] or [allowedSources] would
/// block all cards — use null (or [ProfileCardFilter.all]) to allow all.
class ProfileCardFilter {
  const ProfileCardFilter({
    this.allowedMoods,
    this.allowedSources,
    this.maxCards,
  });

  /// A filter that allows all cards through with no cap. The default for new
  /// profiles.
  static const ProfileCardFilter all = ProfileCardFilter();

  /// Mood values that may appear in this profile. Null = all moods allowed.
  final List<CardMood>? allowedMoods;

  /// Source prefixes that may appear in this profile. Null = all sources.
  ///
  /// Matching is prefix-based: `'agent.homekit'` matches any card whose
  /// [source] starts with `'agent.homekit'`.
  final List<String>? allowedSources;

  /// Maximum number of agent cards shown at once. System cards (clock, weather,
  /// calendar, photos) are not counted against this cap. Null = no cap.
  final int? maxCards;

  /// Returns true when a card with the given [mood] and [source] passes this
  /// filter.
  bool allows({required String source, required CardMood mood}) {
    if (allowedMoods != null && !allowedMoods!.contains(mood)) return false;
    if (allowedSources != null) {
      final allowed =
          allowedSources!.any((prefix) => source.startsWith(prefix));
      if (!allowed) return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
        if (allowedMoods != null)
          'allowedMoods': allowedMoods!.map((m) => m.name).toList(),
        if (allowedSources != null) 'allowedSources': allowedSources,
        if (maxCards != null) 'maxCards': maxCards,
      };

  factory ProfileCardFilter.fromJson(Map<String, dynamic> json) =>
      ProfileCardFilter(
        allowedMoods: (json['allowedMoods'] as List<dynamic>?)
            ?.map((e) => CardMood.values.byName(e as String))
            .toList(),
        allowedSources: (json['allowedSources'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        maxCards: json['maxCards'] as int?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileCardFilter &&
          _listEqual(allowedMoods, other.allowedMoods) &&
          _listEqual(allowedSources, other.allowedSources) &&
          maxCards == other.maxCards;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(allowedMoods ?? []),
        Object.hashAll(allowedSources ?? []),
        maxCards,
      );

  static bool _listEqual<T>(List<T>? a, List<T>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
