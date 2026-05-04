import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

void _requireAuth(Session session) {
  if (session.authenticated == null) {
    throw LandfallException(message: 'Authentication required.');
  }
}

/// Manages named dashboard profiles.
///
/// Each profile stores a complete layout (cardsJson + grid dimensions), an
/// agent card filter, an optional theme, and an optional schedule. Exactly one
/// profile has [DashboardProfile.isActive] = true at any time.
class ProfileEndpoint extends Endpoint {
  /// Returns all profiles ordered by [DashboardProfile.sortOrder] ascending.
  Future<List<DashboardProfile>> listProfiles(Session session) async {
    return DashboardProfile.db.find(
      session,
      orderBy: (t) => t.sortOrder,
    );
  }

  /// Creates a new profile with the given [name].
  ///
  /// [cardsJson] sets the initial card layout. When omitted the layout is an
  /// empty array — callers should pass in the current active layout's cardsJson
  /// to duplicate it as a starting point.
  ///
  /// Returns the created [DashboardProfile] with its assigned id.
  Future<DashboardProfile> createProfile(
    Session session,
    String name, {
    String? cardsJson,
  }) async {
    _requireAuth(session);
    final slug = _slugify(name);
    final row = DashboardProfile(
      name: name,
      slug: await _uniqueSlug(session, slug),
      isActive: false,
      cardFilterJson: '{}',
      sortOrder: await _nextSortOrder(session),
      cardsJson: cardsJson ?? '[]',
      createdAt: DateTime.now().toUtc(),
    );
    return DashboardProfile.db.insertRow(session, row);
  }

  /// Updates the mutable fields of an existing profile.
  ///
  /// Only non-null arguments are applied — pass null to leave a field unchanged.
  Future<DashboardProfile> updateProfile(
    Session session,
    int id, {
    String? name,
    String? themeId,
    String? cardFilterJson,
    String? scheduleJson,
    int? sortOrder,
    String? cardsJson,
  }) async {
    _requireAuth(session);
    final row = await DashboardProfile.db.findById(session, id);
    if (row == null) {
      throw NotFoundException('DashboardProfile id=$id not found.');
    }
    final updated = row.copyWith(
      name: name ?? row.name,
      slug: name != null ? await _uniqueSlug(session, _slugify(name), excludeId: id) : row.slug,
      themeId: themeId ?? row.themeId,
      cardFilterJson: cardFilterJson ?? row.cardFilterJson,
      scheduleJson: scheduleJson,
      sortOrder: sortOrder ?? row.sortOrder,
      cardsJson: cardsJson ?? row.cardsJson,
    );
    return DashboardProfile.db.updateRow(session, updated);
  }

  /// Deletes the profile with the given [id].
  ///
  /// Throws [InvalidRequestException] if the profile is currently active or if
  /// it is the last remaining profile.
  Future<void> deleteProfile(Session session, int id) async {
    _requireAuth(session);
    final row = await DashboardProfile.db.findById(session, id);
    if (row == null) return;
    if (row.isActive) {
      throw InvalidRequestException('Cannot delete the active profile.');
    }
    final total = await DashboardProfile.db.count(session);
    if (total <= 1) {
      throw InvalidRequestException('Cannot delete the last profile.');
    }
    await DashboardProfile.db.deleteRow(session, row);
  }

  /// Switches the active profile to [id].
  ///
  /// Clears [isActive] on all other profiles atomically. Returns the newly
  /// activated profile.
  Future<DashboardProfile> activateProfile(Session session, int id) async {
    _requireAuth(session);
    // Deactivate all.
    final all = await DashboardProfile.db.find(
      session,
      where: (t) => t.isActive.equals(true),
    );
    for (final p in all) {
      await DashboardProfile.db.updateRow(
        session,
        p.copyWith(isActive: false),
      );
    }

    // Activate the target.
    final target = await DashboardProfile.db.findById(session, id);
    if (target == null) {
      throw NotFoundException('DashboardProfile id=$id not found.');
    }
    return DashboardProfile.db.updateRow(
      session,
      target.copyWith(isActive: true),
    );
  }

  /// Creates a copy of the profile identified by [id] with the given [newName].
  ///
  /// The duplicate is inactive and placed at the end of the sort order.
  /// Returns the newly created profile.
  Future<DashboardProfile> duplicateProfile(
    Session session,
    int id,
    String newName,
  ) async {
    _requireAuth(session);
    final source = await DashboardProfile.db.findById(session, id);
    if (source == null) {
      throw NotFoundException('DashboardProfile id=$id not found.');
    }
    final slug = await _uniqueSlug(session, _slugify(newName));
    final copy = DashboardProfile(
      name: newName,
      slug: slug,
      isActive: false,
      themeId: source.themeId,
      cardFilterJson: source.cardFilterJson,
      scheduleJson: source.scheduleJson,
      sortOrder: await _nextSortOrder(session),
      columnsCount: source.columnsCount,
      rowsCount: source.rowsCount,
      cardsJson: source.cardsJson,
      createdAt: DateTime.now().toUtc(),
    );
    return DashboardProfile.db.insertRow(session, copy);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Converts a display name to a URL-safe slug.
  static String _slugify(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  /// Returns [base] slug, appending a numeric suffix if needed to avoid
  /// collisions. Optionally excludes [excludeId] from the uniqueness check
  /// (so rename-in-place doesn't trigger a suffix).
  Future<String> _uniqueSlug(
    Session session,
    String base, {
    int? excludeId,
  }) async {
    var candidate = base;
    var suffix = 2;
    while (true) {
      final existing = await DashboardProfile.db.findFirstRow(
        session,
        where: (t) => t.slug.equals(candidate),
      );
      if (existing == null || existing.id == excludeId) return candidate;
      candidate = '$base-$suffix';
      suffix++;
    }
  }

  /// Returns the next sort order value (max existing + 1, or 0 if empty).
  Future<int> _nextSortOrder(Session session) async {
    final all = await DashboardProfile.db.find(
      session,
      orderBy: (t) => t.sortOrder,
      orderDescending: true,
      limit: 1,
    );
    return all.isEmpty ? 0 : all.first.sortOrder + 1;
  }
}

class NotFoundException implements Exception {
  const NotFoundException(this.message);
  final String message;
  @override
  String toString() => 'NotFoundException: $message';
}

class InvalidRequestException implements Exception {
  const InvalidRequestException(this.message);
  final String message;
  @override
  String toString() => 'InvalidRequestException: $message';
}
