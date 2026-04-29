import 'package:test/test.dart';

import 'package:landfall_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';

const _testUserId = 'user-uuid-1234-5678-abcd';

TestSessionBuilder _authenticatedSession(TestSessionBuilder base) {
  return base.copyWith(
    authentication: AuthenticationOverride.authenticationInfo(
      _testUserId,
      {},
    ),
  );
}

void main() {
  withServerpod('Given LicenseEndpoint', (sessionBuilder, endpoints) {
    final authed = _authenticatedSession(sessionBuilder);

    group('getLicenseStatus', () {
      test('returns free tier when no license is activated', () async {
        final status = await endpoints.license.getLicenseStatus(authed);

        expect(status.tier, equals('free'));
        expect(status.activatedAt, isNull);
        expect(status.maskedKey, isNull);
      });

      test('returns free tier for unauthenticated session', () async {
        final status =
            await endpoints.license.getLicenseStatus(sessionBuilder);
        expect(status.tier, equals('free'));
      });
    });

    group('activateLicense', () {
      setUp(() async {
        // Insert a test license key (simulates post-Stripe-purchase key).
        await LicenseKey.db.insertRow(
          authed.build(),
          LicenseKey(
            key: 'LF-PRO-TEST-0001',
            tier: 'pro',
            purchasedAt: DateTime.now().toUtc(),
          ),
        );
      });

      test('activates key and returns pro status', () async {
        final status = await endpoints.license.activateLicense(
          authed,
          'LF-PRO-TEST-0001',
        );

        expect(status.tier, equals('pro'));
        expect(status.activatedAt, isNotNull);
        expect(status.maskedKey, contains('****'));
      });

      test('maskedKey preserves first and last segments', () async {
        final status = await endpoints.license.activateLicense(
          authed,
          'LF-PRO-TEST-0001',
        );

        expect(status.maskedKey, equals('LF-PRO-****-0001'));
      });

      test('subsequent getLicenseStatus reflects activated tier', () async {
        await endpoints.license.activateLicense(authed, 'LF-PRO-TEST-0001');

        final status = await endpoints.license.getLicenseStatus(authed);
        expect(status.tier, equals('pro'));
        expect(status.maskedKey, isNotNull);
      });

      test('throws when key does not exist', () async {
        expect(
          () => endpoints.license.activateLicense(authed, 'LF-PRO-FAKE-0000'),
          throwsA(anything),
        );
      });

      test('throws when re-activating an already-activated key', () async {
        await endpoints.license.activateLicense(authed, 'LF-PRO-TEST-0001');

        expect(
          () => endpoints.license.activateLicense(authed, 'LF-PRO-TEST-0001'),
          throwsA(anything),
        );
      });

      test('throws when key is activated by a different user', () async {
        final otherUser = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            'different-user-uuid',
            {},
          ),
        );

        // First user activates.
        await endpoints.license.activateLicense(authed, 'LF-PRO-TEST-0001');

        // Second user tries to use the same key.
        expect(
          () => endpoints.license.activateLicense(
              otherUser, 'LF-PRO-TEST-0001'),
          throwsA(anything),
        );
      });

      test('activatedAt is persisted and matches the returned timestamp',
          () async {
        final before = DateTime.now().toUtc().subtract(const Duration(seconds: 1));
        final status = await endpoints.license.activateLicense(
          authed,
          'LF-PRO-TEST-0001',
        );
        final after = DateTime.now().toUtc().add(const Duration(seconds: 1));

        expect(status.activatedAt!.isAfter(before), isTrue);
        expect(status.activatedAt!.isBefore(after), isTrue);

        final fetched = await endpoints.license.getLicenseStatus(authed);
        expect(fetched.activatedAt, isNotNull);
      });
    });

    group('license workflow: founding member tier', () {
      setUp(() async {
        await LicenseKey.db.insertRow(
          authed.build(),
          LicenseKey(
            key: 'LF-FM-TEST-0001',
            tier: 'foundingMember',
            purchasedAt: DateTime.now().toUtc(),
          ),
        );
      });

      test('founding member tier is returned after activation', () async {
        final status = await endpoints.license.activateLicense(
          authed,
          'LF-FM-TEST-0001',
        );
        expect(status.tier, equals('foundingMember'));
      });

      test('getLicenseStatus returns founding member tier after activation',
          () async {
        await endpoints.license.activateLicense(authed, 'LF-FM-TEST-0001');
        final status = await endpoints.license.getLicenseStatus(authed);
        expect(status.tier, equals('foundingMember'));
      });

      test('maskedKey format is correct for founding member key', () async {
        final status = await endpoints.license.activateLicense(
          authed,
          'LF-FM-TEST-0001',
        );
        expect(status.maskedKey, equals('LF-FM-****-0001'));
      });
    });

    group('license workflow: unauthenticated activation', () {
      setUp(() async {
        await LicenseKey.db.insertRow(
          authed.build(),
          LicenseKey(
            key: 'LF-PRO-NOAUTH-001',
            tier: 'pro',
            purchasedAt: DateTime.now().toUtc(),
          ),
        );
      });

      test('activateLicense throws for unauthenticated session', () async {
        expect(
          () => endpoints.license.activateLicense(
            sessionBuilder,
            'LF-PRO-NOAUTH-001',
          ),
          throwsA(anything),
        );
      });
    });

    group('license workflow: pack ownership', () {
      setUp(() async {
        final session = authed.build();
        await LicenseKey.db.insertRow(
          session,
          LicenseKey(
            key: 'LF-PRO-PACK-0001',
            tier: 'pro',
            purchasedAt: DateTime.now().toUtc(),
          ),
        );
        await IntegrationPack.db.insertRow(
          session,
          IntegrationPack(
            packId: 'sports_scores',
            name: 'Sports Scores',
            description: 'Live game tickers.',
            version: '1.0.0',
            priceUsd: 6.0,
            authorName: 'Landfall',
            isActive: true,
          ),
        );
      });

      test('pack is not owned before activation', () async {
        final owned = await endpoints.pack.getOwnedPacks(authed);
        expect(owned, isEmpty);
      });

      test('pack purchased after license activation appears in getOwnedPacks',
          () async {
        await endpoints.license.activateLicense(authed, 'LF-PRO-PACK-0001');

        // Simulate pack grant (as Stripe webhook would do post-purchase).
        await OwnedPack.db.insertRow(
          authed.build(),
          OwnedPack(
            userId: _testUserId,
            packId: 'sports_scores',
            grantedAt: DateTime.now().toUtc(),
          ),
        );

        final owned = await endpoints.pack.getOwnedPacks(authed);
        expect(owned.any((p) => p.packId == 'sports_scores'), isTrue);
        expect(owned.first.isOwned, isTrue);
      });
    });
  });
}
