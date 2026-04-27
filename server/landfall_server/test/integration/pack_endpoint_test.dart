import 'package:serverpod/serverpod.dart';
import 'package:serverpod_test/serverpod_test.dart';
import 'package:test/test.dart';

import 'package:landfall_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';

const _testUserId = 'pack-test-user-uuid';

TestSessionBuilder _authenticatedSession(TestSessionBuilder base) {
  return base.copyWith(
    authentication: AuthenticationOverride.authenticationInfo(
      _testUserId,
      {},
    ),
  );
}

void main() {
  withServerpod('Given PackEndpoint', (sessionBuilder, endpoints) {
    final authed = _authenticatedSession(sessionBuilder);

    setUp(() async {
      final session = authed.build();
      await IntegrationPack.db.insertRow(
        session,
        IntegrationPack(
          packId: 'test_pack_a',
          name: 'Test Pack A',
          description: 'A test pack.',
          version: '1.0.0',
          priceUsd: 5.0,
          authorName: 'Landfall',
          isActive: true,
        ),
      );
      await IntegrationPack.db.insertRow(
        session,
        IntegrationPack(
          packId: 'test_pack_b',
          name: 'Test Pack B',
          description: 'Another test pack.',
          version: '1.0.0',
          priceUsd: 8.0,
          authorName: 'Landfall',
          isActive: true,
        ),
      );
      await IntegrationPack.db.insertRow(
        session,
        IntegrationPack(
          packId: 'inactive_pack',
          name: 'Inactive Pack',
          description: 'Not shown.',
          version: '1.0.0',
          priceUsd: 5.0,
          authorName: 'Landfall',
          isActive: false,
        ),
      );
    });

    group('listPacks', () {
      test('returns only active packs', () async {
        final packs = await endpoints.pack.listPacks(authed);

        expect(packs, hasLength(2));
        expect(packs.every((p) => p.isOwned == false), isTrue);
      });

      test('does not include inactive packs', () async {
        final packs = await endpoints.pack.listPacks(authed);

        expect(packs.any((p) => p.packId == 'inactive_pack'), isFalse);
      });

      test('pack info has correct fields', () async {
        final packs = await endpoints.pack.listPacks(authed);
        final packA = packs.firstWhere((p) => p.packId == 'test_pack_a');

        expect(packA.name, equals('Test Pack A'));
        expect(packA.priceUsd, equals(5.0));
        expect(packA.authorName, equals('Landfall'));
      });

      test('unauthenticated session sees packs as unowned', () async {
        final packs = await endpoints.pack.listPacks(sessionBuilder);
        expect(packs.every((p) => !p.isOwned), isTrue);
      });
    });

    group('getOwnedPacks', () {
      test('returns empty list when no packs are owned', () async {
        final owned = await endpoints.pack.getOwnedPacks(authed);
        expect(owned, isEmpty);
      });

      test('returns empty list for unauthenticated session', () async {
        final owned = await endpoints.pack.getOwnedPacks(sessionBuilder);
        expect(owned, isEmpty);
      });

      test('returns owned pack after grant', () async {
        await OwnedPack.db.insertRow(
          authed.build(),
          OwnedPack(
            userId: _testUserId,
            packId: 'test_pack_a',
            grantedAt: DateTime.now().toUtc(),
          ),
        );

        final owned = await endpoints.pack.getOwnedPacks(authed);
        expect(owned, hasLength(1));
        expect(owned.first.packId, equals('test_pack_a'));
        expect(owned.first.isOwned, isTrue);
      });

      test('listPacks marks owned pack as isOwned true', () async {
        await OwnedPack.db.insertRow(
          authed.build(),
          OwnedPack(
            userId: _testUserId,
            packId: 'test_pack_b',
            grantedAt: DateTime.now().toUtc(),
          ),
        );

        final packs = await endpoints.pack.listPacks(authed);
        final packB = packs.firstWhere((p) => p.packId == 'test_pack_b');
        final packA = packs.firstWhere((p) => p.packId == 'test_pack_a');

        expect(packB.isOwned, isTrue);
        expect(packA.isOwned, isFalse);
      });
    });
  });
}
