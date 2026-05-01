import 'dart:convert';

import 'package:landfall_client/landfall_client.dart';
import 'package:landfall_shared/landfall_shared.dart';

/// Production [DashboardProfileRepository] backed by the Serverpod
/// [ProfileEndpoint].
///
/// Profiles are stored server-side so all displays sharing the same server
/// stay in sync. Converts between [DashboardProfile] (Serverpod model) and
/// [ProfileInfo] (domain model).
class ServerpodProfileRepository implements DashboardProfileRepository {
  const ServerpodProfileRepository(this._client);

  final Client _client;

  // ── read ──────────────────────────────────────────────────────────────────

  @override
  Future<List<ProfileInfo>> listProfiles() async {
    final profiles = await _client.profile.listProfiles();
    return profiles.map(_toDomain).toList();
  }

  @override
  Future<ProfileInfo> getActiveProfile() async {
    final all = await listProfiles();
    if (all.isEmpty) {
      return _defaultProfile();
    }
    return all.firstWhere(
      (p) => p.isActive,
      orElse: () => all.first,
    );
  }

  // ── write ─────────────────────────────────────────────────────────────────

  @override
  Future<ProfileInfo> createProfile(
    String name, {
    DashboardLayout? layout,
  }) async {
    final cardsJson = layout != null
        ? jsonEncode(layout.cards.map((c) => c.toJson()).toList())
        : null;
    final result = await _client.profile.createProfile(
      name,
      cardsJson: cardsJson,
    );
    return _toDomain(result);
  }

  @override
  Future<ProfileInfo> updateProfile(
    int id, {
    String? name,
    DashboardLayout? layout,
    ProfileCardFilter? cardFilter,
    ProfileSchedule? schedule,
  }) async {
    final result = await _client.profile.updateProfile(
      id,
      name: name,
      cardsJson: layout != null
          ? jsonEncode(layout.cards.map((c) => c.toJson()).toList())
          : null,
      cardFilterJson: cardFilter != null ? jsonEncode(cardFilter.toJson()) : null,
      scheduleJson: schedule != null ? jsonEncode(schedule.toJson()) : null,
    );
    return _toDomain(result);
  }

  @override
  Future<void> deleteProfile(int id) => _client.profile.deleteProfile(id);

  @override
  Future<ProfileInfo> activateProfile(int id) async {
    final result = await _client.profile.activateProfile(id);
    return _toDomain(result);
  }

  @override
  Future<ProfileInfo> duplicateProfile(int id, String newName) async {
    final result = await _client.profile.duplicateProfile(id, newName);
    return _toDomain(result);
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  static ProfileInfo _toDomain(DashboardProfile p) {
    final rawCards = jsonDecode(p.cardsJson) as List<dynamic>;
    final layout = DashboardLayout(
      id: 'profile-${p.id}',
      name: p.name,
      columns: p.columnsCount,
      rows: p.rowsCount,
      cards: rawCards
          .map((e) => CardConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

    ProfileCardFilter cardFilter = ProfileCardFilter.all;
    if (p.cardFilterJson.isNotEmpty && p.cardFilterJson != '{}') {
      try {
        cardFilter = ProfileCardFilter.fromJson(
          jsonDecode(p.cardFilterJson) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    ProfileSchedule? schedule;
    if (p.scheduleJson != null) {
      try {
        schedule = ProfileSchedule.fromJson(
          jsonDecode(p.scheduleJson!) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    return ProfileInfo(
      id: p.id!,
      name: p.name,
      slug: p.slug,
      isActive: p.isActive,
      layout: layout,
      cardFilter: cardFilter,
      schedule: schedule,
      sortOrder: p.sortOrder,
    );
  }

  static ProfileInfo _defaultProfile() => ProfileInfo(
        id: -1,
        name: 'Default',
        slug: 'default',
        isActive: true,
        layout: DashboardLayout.weekdayLayout(),
        sortOrder: 0,
      );
}
