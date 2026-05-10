// ignore_for_file: deprecated_member_use

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'google_drive_photo_service.dart';
import 'photo_service.dart';

const _refreshInterval = Duration(minutes: 30);

/// Periodically syncs photo metadata from the configured Drive folder and
/// caches it in the [Photo] table.
///
/// Registered with Serverpod as 'photoRefresh'. Self-rescheduling pattern
/// mirrors [WeatherRefreshCall] and [CalendarRefreshCall].
///
/// No-ops cleanly when [googleDriveFolderId] is empty or no active Google
/// credential is found — the display shows an empty placeholder instead.
///
/// Uses a differential sync so existing row IDs are preserved across runs.
/// Deletes rows whose providerFileId has been removed from the Drive folder,
/// inserts rows for new files, and skips rows that already exist.
class PhotoRefreshCall extends FutureCall<SerializableModel> {
  /// In-process guard against concurrent refresh chains stacking up during
  /// rapid dev-mode restarts. Resets on process restart (intentional — it is
  /// best-effort only; the differential sync makes repeated runs safe anyway).
  static DateTime? _lastRun;

  static const _minInterval = Duration(minutes: 20);

  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    // Throttle: if a refresh ran less than [_minInterval] ago in this process,
    // reschedule and return without doing work.
    final last = _lastRun;
    if (last != null &&
        DateTime.now().toUtc().difference(last) < _minInterval) {
      await session.serverpod.futureCallWithDelay(
        'photoRefresh',
        null,
        _refreshInterval,
      );
      return;
    }

    try {
      await _refresh(session);
      _lastRun = DateTime.now().toUtc();
    } catch (e, stackTrace) {
      session.log(
        'Photo refresh failed: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
    } finally {
      await session.serverpod.futureCallWithDelay(
        'photoRefresh',
        null,
        _refreshInterval,
      );
    }
  }

  Future<void> _refresh(Session session) async {
    final folderId = session.passwords['googleDriveFolderId'];
    if (folderId == null || folderId.isEmpty) {
      session.log('Photo refresh: googleDriveFolderId not configured, skipping.');
      return;
    }

    final credential = await LinkedCredential.db.findFirstRow(
      session,
      where: (t) =>
          t.provider.equals('google') & t.isActive.equals(true),
    );

    if (credential == null) {
      session.log('Photo refresh: no active Google credential found, skipping.');
      return;
    }

    final service = _serviceFor(credential);
    final drivePhotos = await service.listPhotos(session, credential, folderId);

    // Build a set of providerFileIds currently in Drive.
    final driveIds = {for (final p in drivePhotos) p.providerFileId};

    // Load existing rows for this credential.
    final existing = await Photo.db.find(
      session,
      where: (t) => t.credentialId.equals(credential.id!),
    );

    // Map providerFileId → existing DB row for quick lookup.
    final existingByProviderId = {
      for (final p in existing) p.providerFileId: p,
    };

    // Delete rows whose providerFileId is no longer in the Drive list.
    final toDelete = existing
        .where((p) => !driveIds.contains(p.providerFileId))
        .toList();
    if (toDelete.isNotEmpty) {
      await Photo.db.delete(session, toDelete);
    }

    // Insert only rows that do not already exist in the DB.
    final toInsert = drivePhotos
        .where((p) => !existingByProviderId.containsKey(p.providerFileId))
        .map(
          (p) => Photo(
            credentialId: p.credentialId,
            providerFileId: p.providerFileId,
            filename: p.filename,
            mimeType: p.mimeType,
            fetchedAt: DateTime.now().toUtc(),
          ),
        )
        .toList();
    if (toInsert.isNotEmpty) {
      await Photo.db.insert(session, toInsert);
    }

    session.log(
      'Photo refresh: synced ${drivePhotos.length} photos '
      '(${toInsert.length} added, ${toDelete.length} removed, '
      '${existing.length - toDelete.length} unchanged).',
    );
  }

  PhotoService _serviceFor(LinkedCredential credential) {
    return switch (credential.provider) {
      'google' => GoogleDrivePhotoService(),
      _ => throw UnimplementedError(
          'Photo provider "${credential.provider}" is not yet supported.',
        ),
    };
  }
}
