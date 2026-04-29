import 'package:test/test.dart';

import 'package:landfall_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';

CardPushRequest _card({
  String source = 'system.test',
  String title = 'Test card',
  String? externalId,
  bool? persistent,
  DateTime? expiresAt,
  String layout = 'medium',
}) {
  return CardPushRequest(
    source: source,
    title: title,
    externalId: externalId,
    persistent: persistent,
    expiresAt: expiresAt,
    layout: layout,
  );
}

void main() {
  withServerpod('Given card lifecycle (CardEndpoint)', (
    sessionBuilder,
    endpoints,
  ) {
    group('active card filtering', () {
      test('non-dismissed card with no expiresAt is always active', () async {
        await endpoints.card.pushCard(sessionBuilder, _card(title: 'Active'));
        final cards = await endpoints.card.getCards(sessionBuilder);
        expect(cards, hasLength(1));
      });

      test('card with future expiresAt is active', () async {
        await endpoints.card.pushCard(
          sessionBuilder,
          _card(
            expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
          ),
        );
        final cards = await endpoints.card.getCards(sessionBuilder);
        expect(cards, hasLength(1));
      });

      test('card with past expiresAt is excluded', () async {
        await endpoints.card.pushCard(
          sessionBuilder,
          _card(
            title: 'Expired',
            expiresAt:
                DateTime.now().toUtc().subtract(const Duration(seconds: 1)),
          ),
        );
        final cards = await endpoints.card.getCards(sessionBuilder);
        expect(cards, isEmpty);
      });

      test('dismissed card is excluded regardless of expiresAt', () async {
        final card = await endpoints.card.pushCard(
          sessionBuilder,
          _card(externalId: 'bye'),
        );
        await endpoints.card.dismissCard(sessionBuilder, card.externalId);
        final cards = await endpoints.card.getCards(sessionBuilder);
        expect(cards, isEmpty);
      });

      test('persistent card is active even with a past expiresAt', () async {
        await endpoints.card.pushCard(
          sessionBuilder,
          _card(
            title: 'Persistent',
            persistent: true,
            expiresAt:
                DateTime.now().toUtc().subtract(const Duration(hours: 1)),
          ),
        );
        final cards = await endpoints.card.getCards(sessionBuilder);
        expect(cards, hasLength(1));
        expect(cards.first.title, equals('Persistent'));
      });

      test('dismissed persistent card is excluded', () async {
        final card = await endpoints.card.pushCard(
          sessionBuilder,
          _card(externalId: 'dismiss-persistent', persistent: true),
        );
        await endpoints.card.dismissCard(sessionBuilder, card.externalId);
        final cards = await endpoints.card.getCards(sessionBuilder);
        expect(cards, isEmpty);
      });

      test('mix of active and expired returns only active', () async {
        await endpoints.card.pushCard(
          sessionBuilder,
          _card(title: 'Active 1'),
        );
        await endpoints.card.pushCard(
          sessionBuilder,
          _card(
            title: 'Expired',
            expiresAt:
                DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
          ),
        );
        await endpoints.card.pushCard(
          sessionBuilder,
          _card(title: 'Active 2'),
        );

        final cards = await endpoints.card.getCards(sessionBuilder);
        expect(cards, hasLength(2));
        expect(cards.map((c) => c.title), isNot(contains('Expired')));
      });
    });

    group('ticker routing', () {
      test('ticker cards are excluded from getCards', () async {
        await endpoints.card.pushCard(sessionBuilder, _card(title: 'Grid card'));
        await endpoints.card.pushCard(
          sessionBuilder,
          _card(title: 'Ticker msg', layout: 'ticker'),
        );

        final gridCards = await endpoints.card.getCards(sessionBuilder);
        expect(gridCards, hasLength(1));
        expect(gridCards.first.title, equals('Grid card'));
      });

      test('ticker cards appear in getTickerMessages', () async {
        await endpoints.card.pushCard(
          sessionBuilder,
          _card(
            title: 'Ticker msg',
            layout: 'ticker',
            expiresAt:
                DateTime.now().toUtc().add(const Duration(seconds: 30)),
          ),
        );

        final ticker = await endpoints.card.getTickerMessages(sessionBuilder);
        expect(ticker, hasLength(1));
        expect(ticker.first.title, equals('Ticker msg'));
        expect(ticker.first.layout, equals('ticker'));
      });

      test('grid cards do not appear in getTickerMessages', () async {
        await endpoints.card.pushCard(sessionBuilder, _card(title: 'Grid'));
        final ticker = await endpoints.card.getTickerMessages(sessionBuilder);
        expect(ticker, isEmpty);
      });

      test('expired ticker is excluded from getTickerMessages', () async {
        await endpoints.card.pushCard(
          sessionBuilder,
          _card(
            title: 'Old ticker',
            layout: 'ticker',
            expiresAt:
                DateTime.now().toUtc().subtract(const Duration(seconds: 1)),
          ),
        );

        final ticker = await endpoints.card.getTickerMessages(sessionBuilder);
        expect(ticker, isEmpty);
      });

      test('dismissed ticker is excluded from getTickerMessages', () async {
        final card = await endpoints.card.pushCard(
          sessionBuilder,
          _card(
            externalId: 'dismiss-ticker',
            title: 'Dismissed ticker',
            layout: 'ticker',
            expiresAt:
                DateTime.now().toUtc().add(const Duration(seconds: 30)),
          ),
        );
        await endpoints.card.dismissCard(sessionBuilder, card.externalId);

        final ticker = await endpoints.card.getTickerMessages(sessionBuilder);
        expect(ticker, isEmpty);
      });

      test('ticker buffer is capped at 10 entries', () async {
        for (var i = 0; i < 11; i++) {
          await endpoints.card.pushCard(
            sessionBuilder,
            _card(
              title: 'Ticker $i',
              layout: 'ticker',
              expiresAt:
                  DateTime.now().toUtc().add(const Duration(seconds: 30)),
            ),
          );
        }

        final ticker = await endpoints.card.getTickerMessages(sessionBuilder);
        expect(ticker, hasLength(10));
      });
    });

    group('card history', () {
      test('dismissed cards are retained in the database', () async {
        final card = await endpoints.card.pushCard(
          sessionBuilder,
          _card(externalId: 'history-dismiss'),
        );
        await endpoints.card.dismissCard(sessionBuilder, card.externalId);

        // Directly verify the card still exists in the DB with dismissedAt set.
        final row = await CardRow.db.findFirstRow(
          sessionBuilder.build(),
          where: (t) => t.externalId.equals('history-dismiss'),
        );
        expect(row, isNotNull);
        expect(row!.dismissedAt, isNotNull);
      });

      test('expired cards are retained in the database', () async {
        await endpoints.card.pushCard(
          sessionBuilder,
          _card(
            externalId: 'history-expired',
            expiresAt:
                DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
          ),
        );

        // Card is gone from active view...
        final active = await endpoints.card.getCards(sessionBuilder);
        expect(active.any((c) => c.externalId == 'history-expired'), isFalse);

        // ...but still exists in the DB.
        final row = await CardRow.db.findFirstRow(
          sessionBuilder.build(),
          where: (t) => t.externalId.equals('history-expired'),
        );
        expect(row, isNotNull);
        expect(row!.expiresAt, isNotNull);
      });
    });

    group('dismissCard', () {
      test('returns true when card found and dismissed', () async {
        final card = await endpoints.card.pushCard(
          sessionBuilder,
          _card(externalId: 'dismiss-me'),
        );
        final result =
            await endpoints.card.dismissCard(sessionBuilder, card.externalId);
        expect(result, isTrue);
      });

      test('returns false for unknown externalId', () async {
        final result =
            await endpoints.card.dismissCard(sessionBuilder, 'ghost-id');
        expect(result, isFalse);
      });

      test('re-pushing a dismissed card un-dismisses it', () async {
        final card = await endpoints.card.pushCard(
          sessionBuilder,
          _card(externalId: 'bounce'),
        );
        await endpoints.card.dismissCard(sessionBuilder, card.externalId);

        await endpoints.card.pushCard(
          sessionBuilder,
          _card(externalId: 'bounce', title: 'Back'),
        );

        final active = await endpoints.card.getCards(sessionBuilder);
        expect(active, hasLength(1));
        expect(active.first.title, equals('Back'));
        expect(active.first.dismissedAt, isNull);
      });
    });
  });
}
