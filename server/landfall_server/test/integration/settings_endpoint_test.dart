import 'package:serverpod/serverpod.dart' show UuidValue;
import 'package:test/test.dart';

import 'package:landfall_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';

const _testUserId = '100000000001';

TestSessionBuilder _authenticatedSession(TestSessionBuilder base) {
  return base.copyWith(
    authentication: AuthenticationOverride.authenticationInfo(
      _testUserId,
      {},
    ),
  );
}

LinkedCredential _credential({
  String provider = 'google',
  String providerEmail = 'test@example.com',
  String authUserId = '00000000-0000-4000-8000-000000000001',
  bool isActive = true,
}) {
  final now = DateTime.now().toUtc();
  return LinkedCredential(
    authUserId: UuidValue.fromString(authUserId),
    provider: provider,
    providerEmail: providerEmail,
    accessToken: 'tok_test',
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  withServerpod('Given SettingsEndpoint', (sessionBuilder, endpoints) {
    final authed = _authenticatedSession(sessionBuilder);

    setUp(() async {
      final session = sessionBuilder.build();
      await LinkedCredential.db.deleteWhere(
        session,
        where: (t) => t.id > 0,
      );
      await session.close();
    });

    group('getLinkedCredentials', () {
      test('rejects unauthenticated caller', () async {
        expect(
          () => endpoints.settings.getLinkedCredentials(sessionBuilder),
          throwsA(isA<Exception>()),
        );
      });

      test('returns empty list when no credentials exist', () async {
        final result =
            await endpoints.settings.getLinkedCredentials(authed);
        expect(result, isEmpty);
      });

      test('returns active credentials as summaries', () async {
        final session = authed.build();
        await LinkedCredential.db.insertRow(
          session,
          _credential(provider: 'google', providerEmail: 'alice@example.com'),
        );
        await session.close();

        final result =
            await endpoints.settings.getLinkedCredentials(authed);

        expect(result, hasLength(1));
        expect(result.first.provider, equals('google'));
        expect(result.first.providerEmail, equals('alice@example.com'));
        expect(result.first.isActive, isTrue);
      });

      test('excludes inactive credentials', () async {
        final session = authed.build();
        await LinkedCredential.db.insertRow(
          session,
          _credential(
            provider: 'google',
            providerEmail: 'active@example.com',
            isActive: true,
          ),
        );
        await LinkedCredential.db.insertRow(
          session,
          _credential(
            provider: 'microsoft',
            providerEmail: 'inactive@example.com',
            isActive: false,
          ),
        );
        await session.close();

        final result =
            await endpoints.settings.getLinkedCredentials(authed);

        expect(result, hasLength(1));
        expect(result.first.providerEmail, equals('active@example.com'));
      });

      test('does not expose accessToken in summary', () async {
        final session = authed.build();
        await LinkedCredential.db.insertRow(
          session,
          _credential(provider: 'google'),
        );
        await session.close();

        final result =
            await endpoints.settings.getLinkedCredentials(authed);

        expect(result.first, isA<LinkedCredentialSummary>());
        // LinkedCredentialSummary has no token field — structural check via type.
      });

      test('returns multiple providers ordered by createdAt', () async {
        final session = authed.build();
        final earlier = DateTime.utc(2026, 1, 1);
        final later = DateTime.utc(2026, 3, 1);

        await LinkedCredential.db.insertRow(
          session,
          LinkedCredential(
            authUserId: UuidValue.fromString(
                '00000000-0000-4000-8000-000000000001'),
            provider: 'microsoft',
            providerEmail: 'ms@example.com',
            accessToken: 'tok',
            isActive: true,
            createdAt: later,
            updatedAt: later,
          ),
        );
        await LinkedCredential.db.insertRow(
          session,
          LinkedCredential(
            authUserId: UuidValue.fromString(
                '00000000-0000-4000-8000-000000000001'),
            provider: 'google',
            providerEmail: 'g@example.com',
            accessToken: 'tok',
            isActive: true,
            createdAt: earlier,
            updatedAt: earlier,
          ),
        );
        await session.close();

        final result =
            await endpoints.settings.getLinkedCredentials(authed);

        expect(result, hasLength(2));
        expect(result.first.provider, equals('google'));
        expect(result.last.provider, equals('microsoft'));
      });

      test('summary id matches the stored credential id', () async {
        final session = authed.build();
        final inserted = await LinkedCredential.db.insertRow(
          session,
          _credential(),
        );
        await session.close();

        final result =
            await endpoints.settings.getLinkedCredentials(authed);

        expect(result.first.id, equals(inserted.id));
      });
    });

    group('getMyAuthUserId', () {
      test('rejects unauthenticated caller', () async {
        expect(
          () => endpoints.settings.getMyAuthUserId(sessionBuilder),
          throwsA(isA<Exception>()),
        );
      });

      test('returns a valid UUID-formatted string for authenticated caller',
          () async {
        final userId = await endpoints.settings.getMyAuthUserId(authed);

        final uuidPattern = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        );
        expect(uuidPattern.hasMatch(userId), isTrue,
            reason: 'Expected a UUID, got: $userId');
      });

      test('returns deterministic ID for the same authenticated session',
          () async {
        final id1 = await endpoints.settings.getMyAuthUserId(authed);
        final id2 = await endpoints.settings.getMyAuthUserId(authed);
        expect(id1, equals(id2));
      });

      test('returns different IDs for different authenticated users', () async {
        final authed2 = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            '200000000002',
            {},
          ),
        );

        final id1 = await endpoints.settings.getMyAuthUserId(authed);
        final id2 = await endpoints.settings.getMyAuthUserId(authed2);
        expect(id1, isNot(equals(id2)));
      });
    });

    group('createCalendarLinkTicket', () {
      test('rejects unauthenticated caller', () async {
        expect(
          () => endpoints.settings.createCalendarLinkTicket(sessionBuilder),
          throwsA(isA<Exception>()),
        );
      });

      test('returns a non-empty ticket for an authenticated caller', () async {
        final ticket =
            await endpoints.settings.createCalendarLinkTicket(authed);
        expect(ticket, isNotEmpty);
      });

      test('mints a distinct ticket on each call (single-use)', () async {
        final a = await endpoints.settings.createCalendarLinkTicket(authed);
        final b = await endpoints.settings.createCalendarLinkTicket(authed);
        expect(a, isNot(equals(b)));
      });
    });
  });
}
