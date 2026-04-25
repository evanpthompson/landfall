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
class PhotoRefreshCall extends FutureCall<SerializableModel> {
  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    try {
      await _refresh(session);
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
    final photos = await service.listPhotos(session, credential, folderId);

    // Atomically replace all cached photos for this credential.
    await session.db.transaction((tx) async {
      await Photo.db.deleteWhere(
        session,
        where: (t) => t.credentialId.equals(credential.id!),
        transaction: tx,
      );
      if (photos.isNotEmpty) {
        await Photo.db.insert(session, photos, transaction: tx);
      }
    });

    session.log('Photo refresh: synced ${photos.length} photos from Drive.');
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
