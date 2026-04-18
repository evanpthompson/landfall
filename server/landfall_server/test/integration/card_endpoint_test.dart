import 'package:test/test.dart';

import 'package:landfall_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';

CardPushRequest _request({
  String source = 'system.test',
  String title = 'Test card',
  String? body,
  String? externalId,
  bool? persistent,
  DateTime? expiresAt,
}) {
  return CardPushRequest(
    source: source,
    title: title,
    body: body,
    externalId: externalId,
    persistent: persistent,
    expiresAt: expiresAt,
  );
}

void main() {
  withServerpod('Given CardEndpoint (unauthenticated local dev)', (
    sessionBuilder,
    endpoints,
  ) {
    group('pushCard', () {
      test('creates a card and returns it with a generated externalId',
          () async {
        final card = await endpoints.card.pushCard(
          sessionBuilder,
          _request(),
        );

        expect(card.id, isNotNull);
        expect(card.externalId, isNotEmpty);
        expect(card.source, equals('system.test'));
        expect(card.title, equals('Test card'));
        expect(card.dismissedAt, isNull);
      });

      test('uses provided externalId', () async {
        final card = await endpoints.card.pushCard(
          sessionBuilder,
          _request(externalId: 'stable-id'),
        );
        expect(card.externalId, equals('stable-id'));
      });

      test('re-pushing same externalId updates card in-place', () async {
        await endpoints.card.pushCard(
          sessionBuilder,
          _request(externalId: 'idempotent', title: 'First'),
        );
        final updated = await endpoints.card.pushCard(
          sessionBuilder,
          _request(externalId: 'idempotent', title: 'Second'),
        );
        expect(updated.title, equals('Second'));
        expect(updated.externalId, equals('idempotent'));
      });

      test('re-pushing un-dismisses a dismissed card', () async {
        final card = await endpoints.card.pushCard(
          sessionBuilder,
          _request(externalId: 'undismiss'),
        );
        await endpoints.card.dismissCard(sessionBuilder, card.externalId);

        final repushed = await endpoints.card.pushCard(
          sessionBuilder,
          _request(externalId: 'undismiss', title: 'Back'),
        );
        expect(repushed.dismissedAt, isNull);
      });
    });

    group('getCards', () {
      test('returns empty list when no cards exist', () async {
        final cards = await endpoints.card.getCards(sessionBuilder);
        expect(cards, isEmpty);
      });

      test('returns pushed cards', () async {
        await endpoints.card.pushCard(sessionBuilder, _request(title: 'One'));
        await endpoints.card.pushCard(sessionBuilder, _request(title: 'Two'));

        final cards = await endpoints.card.getCards(sessionBuilder);
        expect(cards.length, equals(2));
      });

      test('excludes dismissed cards', () async {
        final card = await endpoints.card.pushCard(
          sessionBuilder,
          _request(externalId: 'dismiss-me'),
        );
        await endpoints.card.pushCard(
          sessionBuilder,
          _request(title: 'Stays'),
        );
        await endpoints.card.dismissCard(sessionBuilder, card.externalId);

        final cards = await endpoints.card.getCards(sessionBuilder);
        expect(cards.length, equals(1));
        expect(cards.first.title, equals('Stays'));
      });

      test('excludes expired cards', () async {
        await endpoints.card.pushCard(
          sessionBuilder,
          CardPushRequest(
            source: 'system.test',
            title: 'Expired',
            expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
          ),
        );
        await endpoints.card.pushCard(
          sessionBuilder,
          _request(title: 'Active'),
        );

        final cards = await endpoints.card.getCards(sessionBuilder);
        expect(cards.length, equals(1));
        expect(cards.first.title, equals('Active'));
      });

      test('persistent cards are never expired', () async {
        await endpoints.card.pushCard(
          sessionBuilder,
          CardPushRequest(
            source: 'system.test',
            title: 'Persistent',
            persistent: true,
            expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
          ),
        );

        final cards = await endpoints.card.getCards(sessionBuilder);
        expect(cards.length, equals(1));
        expect(cards.first.title, equals('Persistent'));
      });
    });

    group('dismissCard', () {
      test('returns true and marks card dismissed', () async {
        final card = await endpoints.card.pushCard(
          sessionBuilder,
          _request(externalId: 'to-dismiss'),
        );
        final result = await endpoints.card.dismissCard(
          sessionBuilder,
          card.externalId,
        );
        expect(result, isTrue);
      });

      test('returns false for unknown externalId', () async {
        final result = await endpoints.card.dismissCard(
          sessionBuilder,
          'ghost-id',
        );
        expect(result, isFalse);
      });
    });
  });
}
