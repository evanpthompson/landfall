import 'package:landfall_shared/src/models/dashboard/dashboard_layout.dart';
import 'package:landfall_shared/src/models/profile/profile_card_filter.dart';
import 'package:landfall_shared/src/models/profile/profile_info.dart';
import 'package:landfall_shared/src/models/profile/profile_schedule.dart';

/// Abstract interface for named dashboard profile persistence.
///
/// Implementations:
/// - [ServerpodProfileRepository] — production, syncs with the server
abstract interface class DashboardProfileRepository {
  /// Returns all profiles ordered by [ProfileInfo.sortOrder] ascending.
  Future<List<ProfileInfo>> listProfiles();

  /// Returns the currently active profile, or the first profile if none is
  /// marked active. Throws [StateError] if the server has no profiles at all.
  Future<ProfileInfo> getActiveProfile();

  /// Creates a new profile named [name].
  ///
  /// [layout] provides the initial card arrangement. When omitted the profile
  /// starts with the default weekday layout.
  Future<ProfileInfo> createProfile(String name, {DashboardLayout? layout});

  /// Updates mutable fields of the profile identified by [id].
  ///
  /// Only non-null arguments are applied — pass null to leave a field unchanged.
  Future<ProfileInfo> updateProfile(
    int id, {
    String? name,
    DashboardLayout? layout,
    ProfileCardFilter? cardFilter,
    ProfileSchedule? schedule,
  });

  /// Deletes the profile with the given [id].
  ///
  /// Throws if the profile is currently active or is the last one.
  Future<void> deleteProfile(int id);

  /// Makes [id] the active profile. Returns the newly activated profile.
  Future<ProfileInfo> activateProfile(int id);

  /// Creates a copy of profile [id] with [newName]. Returns the duplicate.
  Future<ProfileInfo> duplicateProfile(int id, String newName);
}
