import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'dashboard_profile_state.dart';

/// Manages named dashboard profiles and the currently active one.
///
/// Responsibilities:
/// - Loading all profiles and surfacing the active one
/// - Activating a profile (display switches to its layout)
/// - Saving layout edits back into the active profile
/// - CRUD for the profile list (create, rename, duplicate, delete)
class DashboardProfileCubit extends Cubit<DashboardProfileState> {
  DashboardProfileCubit(this._repository)
      : super(const DashboardProfileLoading());

  final DashboardProfileRepository _repository;

  /// Loads all profiles and emits the active one.
  ///
  /// If no profiles exist on the server (fresh install), seeds the three
  /// default profiles (Weekday, Weekend, Night) and activates Weekday.
  Future<void> loadProfiles() async {
    emit(const DashboardProfileLoading());
    try {
      var all = await _repository.listProfiles();
      if (all.isEmpty) {
        all = await _seedDefaults();
      }
      final active =
          all.firstWhere((p) => p.isActive, orElse: () => all.first);
      emit(DashboardProfileLoaded(active, profiles: all));
    } catch (e) {
      emit(DashboardProfileError(e.toString()));
    }
  }

  Future<List<ProfileInfo>> _seedDefaults() async {
    final weekday = await _repository.createProfile(
      'Weekday',
      layout: DashboardLayout.weekdayLayout(),
    );
    await _repository.createProfile(
      'Weekend',
      layout: DashboardLayout.weekendLayout(),
    );
    await _repository.createProfile(
      'Night',
      layout: DashboardLayout.nightLayout(),
    );
    await _repository.activateProfile(weekday.id);
    return _repository.listProfiles();
  }

  /// Activates the profile identified by [id] and reloads.
  Future<void> activateProfile(int id) async {
    try {
      await _repository.activateProfile(id);
      await _refreshAfterWrite();
    } catch (e) {
      emit(DashboardProfileError(e.toString()));
    }
  }

  /// Persists [layout] into the currently active profile.
  Future<void> saveActiveLayout(DashboardLayout layout) async {
    final current = state;
    if (current is! DashboardProfileLoaded) return;
    try {
      await _repository.updateProfile(current.active.id, layout: layout);
      await _refreshAfterWrite();
    } catch (e) {
      emit(DashboardProfileError(e.toString()));
    }
  }

  /// Resets the active profile's layout to its default seed layout.
  ///
  /// The default is derived from the profile name: "Night" → nightLayout,
  /// "Weekend" → weekendLayout, anything else → weekdayLayout.
  Future<void> resetActiveLayout() async {
    final current = state;
    if (current is! DashboardProfileLoaded) return;
    final defaultLayout = _defaultLayoutFor(current.active.name);
    try {
      await _repository.updateProfile(current.active.id, layout: defaultLayout);
      await _refreshAfterWrite();
    } catch (e) {
      emit(DashboardProfileError(e.toString()));
    }
  }

  static DashboardLayout _defaultLayoutFor(String profileName) {
    final lower = profileName.toLowerCase();
    if (lower.contains('night')) return DashboardLayout.nightLayout();
    if (lower.contains('weekend')) return DashboardLayout.weekendLayout();
    return DashboardLayout.weekdayLayout();
  }

  /// Creates a new profile named [name], optionally seeded from [layout].
  Future<void> createProfile(String name, {DashboardLayout? layout}) async {
    try {
      await _repository.createProfile(name, layout: layout);
      await _refreshAfterWrite();
    } catch (e) {
      emit(DashboardProfileError(e.toString()));
    }
  }

  /// Renames the profile [id] to [newName].
  Future<void> renameProfile(int id, String newName) async {
    try {
      await _repository.updateProfile(id, name: newName);
      await _refreshAfterWrite();
    } catch (e) {
      emit(DashboardProfileError(e.toString()));
    }
  }

  /// Duplicates profile [id] as [newName].
  Future<void> duplicateProfile(int id, String newName) async {
    try {
      await _repository.duplicateProfile(id, newName);
      await _refreshAfterWrite();
    } catch (e) {
      emit(DashboardProfileError(e.toString()));
    }
  }

  /// Deletes the profile [id]. The active profile cannot be deleted.
  Future<void> deleteProfile(int id) async {
    try {
      await _repository.deleteProfile(id);
      await _refreshAfterWrite();
    } catch (e) {
      emit(DashboardProfileError(e.toString()));
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  Future<void> _refreshAfterWrite() async {
    try {
      final all = await _repository.listProfiles();
      final active = all.isEmpty
          ? _fallback()
          : all.firstWhere((p) => p.isActive, orElse: () => all.first);
      emit(DashboardProfileLoaded(active, profiles: all));
    } catch (e) {
      emit(DashboardProfileError(e.toString()));
    }
  }

  static ProfileInfo _fallback() => ProfileInfo(
        id: -1,
        name: 'Default',
        slug: 'default',
        isActive: true,
        layout: DashboardLayout.weekdayLayout(),
        sortOrder: 0,
      );
}
