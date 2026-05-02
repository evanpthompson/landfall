import 'package:test/test.dart';

import 'package:landfall_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given ticker (AgentEndpoint.pushTicker)', (
    sessionBuilder,
    endpoints,
  ) {
    late String apiKey;

    setUp(() async {
      final response =
          await endpoints.apiKey.generateKey(
            sessionBuilder,
            'Ticker Key',
            'test-management-token',
          );
      apiKey = response.plainTextKey;
    });

    group('pushTicker', () {
      test('creates a ticker card with layout = ticker', () async {
        final card = await endpoints.agent.pushTicker(
          sessionBuilder,
          apiKey,
          'agent.test',
          'Researching vacation destinations…',
        );

        expect(card.layout, equals('ticker'));
        expect(card.title, equals('Researching vacation destinations…'));
        expect(card.source, equals('agent.test'));
      });

      test('ticker card has a default TTL of ~30 seconds', () async {
        final before = DateTime.now().toUtc();
        final card = await endpoints.agent.pushTicker(
          sessionBuilder,
          apiKey,
          'agent.test',
          'Working…',
        );

        expect(card.expiresAt, isNotNull);
        // expiresAt should be roughly 30s from now — allow a 5s window.
        final expectedExpiry = before.add(const Duration(seconds: 30));
        expect(
          card.expiresAt!.isAfter(expectedExpiry.subtract(const Duration(seconds: 5))),
          isTrue,
        );
        expect(
          card.expiresAt!.isBefore(expectedExpiry.add(const Duration(seconds: 5))),
          isTrue,
        );
      });

      test('custom expiresAt overrides the default TTL', () async {
        final customExpiry =
            DateTime.now().toUtc().add(const Duration(minutes: 5));
        final card = await endpoints.agent.pushTicker(
          sessionBuilder,
          apiKey,
          'agent.test',
          'Long task…',
          expiresAt: customExpiry,
        );

        // Should be close to the custom expiry, not 30s.
        final diff = card.expiresAt!.difference(customExpiry).abs();
        expect(diff.inSeconds, lessThan(2));
      });

      test('ticker card is persistent = false', () async {
        final card = await endpoints.agent.pushTicker(
          sessionBuilder,
          apiKey,
          'agent.test',
          'Heartbeat',
        );
        expect(card.persistent, isFalse);
      });

      test('ticker card is priority = ephemeral', () async {
        final card = await endpoints.agent.pushTicker(
          sessionBuilder,
          apiKey,
          'agent.test',
          'Heartbeat',
        );
        expect(card.priority, equals('ephemeral'));
      });

      test('rejects invalid API key', () async {
        expect(
          () => endpoints.agent.pushTicker(
            sessionBuilder,
            'lf_badkey00000000000000000000000000',
            'agent.test',
            'Fail',
          ),
          throwsA(anything),
        );
      });

      test('ticker cards are not returned by listCards', () async {
        await endpoints.agent.pushTicker(
          sessionBuilder,
          apiKey,
          'agent.test',
          'Silent ticker',
        );

        final cards =
            await endpoints.agent.listCards(sessionBuilder, apiKey);
        expect(cards, isEmpty);
      });

      test('ticker cards appear in getTickerMessages', () async {
        await endpoints.agent.pushTicker(
          sessionBuilder,
          apiKey,
          'agent.test',
          'Visible ticker',
        );

        final ticker =
            await endpoints.card.getTickerMessages(sessionBuilder);
        expect(ticker, hasLength(1));
        expect(ticker.first.title, equals('Visible ticker'));
      });

      test('expired ticker does not appear in getTickerMessages', () async {
        await endpoints.agent.pushTicker(
          sessionBuilder,
          apiKey,
          'agent.test',
          'Gone',
          expiresAt:
              DateTime.now().toUtc().subtract(const Duration(seconds: 1)),
        );

        final ticker =
            await endpoints.card.getTickerMessages(sessionBuilder);
        expect(ticker, isEmpty);
      });
    });

    group('ticker persistence restriction', () {
      test('pushCard with layout=ticker and persistent=true is rejected',
          () async {
        expect(
          () => endpoints.agent.pushCard(
            sessionBuilder,
            apiKey,
            CardPushRequest(
              source: 'agent.test',
              title: 'Persistent ticker attempt',
              layout: 'ticker',
              persistent: true,
            ),
          ),
          throwsA(anything),
        );
      });
    });

    group('ticker buffer cap', () {
      test('getTickerMessages returns at most 10 entries', () async {
        for (var i = 0; i < 11; i++) {
          await endpoints.agent.pushTicker(
            sessionBuilder,
            apiKey,
            'agent.test',
            'Ticker $i',
          );
        }

        final ticker =
            await endpoints.card.getTickerMessages(sessionBuilder);
        expect(ticker, hasLength(10));
      });

      test('buffer returns the most recent entries when over cap', () async {
        for (var i = 0; i < 11; i++) {
          await endpoints.agent.pushTicker(
            sessionBuilder,
            apiKey,
            'agent.test',
            'Ticker $i',
          );
        }

        final ticker =
            await endpoints.card.getTickerMessages(sessionBuilder);
        // The 11th push (index 10) should be the newest and appear first
        // (getTickerMessages is ordered newest-first).
        expect(ticker.first.title, equals('Ticker 10'));
        // The oldest (Ticker 0) should be dropped.
        expect(ticker.any((c) => c.title == 'Ticker 0'), isFalse);
      });
    });
  });
}
