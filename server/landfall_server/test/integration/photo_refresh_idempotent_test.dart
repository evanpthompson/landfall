import 'package:test/test.dart';

import 'package:landfall_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a [Photo] without a DB id (as the service layer returns them).
Photo _drivePhoto({
  required int credentialId,
  required String providerFileId,
  required String filename,
  String mimeType = 'image/jpeg',
}) {
  return Photo(
    credentialId: credentialId,
    providerFileId: providerFileId,
    filename: filename,
    mimeType: mimeType,
    fetchedAt: DateTime.now().toUtc(),
  );
}

/// Replicates the differential-sync logic from [PhotoRefreshCall._refresh] so
/// that the integration test can drive it directly against the real DB without
/// needing a real Google credential or HTTP call.
///
/// [credentialId] — the credential whose rows are being synced.
/// [drivePhotos]  — the list returned by the photo-service (no DB ids).
Future<void> syncPhotos(
  dynamic session, {
  required int credentialId,
  required List<Photo> drivePhotos,
}) async {
  final driveIds = {for (final p in drivePhotos) p.providerFileId};

  final existing = await Photo.db.find(
    session,
    where: (t) => t.credentialId.equals(credentialId),
  );

  final existingByProviderId = {
    for (final p in existing) p.providerFileId: p,
  };

  final toDelete = existing
      .where((p) => !driveIds.contains(p.providerFileId))
      .toList();
  if (toDelete.isNotEmpty) {
    await Photo.db.delete(session, toDelete);
  }

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
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  withServerpod(
    'Given PhotoRefreshCall differential sync (idempotency)',
    (sessionBuilder, endpoints) {
      const credentialId = 1;

      setUp(() async {
        final session = sessionBuilder.build();
        await Photo.db.deleteWhere(
          session,
          where: (t) => t.credentialId.equals(credentialId),
        );
        await session.close();
      });

      Future<List<Photo>> loadRows(dynamic session) {
        return Photo.db.find(
          session,
          where: (t) => t.credentialId.equals(credentialId),
          orderBy: (t) => t.providerFileId,
        );
      }

      test('first sync inserts all photos with DB ids assigned', () async {
        final session = sessionBuilder.build();

        final drivePhotos = [
          _drivePhoto(credentialId: credentialId, providerFileId: 'gf1', filename: 'a.jpg'),
          _drivePhoto(credentialId: credentialId, providerFileId: 'gf2', filename: 'b.jpg'),
        ];

        await syncPhotos(session, credentialId: credentialId, drivePhotos: drivePhotos);

        final rows = await loadRows(session);
        await session.close();

        expect(rows, hasLength(2));
        expect(rows.every((r) => r.id != null && r.id! > 0), isTrue,
            reason: 'Every inserted row must have a DB id');
        expect(
          rows.map((r) => r.providerFileId).toSet(),
          equals({'gf1', 'gf2'}),
        );
      });

      test('second sync with same list preserves all row IDs', () async {
        final session = sessionBuilder.build();

        final drivePhotos = [
          _drivePhoto(credentialId: credentialId, providerFileId: 'gf1', filename: 'a.jpg'),
          _drivePhoto(credentialId: credentialId, providerFileId: 'gf2', filename: 'b.jpg'),
        ];

        // First sync — establishes row IDs.
        await syncPhotos(session, credentialId: credentialId, drivePhotos: drivePhotos);
        final rowsAfterFirst = await loadRows(session);
        final idsBefore = {for (final r in rowsAfterFirst) r.providerFileId: r.id};

        // Second sync with identical list — must not change any row IDs.
        await syncPhotos(session, credentialId: credentialId, drivePhotos: drivePhotos);
        final rowsAfterSecond = await loadRows(session);
        await session.close();

        expect(rowsAfterSecond, hasLength(2),
            reason: 'Row count must not change on identical sync');

        for (final row in rowsAfterSecond) {
          expect(
            row.id,
            equals(idsBefore[row.providerFileId]),
            reason:
                'Row id for providerFileId="${row.providerFileId}" must be stable across syncs',
          );
        }
      });

      test('sync with one photo removed deletes that row, others keep their IDs', () async {
        final session = sessionBuilder.build();

        final initial = [
          _drivePhoto(credentialId: credentialId, providerFileId: 'gf1', filename: 'a.jpg'),
          _drivePhoto(credentialId: credentialId, providerFileId: 'gf2', filename: 'b.jpg'),
          _drivePhoto(credentialId: credentialId, providerFileId: 'gf3', filename: 'c.jpg'),
        ];

        await syncPhotos(session, credentialId: credentialId, drivePhotos: initial);
        final rowsAfterFirst = await loadRows(session);
        final idsBefore = {for (final r in rowsAfterFirst) r.providerFileId: r.id};

        // Remove gf2 from Drive.
        final afterRemoval = [
          _drivePhoto(credentialId: credentialId, providerFileId: 'gf1', filename: 'a.jpg'),
          _drivePhoto(credentialId: credentialId, providerFileId: 'gf3', filename: 'c.jpg'),
        ];

        await syncPhotos(session, credentialId: credentialId, drivePhotos: afterRemoval);
        final rowsAfterRemoval = await loadRows(session);
        await session.close();

        expect(rowsAfterRemoval, hasLength(2),
            reason: 'Removed photo must be deleted from DB');
        expect(
          rowsAfterRemoval.map((r) => r.providerFileId),
          isNot(contains('gf2')),
          reason: 'gf2 must no longer be in DB',
        );
        for (final row in rowsAfterRemoval) {
          expect(
            row.id,
            equals(idsBefore[row.providerFileId]),
            reason:
                'Surviving row id for "${row.providerFileId}" must be unchanged',
          );
        }
      });

      test('sync with one photo added gives new ID to new row, others unchanged', () async {
        final session = sessionBuilder.build();

        final initial = [
          _drivePhoto(credentialId: credentialId, providerFileId: 'gf1', filename: 'a.jpg'),
          _drivePhoto(credentialId: credentialId, providerFileId: 'gf2', filename: 'b.jpg'),
        ];

        await syncPhotos(session, credentialId: credentialId, drivePhotos: initial);
        final rowsAfterFirst = await loadRows(session);
        final idsBefore = {for (final r in rowsAfterFirst) r.providerFileId: r.id};

        // Add gf3 to Drive.
        final afterAddition = [
          _drivePhoto(credentialId: credentialId, providerFileId: 'gf1', filename: 'a.jpg'),
          _drivePhoto(credentialId: credentialId, providerFileId: 'gf2', filename: 'b.jpg'),
          _drivePhoto(credentialId: credentialId, providerFileId: 'gf3', filename: 'c.jpg'),
        ];

        await syncPhotos(session, credentialId: credentialId, drivePhotos: afterAddition);
        final rowsAfterAddition = await loadRows(session);
        await session.close();

        expect(rowsAfterAddition, hasLength(3),
            reason: 'New photo must be inserted');

        final newRow = rowsAfterAddition.firstWhere((r) => r.providerFileId == 'gf3');
        expect(newRow.id, isNotNull);
        expect(newRow.id, greaterThan(0));
        expect(
          idsBefore.values,
          isNot(contains(newRow.id)),
          reason: 'New row must have a fresh ID not reusing any previous ID',
        );

        for (final row in rowsAfterAddition.where((r) => r.providerFileId != 'gf3')) {
          expect(
            row.id,
            equals(idsBefore[row.providerFileId]),
            reason:
                'Existing row id for "${row.providerFileId}" must be unchanged after addition',
          );
        }
      });

      test('sync to empty list deletes all existing rows', () async {
        final session = sessionBuilder.build();

        final initial = [
          _drivePhoto(credentialId: credentialId, providerFileId: 'gf1', filename: 'a.jpg'),
        ];

        await syncPhotos(session, credentialId: credentialId, drivePhotos: initial);

        await syncPhotos(session, credentialId: credentialId, drivePhotos: []);

        final rows = await loadRows(session);
        await session.close();

        expect(rows, isEmpty, reason: 'All rows must be deleted when Drive is empty');
      });

      test('sync is idempotent across three identical runs', () async {
        final session = sessionBuilder.build();

        final drivePhotos = [
          _drivePhoto(credentialId: credentialId, providerFileId: 'gf1', filename: 'a.jpg'),
          _drivePhoto(credentialId: credentialId, providerFileId: 'gf2', filename: 'b.jpg'),
        ];

        await syncPhotos(session, credentialId: credentialId, drivePhotos: drivePhotos);
        final idsAfterFirst = {
          for (final r in await loadRows(session)) r.providerFileId: r.id,
        };

        await syncPhotos(session, credentialId: credentialId, drivePhotos: drivePhotos);
        final idsAfterSecond = {
          for (final r in await loadRows(session)) r.providerFileId: r.id,
        };

        await syncPhotos(session, credentialId: credentialId, drivePhotos: drivePhotos);
        final idsAfterThird = {
          for (final r in await loadRows(session)) r.providerFileId: r.id,
        };
        await session.close();

        expect(idsAfterSecond, equals(idsAfterFirst),
            reason: 'IDs must be stable between run 1 and run 2');
        expect(idsAfterThird, equals(idsAfterFirst),
            reason: 'IDs must be stable between run 1 and run 3');
      });
    },
  );
}
