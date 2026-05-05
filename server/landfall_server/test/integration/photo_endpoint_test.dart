import 'package:test/test.dart';

import 'package:landfall_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';

Photo _photo({
  int credentialId = 1,
  String? providerFileId,
  required String filename,
  String mimeType = 'image/jpeg',
}) {
  return Photo(
    credentialId: credentialId,
    providerFileId: providerFileId ?? 'file_$filename',
    filename: filename,
    mimeType: mimeType,
    fetchedAt: DateTime.now().toUtc(),
  );
}

void main() {
  withServerpod('Given PhotoEndpoint', (sessionBuilder, endpoints) {
    late TestSessionBuilder authed;

    setUp(() async {
      authed = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo('user-1', {}),
      );
      final session = sessionBuilder.build();
      await Photo.db.deleteWhere(
        session,
        where: (t) => t.id > 0,
      );
      await session.close();
    });

    group('getPhotos', () {
      test('returns empty list when no photos are cached', () async {
        final result = await endpoints.photo.getPhotos(authed);
        expect(result, isEmpty);
      });

      test('returns a single photo with correct fields', () async {
        final session = sessionBuilder.build();
        await Photo.db.insertRow(
          session,
          _photo(filename: 'sunset.jpg', mimeType: 'image/jpeg'),
        );
        await session.close();

        final result = await endpoints.photo.getPhotos(authed);

        expect(result, hasLength(1));
        expect(result.first.filename, equals('sunset.jpg'));
        expect(result.first.mimeType, equals('image/jpeg'));
      });

      test('returns photos ordered by filename ascending', () async {
        final session = sessionBuilder.build();
        await Photo.db.insert(session, [
          _photo(filename: 'zebra.jpg', providerFileId: 'f3'),
          _photo(filename: 'apple.jpg', providerFileId: 'f1'),
          _photo(filename: 'mango.jpg', providerFileId: 'f2'),
        ]);
        await session.close();

        final result = await endpoints.photo.getPhotos(authed);

        expect(result.length, equals(3));
        expect(result[0].filename, equals('apple.jpg'));
        expect(result[1].filename, equals('mango.jpg'));
        expect(result[2].filename, equals('zebra.jpg'));
      });

      test('returns all photos when multiple exist', () async {
        final session = sessionBuilder.build();
        await Photo.db.insert(session, [
          _photo(filename: 'a.jpg', providerFileId: 'fa'),
          _photo(filename: 'b.jpg', providerFileId: 'fb'),
          _photo(filename: 'c.jpg', providerFileId: 'fc'),
          _photo(filename: 'd.jpg', providerFileId: 'fd'),
          _photo(filename: 'e.jpg', providerFileId: 'fe'),
        ]);
        await session.close();

        final result = await endpoints.photo.getPhotos(authed);
        expect(result, hasLength(5));
      });

      test('photos from different credentials are all returned', () async {
        final session = sessionBuilder.build();
        await Photo.db.insert(session, [
          _photo(credentialId: 1, filename: 'beach.jpg', providerFileId: 'c1f1'),
          _photo(credentialId: 2, filename: 'mountain.jpg', providerFileId: 'c2f1'),
        ]);
        await session.close();

        final result = await endpoints.photo.getPhotos(authed);

        expect(result, hasLength(2));
        expect(
          result.map((p) => p.credentialId).toSet(),
          containsAll([1, 2]),
        );
      });

      test('ordering is purely by filename, not by credentialId or fetchedAt',
          () async {
        final session = sessionBuilder.build();
        final earlier = DateTime.utc(2026, 1, 1);
        final later = DateTime.utc(2026, 6, 1);

        await Photo.db.insert(session, [
          Photo(
            credentialId: 2,
            providerFileId: 'fb',
            filename: 'bravo.jpg',
            mimeType: 'image/jpeg',
            fetchedAt: earlier,
          ),
          Photo(
            credentialId: 1,
            providerFileId: 'fa',
            filename: 'alpha.jpg',
            mimeType: 'image/jpeg',
            fetchedAt: later,
          ),
        ]);
        await session.close();

        final result = await endpoints.photo.getPhotos(authed);

        expect(result.first.filename, equals('alpha.jpg'));
        expect(result.last.filename, equals('bravo.jpg'));
      });

      test('photo id is populated in returned rows', () async {
        final session = sessionBuilder.build();
        await Photo.db.insertRow(session, _photo(filename: 'img.jpg'));
        await session.close();

        final result = await endpoints.photo.getPhotos(authed);

        expect(result.first.id, isNotNull);
        expect(result.first.id, greaterThan(0));
      });
    });
  });

  // SEC-04: PhotoEndpoint auth guards.
  withServerpod(
    'Given PhotoEndpoint auth guards (SEC-04)',
    (sessionBuilder, endpoints) {
      test('getPhotos rejects unauthenticated caller', () async {
        expect(
          () => endpoints.photo.getPhotos(sessionBuilder),
          throwsA(isA<Exception>()),
        );
      });

      test('authenticated caller can fetch photos', () async {
        final authed = sessionBuilder.copyWith(
          authentication:
              AuthenticationOverride.authenticationInfo('user-1', {}),
        );
        final result = await endpoints.photo.getPhotos(authed);
        expect(result, isA<List>());
      });
    },
  );
}
