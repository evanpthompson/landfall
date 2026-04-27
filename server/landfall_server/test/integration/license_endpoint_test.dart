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
    });
  });
}
