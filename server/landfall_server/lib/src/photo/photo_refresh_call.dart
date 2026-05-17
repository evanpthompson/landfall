// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'photo_service_factory.dart';

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

    final credential = await _resolveCredential(session);
    if (credential == null) {
      session.log(
        'Photo refresh: no Google credential or service account configured, '
        'skipping.',
      );
      return;
    }

    final service = photoServiceFor(
      credential: credential,
      passwords: session.passwords,
    );
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

  /// Picks the credential the next refresh should run against.
  ///
  /// Service account credentials take precedence over user OAuth. If service
  /// account passwords are present we find-or-create a synthetic
  /// `LinkedCredential` row (provider `"google-sa"`) so the existing
  /// `Photo.credentialId` FK + `PhotoServeRoute` lookup pipelines keep
  /// working unchanged.
  Future<LinkedCredential?> _resolveCredential(Session session) async {
    final saEmail = session.passwords['googleServiceAccountEmail'];
    final saKey = session.passwords['googleServiceAccountPrivateKey'];
    final hasServiceAccount = saEmail != null &&
        saEmail.isNotEmpty &&
        saKey != null &&
        saKey.isNotEmpty;

    if (hasServiceAccount) {
      return _findOrCreateServiceAccountCredential(session, saEmail);
    }

    return LinkedCredential.db.findFirstRow(
      session,
      where: (t) => t.provider.equals('google') & t.isActive.equals(true),
    );
  }

  Future<LinkedCredential> _findOrCreateServiceAccountCredential(
    Session session,
    String serviceAccountEmail,
  ) async {
    final existing = await LinkedCredential.db.findFirstRow(
      session,
      where: (t) =>
          t.provider.equals('google-sa') &
          t.providerEmail.equals(serviceAccountEmail),
    );
    if (existing != null) return existing;

    // Synthesize a stable UUID from the service account email so re-creating
    // the row after a DB rebuild gives the same authUserId. (Different SAs
    // map to different UUIDs; the value is opaque — only used as the anchor
    // for Photo.credentialId joins.)
    final hash = sha256.convert(utf8.encode(serviceAccountEmail)).bytes;
    final hex = hash
        .take(16)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final authUserId =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '4${hex.substring(13, 16)}-' // RFC 4122 v4
        '8${hex.substring(17, 20)}-${hex.substring(20)}';

    final now = DateTime.now().toUtc();
    return LinkedCredential.db.insertRow(
      session,
      LinkedCredential(
        authUserId: UuidValue.fromString(authUserId),
        provider: 'google-sa',
        providerEmail: serviceAccountEmail,
        // accessToken/refreshToken are never read for service accounts.
        accessToken: '',
        refreshToken: null,
        tokenExpiresAt: null,
        scopes: 'https://www.googleapis.com/auth/drive.readonly',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
