import 'package:test/test.dart';

import 'package:landfall_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';

CardPushRequest _request({
  String source = 'agent.test',
  String title = 'Test card',
  String? body,
  String? layout,
  String? priority,
  String? externalId,
}) {
  return CardPushRequest(
    source: source,
    title: title,
    body: body,
    layout: layout,
    priority: priority,
    externalId: externalId,
  );
}

void main() {
  withServerpod('Given AgentEndpoint', (sessionBuilder, endpoints) {
    late String validApiKey;

    setUp(() async {
      // Generate a fresh key for each test (DB is rolled back between tests).
      final response = await endpoints.apiKey.generateKey(
        sessionBuilder,
        'Test Key',
        'test-management-token',
      );
      validApiKey = response.plainTextKey;
    });

    group('pushCard', () {
      test('creates a card and returns it', () async {
        final card = await endpoints.agent.pushCard(
          sessionBuilder,
          validApiKey,
          _request(),
        );

        expect(card.id, isNotNull);
        expect(card.source, equals('agent.test'));
        expect(card.title, equals('Test card'));
        expect(card.externalId, isNotEmpty);
        expect(card.dismissedAt, isNull);
      });

      test('uses provided externalId', () async {
        final card = await endpoints.agent.pushCard(
          sessionBuilder,
          validApiKey,
          _request(externalId: 'my-stable-id'),
        );

        expect(card.externalId, equals('my-stable-id'));
      });

      test('re-pushing same externalId updates card in-place', () async {
        await endpoints.agent.pushCard(
          sessionBuilder,
          validApiKey,
          _request(externalId: 'stable', title: 'Original'),
        );

        final updated = await endpoints.agent.pushCard(
          sessionBuilder,
          validApiKey,
          _request(externalId: 'stable', title: 'Updated'),
        );

        expect(updated.title, equals('Updated'));
        expect(updated.externalId, equals('stable'));
      });

      test('re-pushing un-dismisses a dismissed card', () async {
        final card = await endpoints.agent.pushCard(
          sessionBuilder,
          validApiKey,
          _request(externalId: 'undismiss-me'),
        );

        await endpoints.agent.dismissCard(
          sessionBuilder,
          validApiKey,
          card.externalId,
        );

        final repushed = await endpoints.agent.pushCard(
          sessionBuilder,
          validApiKey,
          _request(externalId: 'undismiss-me', title: 'Back again'),
        );

        expect(repushed.dismissedAt, isNull);
      });

      test('defaults layout to medium and priority to normal', () async {
        final card = await endpoints.agent.pushCard(
          sessionBuilder,
          validApiKey,
          _request(),
        );

        expect(card.layout, equals('medium'));
        expect(card.priority, equals('normal'));
      });

      test('rejects invalid API key', () async {
        expect(
          () => endpoints.agent.pushCard(
            sessionBuilder,
            'lf_notavalidkey0000000000000000000',
            _request(),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('rejects revoked API key', () async {
        final response = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'Revocable Key',
          'test-management-token',
        );
        await endpoints.apiKey.revokeKey(
          sessionBuilder,
          response.key.id!,
          'test-management-token',
        );

        expect(
          () => endpoints.agent.pushCard(
            sessionBuilder,
            response.plainTextKey,
            _request(),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('rejects empty title', () async {
        expect(
          () => endpoints.agent.pushCard(
            sessionBuilder,
            validApiKey,
            _request(title: ''),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('rejects invalid source format', () async {
        expect(
          () => endpoints.agent.pushCard(
            sessionBuilder,
            validApiKey,
            _request(source: 'nodot'),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('rejects invalid layout', () async {
        expect(
          () => endpoints.agent.pushCard(
            sessionBuilder,
            validApiKey,
            _request(layout: 'gigantic'),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('increments usage count on each pushCard', () async {
        await endpoints.agent.pushCard(
          sessionBuilder,
          validApiKey,
          _request(),
        );
        await endpoints.agent.pushCard(
          sessionBuilder,
          validApiKey,
          _request(title: 'Second card'),
        );

        final keys = await endpoints.apiKey.listKeys(
          sessionBuilder,
          'test-management-token',
        );
        final key = keys.firstWhere((k) => k.usageCount == 2);
        expect(key.usageCount, equals(2));
      });
    });

    group('listCards', () {
      test('returns empty list when no cards', () async {
        final cards = await endpoints.agent.listCards(
          sessionBuilder,
          validApiKey,
        );
        expect(cards, isEmpty);
      });

      test('returns pushed cards', () async {
        await endpoints.agent.pushCard(
          sessionBuilder,
          validApiKey,
          _request(title: 'Card 1'),
        );
        await endpoints.agent.pushCard(
          sessionBuilder,
          validApiKey,
          _request(title: 'Card 2'),
        );

        final cards = await endpoints.agent.listCards(
          sessionBuilder,
          validApiKey,
        );
        expect(cards.length, equals(2));
      });

      test('excludes dismissed cards', () async {
        final card = await endpoints.agent.pushCard(
          sessionBuilder,
          validApiKey,
          _request(externalId: 'to-dismiss'),
        );
        await endpoints.agent.pushCard(
          sessionBuilder,
          validApiKey,
          _request(title: 'Stays visible'),
        );
        await endpoints.agent.dismissCard(
          sessionBuilder,
          validApiKey,
          card.externalId,
        );

        final cards = await endpoints.agent.listCards(
          sessionBuilder,
          validApiKey,
        );
        expect(cards.length, equals(1));
        expect(cards.first.title, equals('Stays visible'));
      });

      test('excludes expired cards', () async {
        await endpoints.agent.pushCard(
          sessionBuilder,
          validApiKey,
          CardPushRequest(
            source: 'agent.test',
            title: 'Expired card',
            expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
          ),
        );
        await endpoints.agent.pushCard(
          sessionBuilder,
          validApiKey,
          _request(title: 'Not expired'),
        );

        final cards = await endpoints.agent.listCards(
          sessionBuilder,
          validApiKey,
        );
        expect(cards.length, equals(1));
        expect(cards.first.title, equals('Not expired'));
      });

      test('rejects invalid API key', () async {
        expect(
          () => endpoints.agent.listCards(sessionBuilder, 'lf_badkey'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updateCard', () {
      test('updates existing card fields', () async {
        final card = await endpoints.agent.pushCard(
          sessionBuilder,
          validApiKey,
          _request(externalId: 'update-me', title: 'Before'),
        );

        final updated = await endpoints.agent.updateCard(
          sessionBuilder,
          validApiKey,
          card.externalId,
          _request(title: 'After', source: 'agent.updated'),
        );

        expect(updated.title, equals('After'));
        expect(updated.source, equals('agent.updated'));
        expect(updated.externalId, equals('update-me'));
      });

      test('throws when externalId not found', () async {
        expect(
          () => endpoints.agent.updateCard(
            sessionBuilder,
            validApiKey,
            'does-not-exist',
            _request(),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('not-found error message does not echo the supplied externalId',
          () async {
        const sentinel = 'sentinel-id-that-must-not-appear-in-response';
        Exception? caught;
        try {
          await endpoints.agent.updateCard(
            sessionBuilder,
            validApiKey,
            sentinel,
            _request(),
          );
        } catch (e) {
          caught = e as Exception;
        }
        expect(caught, isNotNull,
            reason: 'updateCard with unknown id should throw');
        expect(
          caught.toString(),
          isNot(contains(sentinel)),
          reason: 'error message must not echo the caller-supplied externalId',
        );
      });

      test('rejects invalid request on update', () async {
        final card = await endpoints.agent.pushCard(
          sessionBuilder,
          validApiKey,
          _request(externalId: 'validate-me'),
        );

        expect(
          () => endpoints.agent.updateCard(
            sessionBuilder,
            validApiKey,
            card.externalId,
            _request(title: ''),
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('dismissCard', () {
      test('returns true and marks card dismissed', () async {
        final card = await endpoints.agent.pushCard(
          sessionBuilder,
          validApiKey,
          _request(externalId: 'bye'),
        );

        final result = await endpoints.agent.dismissCard(
          sessionBuilder,
          validApiKey,
          card.externalId,
        );

        expect(result, isTrue);

        final cards = await endpoints.agent.listCards(
          sessionBuilder,
          validApiKey,
        );
        expect(cards, isEmpty);
      });

      test('returns false for unknown externalId', () async {
        final result = await endpoints.agent.dismissCard(
          sessionBuilder,
          validApiKey,
          'not-here',
        );
        expect(result, isFalse);
      });

      test('rejects invalid API key', () async {
        expect(
          () => endpoints.agent.dismissCard(sessionBuilder, 'bad', 'id'),
          throwsA(isA<Exception>()),
        );
      });
    });

    // A09:2025 — Security Logging. Verifies that auth failure logging in
    // ApiKeyService.authenticate() does not suppress exceptions.
    group('A09 audit logging — auth failures still throw', () {
      test('pushCard with invalid key still throws after auth failure logging',
          () async {
        expect(
          () => endpoints.agent.pushCard(
            sessionBuilder,
            'lf_invalidkey000000000000000000000',
            _request(),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('pushCard with empty key still throws after auth failure logging',
          () async {
        expect(
          () => endpoints.agent.pushCard(sessionBuilder, '', _request()),
          throwsA(isA<Exception>()),
        );
      });

      test('dismissCard with invalid key still throws after auth failure logging',
          () async {
        expect(
          () => endpoints.agent.dismissCard(
            sessionBuilder,
            'lf_invalidkey000000000000000000000',
            'some-id',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
