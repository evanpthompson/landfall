import 'package:test/test.dart';

import 'package:landfall_server/src/companion/companion_endpoint.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given CompanionEndpoint', (sessionBuilder, endpoints) {
    setUp(CompanionEndpoint.resetForTests);

    group('getOrCreateForDisplay', () {
      test('creates a new entity on first call', () async {
        final entity = await endpoints.companion
            .getOrCreateForDisplay(sessionBuilder, 'display-1');

        expect(entity.displayId, equals('display-1'));
        expect(entity.speciesId, equals('lumen'));
        expect(entity.name, equals('Lumen'));
        expect(entity.rarityTier, equals('uncommon'));
        expect(entity.evolutionStage, equals(0));
      });

      test('returns same entity on subsequent calls (idempotent)', () async {
        final first = await endpoints.companion
            .getOrCreateForDisplay(sessionBuilder, 'display-2');
        final second = await endpoints.companion
            .getOrCreateForDisplay(sessionBuilder, 'display-2');

        expect(second.id, equals(first.id));
        expect(second.createdAt, equals(first.createdAt));
      });

      test('different displayIds get different entities', () async {
        final a = await endpoints.companion
            .getOrCreateForDisplay(sessionBuilder, 'display-a');
        final b = await endpoints.companion
            .getOrCreateForDisplay(sessionBuilder, 'display-b');

        expect(a.id, isNot(equals(b.id)));
        expect(a.displayId, equals('display-a'));
        expect(b.displayId, equals('display-b'));
      });
    });

    group('pollForEvents + pushAction', () {
      test('pushAction immediately resolves a waiting pollForEvents',
          () async {
        // Start polling in the background.
        final pollFuture = endpoints.companion
            .pollForEvents(sessionBuilder, 'display-p1', timeoutSeconds: 5);

        // Give the poll a moment to register its waiter.
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Phone pushes an action.
        await endpoints.companion
            .pushAction(sessionBuilder, 'display-p1', 'pet');

        final action = await pollFuture;
        expect(action, isNotNull);
        expect(action!.kind, equals('pet'));
      });

      test('returns null on timeout when no action arrives', () async {
        final action = await endpoints.companion
            .pollForEvents(sessionBuilder, 'display-p2', timeoutSeconds: 1);
        expect(action, isNull);
      });

      test('queued action is drained on next poll', () async {
        // Push before any poll exists — action queues.
        await endpoints.companion
            .pushAction(sessionBuilder, 'display-p3', 'play');

        // Poll picks it up immediately.
        final action = await endpoints.companion
            .pollForEvents(sessionBuilder, 'display-p3', timeoutSeconds: 5);

        expect(action, isNotNull);
        expect(action!.kind, equals('play'));
      });

      test('only the oldest waiter receives a single pushed action',
          () async {
        final pollA = endpoints.companion
            .pollForEvents(sessionBuilder, 'display-p4', timeoutSeconds: 5);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final pollB = endpoints.companion
            .pollForEvents(sessionBuilder, 'display-p4', timeoutSeconds: 2);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        await endpoints.companion
            .pushAction(sessionBuilder, 'display-p4', 'feed');

        final resultA = await pollA;
        final resultB = await pollB;

        expect(resultA, isNotNull);
        expect(resultA!.kind, equals('feed'));
        // Second waiter should time out with null.
        expect(resultB, isNull);
      });

      test('actions to different displays do not cross-pollinate', () async {
        final pollX = endpoints.companion
            .pollForEvents(sessionBuilder, 'display-x', timeoutSeconds: 2);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Push to a different display.
        await endpoints.companion
            .pushAction(sessionBuilder, 'display-y', 'pet');

        // X should time out — Y's action didn't leak.
        final result = await pollX;
        expect(result, isNull);
      });
    });
  });
}
