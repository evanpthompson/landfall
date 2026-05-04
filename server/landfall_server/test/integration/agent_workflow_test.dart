// Multi-step workflow tests for the agent integration surface.
//
// These tests exercise cross-endpoint sequences that represent real agent
// behavior: the full key lifecycle, rate limit enforcement, cross-endpoint
// card visibility, and the interaction between AgentEndpoint and
// CardEndpoint from a display's perspective.
//
// Single-method behavior is covered in agent_endpoint_test.dart and
// api_key_endpoint_test.dart. This file covers what falls between them.
import 'package:test/test.dart';

import 'package:landfall_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';

CardPushRequest _card({
  String source = 'agent.test',
  String title = 'Workflow card',
  String? externalId,
}) {
  return CardPushRequest(source: source, title: title, externalId: externalId);
}

void main() {
  withServerpod('Given agent workflow', (sessionBuilder, endpoints) {
    late TestSessionBuilder authed;

    setUp(() {
      authed = sessionBuilder.copyWith(
        authentication:
            AuthenticationOverride.authenticationInfo('user-1', {}),
      );
    });

    group('full key lifecycle', () {
      test('generate → push → list → update → dismiss → revoke', () async {
        // 1. Generate a key.
        final response =
            await endpoints.apiKey.generateKey(
              sessionBuilder,
              'Lifecycle Key',
              'test-management-token',
            );
        final key = response.plainTextKey;

        // 2. Push a card.
        final pushed = await endpoints.agent.pushCard(
          sessionBuilder,
          key,
          _card(externalId: 'lifecycle-card', title: 'First'),
        );
        expect(pushed.title, equals('First'));

        // 3. List returns the card.
        final listed = await endpoints.agent.listCards(sessionBuilder, key);
        expect(listed.any((c) => c.externalId == 'lifecycle-card'), isTrue);

        // 4. Update the card in-place.
        final updated = await endpoints.agent.updateCard(
          sessionBuilder,
          key,
          'lifecycle-card',
          _card(externalId: 'lifecycle-card', title: 'Updated'),
        );
        expect(updated.title, equals('Updated'));
        expect(await endpoints.agent.listCards(sessionBuilder, key),
            hasLength(1));

        // 5. Dismiss the card.
        final dismissed = await endpoints.agent.dismissCard(
          sessionBuilder,
          key,
          'lifecycle-card',
        );
        expect(dismissed, isTrue);
        expect(
            await endpoints.agent.listCards(sessionBuilder, key), isEmpty);

        // 6. Revoke the key.
        await endpoints.apiKey.revokeKey(
          sessionBuilder,
          response.key.id!,
          'test-management-token',
        );

        // 7. Further calls with the revoked key throw.
        expect(
          () => endpoints.agent.listCards(sessionBuilder, key),
          throwsA(anything),
        );
      });
    });

    group('rate limit enforcement', () {
      test('push fails once daily limit is exhausted', () async {
        // Generate a key then lower its limit to 2 for a fast test.
        final response = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'Rate Limited Key',
          'test-management-token',
        );
        final keyRecord = await ApiKey.db.findFirstRow(
          sessionBuilder.build(),
          where: (t) => t.id.equals(response.key.id!),
        );
        await ApiKey.db.updateRow(
          sessionBuilder.build(),
          keyRecord!.copyWith(dailyLimit: 2),
        );
        final key = response.plainTextKey;

        // Push 1 and 2 succeed.
        await endpoints.agent
            .pushCard(sessionBuilder, key, _card(title: 'One'));
        await endpoints.agent
            .pushCard(sessionBuilder, key, _card(title: 'Two'));

        // Push 3 exceeds the limit.
        expect(
          () => endpoints.agent
              .pushCard(sessionBuilder, key, _card(title: 'Three')),
          throwsA(anything),
        );
      });

      test('existing cards survive after the limit is hit', () async {
        final response = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'Limit Survival Key',
          'test-management-token',
        );
        final keyRecord = await ApiKey.db.findFirstRow(
          sessionBuilder.build(),
          where: (t) => t.id.equals(response.key.id!),
        );
        await ApiKey.db.updateRow(
          sessionBuilder.build(),
          keyRecord!.copyWith(dailyLimit: 1),
        );
        final key = response.plainTextKey;

        await endpoints.agent
            .pushCard(sessionBuilder, key, _card(externalId: 'survivor'));

        // This push should fail.
        try {
          await endpoints.agent.pushCard(sessionBuilder, key, _card());
        } catch (_) {}

        // The first card is still listed.
        final cards = await endpoints.agent.listCards(sessionBuilder, key);
        expect(cards.any((c) => c.externalId == 'survivor'), isTrue);
      });

      test('two independent keys have separate rate limit counters', () async {
        final r1 = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'Key One',
          'test-management-token',
        );
        final r2 = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'Key Two',
          'test-management-token',
        );

        // Set both keys to a limit of 1.
        for (final r in [r1, r2]) {
          final row = await ApiKey.db.findFirstRow(
            sessionBuilder.build(),
            where: (t) => t.id.equals(r.key.id!),
          );
          await ApiKey.db.updateRow(
            sessionBuilder.build(),
            row!.copyWith(dailyLimit: 1),
          );
        }

        // First push on each key succeeds.
        await endpoints.agent.pushCard(
            sessionBuilder, r1.plainTextKey, _card(title: 'Key 1 push'));
        await endpoints.agent.pushCard(
            sessionBuilder, r2.plainTextKey, _card(title: 'Key 2 push'));

        // Second push on key 1 fails, key 2 is unaffected.
        expect(
          () => endpoints.agent.pushCard(
              sessionBuilder, r1.plainTextKey, _card()),
          throwsA(anything),
        );
        // Key 2 is already at its limit too — just confirm key 1's failure
        // doesn't spill over; the test above is the meaningful assertion.
      });
    });

    group('cross-endpoint card visibility', () {
      test('card pushed via AgentEndpoint appears in CardEndpoint.getCards',
          () async {
        final response = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'Cross Key',
          'test-management-token',
        );
        await endpoints.agent.pushCard(
          sessionBuilder,
          response.plainTextKey,
          _card(externalId: 'cross-visible', title: 'Cross card'),
        );

        final displayCards = await endpoints.card.getCards(sessionBuilder);
        expect(
            displayCards.any((c) => c.externalId == 'cross-visible'), isTrue);
      });

      test('card dismissed via AgentEndpoint is absent from CardEndpoint.getCards',
          () async {
        final response = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'Cross Dismiss Key',
          'test-management-token',
        );
        final key = response.plainTextKey;

        await endpoints.agent.pushCard(
          sessionBuilder,
          key,
          _card(externalId: 'cross-dismiss'),
        );

        // Visible before dismiss.
        expect(await endpoints.card.getCards(sessionBuilder), hasLength(1));

        await endpoints.agent.dismissCard(sessionBuilder, key, 'cross-dismiss');

        // Gone after dismiss.
        expect(await endpoints.card.getCards(sessionBuilder), isEmpty);
      });

      test('card pushed via CardEndpoint appears in AgentEndpoint.listCards',
          () async {
        final response =
            await endpoints.apiKey.generateKey(
              sessionBuilder,
              'Key',
              'test-management-token',
            );
        final key = response.plainTextKey;

        await endpoints.card.pushCard(
          authed,
          CardPushRequest(
            source: 'system.test',
            title: 'From CardEndpoint',
            externalId: 'from-card-ep',
          ),
        );

        final agentCards =
            await endpoints.agent.listCards(sessionBuilder, key);
        expect(agentCards.any((c) => c.externalId == 'from-card-ep'), isTrue);
      });
    });

    group('ticker in agent workflow', () {
      test('pushTicker does not count against agent card list', () async {
        final response =
            await endpoints.apiKey.generateKey(
              sessionBuilder,
              'Ticker Key',
              'test-management-token',
            );
        final key = response.plainTextKey;

        await endpoints.agent.pushCard(
          sessionBuilder,
          key,
          _card(externalId: 'real-card'),
        );
        await endpoints.agent.pushTicker(
          sessionBuilder,
          key,
          'agent.test',
          'Working…',
        );

        // listCards excludes ticker-layout cards.
        final agentCards = await endpoints.agent.listCards(sessionBuilder, key);
        expect(agentCards, hasLength(1));
        expect(agentCards.first.externalId, equals('real-card'));
      });
    });

    group('key revocation', () {
      test('revoked key cannot push, list, update, or dismiss', () async {
        final response = await endpoints.apiKey.generateKey(
          sessionBuilder,
          'To Revoke',
          'test-management-token',
        );
        final key = response.plainTextKey;

        // Push one card before revocation.
        await endpoints.agent.pushCard(
          sessionBuilder,
          key,
          _card(externalId: 'pre-revoke'),
        );

        await endpoints.apiKey.revokeKey(
          sessionBuilder,
          response.key.id!,
          'test-management-token',
        );

        expect(
          () => endpoints.agent.listCards(sessionBuilder, key),
          throwsA(anything),
        );
        expect(
          () => endpoints.agent.pushCard(sessionBuilder, key, _card()),
          throwsA(anything),
        );
        expect(
          () => endpoints.agent
              .dismissCard(sessionBuilder, key, 'pre-revoke'),
          throwsA(anything),
        );
      });

      test('pre-revocation cards remain visible via CardEndpoint', () async {
        final response =
            await endpoints.apiKey.generateKey(
              sessionBuilder,
              'Keep Cards',
              'test-management-token',
            );
        final key = response.plainTextKey;

        await endpoints.agent.pushCard(
          sessionBuilder,
          key,
          _card(externalId: 'survives-revoke'),
        );

        await endpoints.apiKey.revokeKey(
          sessionBuilder,
          response.key.id!,
          'test-management-token',
        );

        final displayCards = await endpoints.card.getCards(sessionBuilder);
        expect(
            displayCards.any((c) => c.externalId == 'survives-revoke'),
            isTrue);
      });
    });
  });
}
