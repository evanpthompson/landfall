import 'package:test/test.dart';

import 'package:landfall_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';

LayoutConfig _layout({
  int? id,
  String name = 'Test Layout',
  String presetType = 'custom',
  String cardsJson = '[]',
  bool isActive = false,
}) {
  return LayoutConfig(
    id: id,
    name: name,
    presetType: presetType,
    cardsJson: cardsJson,
    isActive: isActive,
    updatedAt: DateTime.now().toUtc(),
  );
}

void main() {
  withServerpod('Given LayoutEndpoint', (sessionBuilder, endpoints) {
    late TestSessionBuilder authed;

    setUp(() {
      authed = sessionBuilder.copyWith(
        authentication:
            AuthenticationOverride.authenticationInfo('user-1', {}),
      );
    });

    group('getLayouts', () {
      test('returns empty list when no layouts have been saved', () async {
        final layouts = await endpoints.layout.getLayouts(authed);
        expect(layouts, isEmpty);
      });

      test('returns all saved layouts', () async {
        await endpoints.layout.saveLayout(authed, _layout(name: 'A'));
        await endpoints.layout.saveLayout(authed, _layout(name: 'B'));

        final layouts = await endpoints.layout.getLayouts(authed);
        expect(layouts, hasLength(2));
      });

      test('returned layouts have assigned ids', () async {
        await endpoints.layout.saveLayout(authed, _layout());
        final layouts = await endpoints.layout.getLayouts(authed);
        expect(layouts.first.id, isNotNull);
      });
    });

    group('saveLayout (insert)', () {
      test('creates a new row and returns it with an assigned id', () async {
        final saved = await endpoints.layout.saveLayout(
          authed,
          _layout(name: 'New Layout'),
        );

        expect(saved.id, isNotNull);
        expect(saved.name, equals('New Layout'));
      });

      test('sets updatedAt on insert', () async {
        final before =
            DateTime.now().toUtc().subtract(const Duration(seconds: 1));
        final saved = await endpoints.layout.saveLayout(authed, _layout());
        expect(saved.updatedAt.isAfter(before), isTrue);
      });

      test('preserves cardsJson content', () async {
        const cards = '[{"id":"slot_clock","source":"system.clock"}]';
        final saved = await endpoints.layout.saveLayout(
          authed,
          _layout(cardsJson: cards),
        );
        expect(saved.cardsJson, equals(cards));
      });

      test('preserves preset type', () async {
        final saved = await endpoints.layout.saveLayout(
          authed,
          _layout(presetType: 'weekday'),
        );
        expect(saved.presetType, equals('weekday'));
      });

      test('two inserts produce two distinct rows', () async {
        final a = await endpoints.layout.saveLayout(authed, _layout(name: 'Alpha'));
        final b = await endpoints.layout.saveLayout(authed, _layout(name: 'Beta'));
        expect(a.id, isNot(equals(b.id)));
        expect(
          await endpoints.layout.getLayouts(authed),
          hasLength(2),
        );
      });
    });

    group('saveLayout (update)', () {
      test('updates name without creating a duplicate row', () async {
        final original =
            await endpoints.layout.saveLayout(authed, _layout(name: 'Before'));

        await endpoints.layout.saveLayout(
          authed,
          original.copyWith(name: 'After'),
        );

        final all = await endpoints.layout.getLayouts(authed);
        expect(all, hasLength(1));
        expect(all.first.name, equals('After'));
        expect(all.first.id, equals(original.id));
      });

      test('updates cardsJson in-place', () async {
        final saved =
            await endpoints.layout.saveLayout(authed, _layout(cardsJson: '[]'));

        const updated = '[{"id":"slot_clock"}]';
        final result = await endpoints.layout.saveLayout(
          authed,
          saved.copyWith(cardsJson: updated),
        );

        expect(result.cardsJson, equals(updated));
        expect(result.id, equals(saved.id));
      });

      test('updates updatedAt timestamp on save', () async {
        final original = await endpoints.layout.saveLayout(authed, _layout());

        // Small delay so updatedAt will differ.
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final updated = await endpoints.layout.saveLayout(
          authed,
          original.copyWith(name: 'Updated'),
        );

        expect(updated.updatedAt.isAfter(original.updatedAt), isTrue);
      });
    });

    group('setActiveLayout', () {
      test('marks the target layout as active', () async {
        final layout =
            await endpoints.layout.saveLayout(authed, _layout(name: 'Activate Me'));

        final activated =
            await endpoints.layout.setActiveLayout(authed, layout.id!);

        expect(activated.isActive, isTrue);
        expect(activated.id, equals(layout.id));
      });

      test('active flag invariant: exactly one layout is active at a time',
          () async {
        final a = await endpoints.layout.saveLayout(authed, _layout(name: 'A'));
        final b = await endpoints.layout.saveLayout(authed, _layout(name: 'B'));
        final c = await endpoints.layout.saveLayout(authed, _layout(name: 'C'));

        await endpoints.layout.setActiveLayout(authed, a.id!);
        await endpoints.layout.setActiveLayout(authed, b.id!);
        await endpoints.layout.setActiveLayout(authed, c.id!);

        final all = await endpoints.layout.getLayouts(authed);
        final activeLayouts = all.where((l) => l.isActive).toList();
        expect(activeLayouts, hasLength(1));
        expect(activeLayouts.first.id, equals(c.id));
      });

      test('switching active clears previous active', () async {
        final a = await endpoints.layout.saveLayout(authed, _layout(name: 'A'));
        final b = await endpoints.layout.saveLayout(authed, _layout(name: 'B'));

        await endpoints.layout.setActiveLayout(authed, a.id!);
        await endpoints.layout.setActiveLayout(authed, b.id!);

        final all = await endpoints.layout.getLayouts(authed);
        final layoutA = all.firstWhere((l) => l.id == a.id);
        expect(layoutA.isActive, isFalse);
      });

      test('throws when layoutId does not exist', () async {
        expect(
          () => endpoints.layout.setActiveLayout(authed, 999999),
          throwsA(anything),
        );
      });
    });

    group('deleteLayout', () {
      test('deletes a non-active layout', () async {
        final layout =
            await endpoints.layout.saveLayout(authed, _layout(name: 'Delete Me'));

        await endpoints.layout.deleteLayout(authed, layout.id!);

        final all = await endpoints.layout.getLayouts(authed);
        expect(all.any((l) => l.id == layout.id), isFalse);
      });

      test('leaves other layouts intact after deletion', () async {
        final keep =
            await endpoints.layout.saveLayout(authed, _layout(name: 'Keep'));
        final remove =
            await endpoints.layout.saveLayout(authed, _layout(name: 'Remove'));

        await endpoints.layout.deleteLayout(authed, remove.id!);

        final all = await endpoints.layout.getLayouts(authed);
        expect(all, hasLength(1));
        expect(all.first.id, equals(keep.id));
      });

      test('throws when attempting to delete the active layout', () async {
        final layout =
            await endpoints.layout.saveLayout(authed, _layout(name: 'Active'));
        await endpoints.layout.setActiveLayout(authed, layout.id!);

        expect(
          () => endpoints.layout.deleteLayout(authed, layout.id!),
          throwsA(anything),
        );
      });

      test('is a no-op for an unknown id', () async {
        await endpoints.layout.saveLayout(authed, _layout());

        // Should not throw.
        await endpoints.layout.deleteLayout(authed, 999999);

        final all = await endpoints.layout.getLayouts(authed);
        expect(all, hasLength(1));
      });
    });
  });

  // SEC-02: LayoutEndpoint mutation auth guards.
  withServerpod('Given LayoutEndpoint auth guards', (sessionBuilder, endpoints) {
    final authed = sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo('user-1', {}),
    );

    test('saveLayout rejects unauthenticated caller', () async {
      expect(
        () => endpoints.layout.saveLayout(sessionBuilder, _layout()),
        throwsA(isA<Exception>()),
      );
    });

    test('setActiveLayout rejects unauthenticated caller', () async {
      final saved = await endpoints.layout.saveLayout(authed, _layout());
      expect(
        () => endpoints.layout.setActiveLayout(sessionBuilder, saved.id!),
        throwsA(isA<Exception>()),
      );
    });

    test('deleteLayout rejects unauthenticated caller', () async {
      final saved = await endpoints.layout.saveLayout(authed, _layout());
      expect(
        () => endpoints.layout.deleteLayout(sessionBuilder, saved.id!),
        throwsA(isA<Exception>()),
      );
    });

    test('getLayouts rejects unauthenticated caller', () async {
      expect(
        () => endpoints.layout.getLayouts(sessionBuilder),
        throwsA(isA<Exception>()),
      );
    });

    test('authenticated caller can save, activate, and delete (regression)',
        () async {
      final saved =
          await endpoints.layout.saveLayout(authed, _layout(name: 'R'));
      expect(saved.id, isNotNull);
      final activated =
          await endpoints.layout.setActiveLayout(authed, saved.id!);
      expect(activated.isActive, isTrue);
    });
  });
}
