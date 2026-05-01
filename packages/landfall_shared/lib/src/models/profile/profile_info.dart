import 'package:landfall_shared/src/models/dashboard/dashboard_layout.dart';
import 'package:landfall_shared/src/models/profile/profile_card_filter.dart';
import 'package:landfall_shared/src/models/profile/profile_schedule.dart';

/// Client-side representation of a named dashboard profile.
///
/// Decoupled from the Serverpod-generated [DashboardProfile] model — this is
/// the domain object used throughout the Flutter client.
class ProfileInfo {
  const ProfileInfo({
    required this.id,
    required this.name,
    required this.slug,
    required this.isActive,
    required this.layout,
    this.cardFilter = ProfileCardFilter.all,
    this.schedule,
    required this.sortOrder,
  });

  final int id;
  final String name;

  /// URL-safe slug derived from [name].
  final String slug;

  /// True when this profile is currently shown on the display.
  final bool isActive;

  /// The grid layout stored by this profile.
  final DashboardLayout layout;

  /// Which agent cards are visible when this profile is active.
  final ProfileCardFilter cardFilter;

  /// Optional automatic scheduling for this profile. Null = no schedule.
  final ProfileSchedule? schedule;

  /// Sort order in the profile list (ascending).
  final int sortOrder;

  ProfileInfo copyWith({
    int? id,
    String? name,
    String? slug,
    bool? isActive,
    DashboardLayout? layout,
    ProfileCardFilter? cardFilter,
    ProfileSchedule? schedule,
    int? sortOrder,
  }) {
    return ProfileInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      isActive: isActive ?? this.isActive,
      layout: layout ?? this.layout,
      cardFilter: cardFilter ?? this.cardFilter,
      schedule: schedule ?? this.schedule,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileInfo &&
          id == other.id &&
          name == other.name &&
          isActive == other.isActive &&
          layout == other.layout &&
          cardFilter == other.cardFilter &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode =>
      Object.hash(id, name, isActive, layout, cardFilter, sortOrder);

  @override
  String toString() => 'ProfileInfo(id: $id, name: $name, active: $isActive)';
}
