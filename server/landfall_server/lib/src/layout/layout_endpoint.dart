import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Manages saved display layout configurations.
///
/// Layouts are stored in [layout_configs]. Each row is a named layout with a
/// preset category (weekday | weekend | night | custom). One row has
/// [LayoutConfig.isActive] = true — that is the layout currently shown on the
/// display.
class LayoutEndpoint extends Endpoint {
  /// Returns all saved layouts, ordered by preset type then name.
  ///
  /// Returns an empty list if no layouts have been saved yet.
  Future<List<LayoutConfig>> getLayouts(Session session) async {
    return LayoutConfig.db.find(
      session,
      orderBy: (t) => t.updatedAt,
      orderDescending: true,
    );
  }

  /// Saves [layout], inserting a new row or updating an existing one by id.
  ///
  /// If [layout.id] is null a new row is created. Returns the saved row.
  Future<LayoutConfig> saveLayout(Session session, LayoutConfig layout) async {
    layout.updatedAt = DateTime.now().toUtc();

    if (layout.id == null) {
      return LayoutConfig.db.insertRow(session, layout);
    }
    return LayoutConfig.db.updateRow(session, layout);
  }

  /// Marks [layoutId] as active and clears the active flag on all others.
  ///
  /// Returns the newly activated [LayoutConfig].
  Future<LayoutConfig> setActiveLayout(Session session, int layoutId) async {
    // Clear all active flags.
    final all = await LayoutConfig.db.find(
      session,
      where: (t) => t.isActive.equals(true),
    );
    for (final row in all) {
      await LayoutConfig.db.updateRow(
        session,
        row.copyWith(isActive: false),
      );
    }

    // Set the target as active.
    final target = await LayoutConfig.db.findFirstRow(
      session,
      where: (t) => t.id.equals(layoutId),
    );
    if (target == null) {
      throw NotFoundException('LayoutConfig id=$layoutId not found.');
    }
    return LayoutConfig.db.updateRow(
      session,
      target.copyWith(isActive: true),
    );
  }

  /// Deletes the layout with the given [id].
  ///
  /// The active layout cannot be deleted — an exception is thrown instead.
  Future<void> deleteLayout(Session session, int id) async {
    final row = await LayoutConfig.db.findFirstRow(
      session,
      where: (t) => t.id.equals(id),
    );
    if (row == null) return;
    if (row.isActive) {
      throw InvalidRequestException('Cannot delete the active layout.');
    }
    await LayoutConfig.db.deleteRow(session, row);
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
