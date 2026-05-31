import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/features/companion/companion_event_bus.dart';
import 'dashboard_profile_state.dart';

/// Manages named dashboard profiles and the currently active one.
///
/// Responsibilities:
/// - Loading all profiles and surfacing the active one
/// - Activating a profile (display switches to its layout)
/// - Saving layout edits back into the active profile
/// - CRUD for the profile list (create, rename, duplicate, delete)
class DashboardProfileCubit extends Cubit<DashboardProfileState> {
  DashboardProfileCubit(this._repository, {CompanionEventBus? bus})
      : _bus = bus,
        super(const DashboardProfileLoading());

  final DashboardProfileRepository _repository;
  final CompanionEventBus? _bus;

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
      // One-time migration: remove standalone forecast slots now that forecast
      // is embedded in WeatherCard. Saves back any profile whose layout changed.
      all = await _migrateForecastSlots(all);
      final active =
          all.firstWhere((p) => p.isActive, orElse: () => all.first);
      emit(DashboardProfileLoaded(active, profiles: all));
    } catch (e) {
      emit(DashboardProfileError(e.toString()));
    }
  }

  Future<List<ProfileInfo>> _migrateForecastSlots(
      List<ProfileInfo> profiles) async {
    final migrated = <ProfileInfo>[];
    for (final profile in profiles) {
      final layout = profile.layout;
      final hadForecastSlot =
          layout.cards.any((c) => c.source == 'system.weather.forecast');
      if (!hadForecastSlot) {
        migrated.add(profile);
        continue;
      }
      final cleaned = DashboardLayout(
        id: layout.id,
        name: layout.name,
        columns: layout.columns,
        rows: layout.rows,
        cards: layout.cards
            .where((c) => c.source != 'system.weather.forecast')
            .toList(),
      );
      await _repository.updateProfile(profile.id, layout: cleaned);
      migrated.add(profile.copyWith(layout: cleaned));
    }
    return migrated;
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
      _emitProfileTrigger();
    } catch (e) {
      emit(DashboardProfileError(e.toString()));
    }
  }

  void _emitProfileTrigger() {
    final bus = _bus;
    if (bus == null) return;
    final current = state;
    if (current is! DashboardProfileLoaded) return;
    final isNight = current.active.name.toLowerCase().contains('night');
    bus.emit(
      isNight
          ? CompanionTrigger.nightProfileActivated
          : CompanionTrigger.dayProfileActivated,
    );
  }

  /// Persists [layout] into the currently active profile.
  ///
  /// Emits the updated state optimistically so the UI reflects the change
  /// immediately. If the server call fails, rolls back to the previous state.
  Future<void> saveActiveLayout(DashboardLayout layout) async {
    final previous = state;
    if (previous is! DashboardProfileLoaded) return;
    final updated = previous.active.copyWith(layout: layout);
    emit(DashboardProfileLoaded(
      updated,
      profiles: previous.profiles
          .map((p) => p.id == updated.id ? updated : p)
          .toList(),
    ));
    try {
      await _repository.updateProfile(previous.active.id, layout: layout);
    } catch (e) {
      emit(previous);
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
