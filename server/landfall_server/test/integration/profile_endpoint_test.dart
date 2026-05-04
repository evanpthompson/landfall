import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

TestSessionBuilder _authed(TestSessionBuilder base) => base.copyWith(
      authentication:
          AuthenticationOverride.authenticationInfo('user-1', {}),
    );

void main() {
  withServerpod('Given ProfileEndpoint', (sessionBuilder, endpoints) {
    final authed = _authed(sessionBuilder);

    group('createProfile', () {
      test('creates a new profile and returns it', () async {
        final profile =
            await endpoints.profile.createProfile(authed, 'Morning');
        expect(profile.id, isNotNull);
        expect(profile.name, equals('Morning'));
        expect(profile.isActive, isFalse);
      });

      test('generates a slug from the name', () async {
        final profile = await endpoints.profile
            .createProfile(authed, 'Weekend Mode');
        expect(profile.slug, equals('weekend-mode'));
      });

      test('disambiguates duplicate slugs with a numeric suffix', () async {
        final a = await endpoints.profile.createProfile(authed, 'Home');
        final b = await endpoints.profile.createProfile(authed, 'Home');
        expect(a.slug, equals('home'));
        expect(b.slug, equals('home-2'));
      });

      test('starts with empty cardsJson when none supplied', () async {
        final profile = await endpoints.profile.createProfile(authed, 'Empty');
        expect(profile.cardsJson, equals('[]'));
      });

      test('stores provided cardsJson', () async {
        const cards = '[{"id":"slot_clock","source":"system.clock"}]';
        final profile = await endpoints.profile
            .createProfile(authed, 'With Cards', cardsJson: cards);
        expect(profile.cardsJson, equals(cards));
      });
    });

    group('updateProfile', () {
      test('updates the name', () async {
        final created =
            await endpoints.profile.createProfile(authed, 'Before');
        final updated = await endpoints.profile.updateProfile(
          authed,
          created.id!,
          name: 'After',
        );
        expect(updated.name, equals('After'));
        expect(updated.id, equals(created.id));
      });

      test('does not create a duplicate row', () async {
        final created =
            await endpoints.profile.createProfile(authed, 'Solo');
        await endpoints.profile
            .updateProfile(authed, created.id!, name: 'Renamed');
        final all = await endpoints.profile.listProfiles(authed);
        expect(all, hasLength(1));
      });

      test('throws when profile id does not exist', () async {
        expect(
          () => endpoints.profile.updateProfile(authed, 999999, name: 'X'),
          throwsA(anything),
        );
      });
    });

    group('deleteProfile', () {
      test('removes the profile', () async {
        final p = await endpoints.profile.createProfile(authed, 'Temp');
        await endpoints.profile.createProfile(authed, 'Keep');

        await endpoints.profile.deleteProfile(authed, p.id!);

        final all = await endpoints.profile.listProfiles(authed);
        expect(all.any((x) => x.id == p.id), isFalse);
      });

      test('throws when trying to delete the active profile', () async {
        final p = await endpoints.profile.createProfile(authed, 'Active');
        await endpoints.profile.activateProfile(authed, p.id!);
        await endpoints.profile.createProfile(authed, 'Other');

        expect(
          () => endpoints.profile.deleteProfile(authed, p.id!),
          throwsA(anything),
        );
      });

      test('throws when it is the last profile', () async {
        final p = await endpoints.profile.createProfile(authed, 'Last');

        expect(
          () => endpoints.profile.deleteProfile(authed, p.id!),
          throwsA(anything),
        );
      });

      test('is a no-op for an unknown id', () async {
        await endpoints.profile.createProfile(authed, 'Exists');
        await endpoints.profile.deleteProfile(authed, 999999);
        final all = await endpoints.profile.listProfiles(authed);
        expect(all, hasLength(1));
      });
    });

    group('activateProfile', () {
      test('marks only the target profile as active', () async {
        final a = await endpoints.profile.createProfile(authed, 'A');
        final b = await endpoints.profile.createProfile(authed, 'B');
        final c = await endpoints.profile.createProfile(authed, 'C');

        await endpoints.profile.activateProfile(authed, a.id!);
        await endpoints.profile.activateProfile(authed, b.id!);
        await endpoints.profile.activateProfile(authed, c.id!);

        final all = await endpoints.profile.listProfiles(authed);
        final active = all.where((p) => p.isActive).toList();
        expect(active, hasLength(1));
        expect(active.first.id, equals(c.id));
      });

      test('throws when id does not exist', () async {
        expect(
          () => endpoints.profile.activateProfile(authed, 999999),
          throwsA(anything),
        );
      });
    });

    group('duplicateProfile', () {
      test('creates an inactive copy with a new name', () async {
        const cards = '[{"id":"slot_clock"}]';
        final source = await endpoints.profile
            .createProfile(authed, 'Original', cardsJson: cards);
        await endpoints.profile.activateProfile(authed, source.id!);

        final copy = await endpoints.profile
            .duplicateProfile(authed, source.id!, 'Copy');

        expect(copy.id, isNot(equals(source.id)));
        expect(copy.name, equals('Copy'));
        expect(copy.isActive, isFalse);
        expect(copy.cardsJson, equals(cards));
      });

      test('throws when source id does not exist', () async {
        expect(
          () => endpoints.profile.duplicateProfile(authed, 999999, 'Orphan'),
          throwsA(anything),
        );
      });
    });

    group('listProfiles', () {
      test('returns empty list when no profiles exist', () async {
        final all = await endpoints.profile.listProfiles(authed);
        expect(all, isEmpty);
      });

      test('returns profiles ordered by sortOrder', () async {
        final a = await endpoints.profile.createProfile(authed, 'First');
        final b = await endpoints.profile.createProfile(authed, 'Second');
        final all = await endpoints.profile.listProfiles(authed);
        expect(all.first.id, equals(a.id));
        expect(all.last.id, equals(b.id));
      });
    });
  });

  // SEC-02: ProfileEndpoint mutation auth guards.
  withServerpod('Given ProfileEndpoint auth guards', (
    sessionBuilder,
    endpoints,
  ) {
    final authed = _authed(sessionBuilder);

    test('createProfile rejects unauthenticated caller', () async {
      expect(
        () => endpoints.profile.createProfile(sessionBuilder, 'Test'),
        throwsA(isA<Exception>()),
      );
    });

    test('updateProfile rejects unauthenticated caller', () async {
      final p = await endpoints.profile.createProfile(authed, 'P');
      expect(
        () => endpoints.profile.updateProfile(sessionBuilder, p.id!, name: 'X'),
        throwsA(isA<Exception>()),
      );
    });

    test('deleteProfile rejects unauthenticated caller', () async {
      await endpoints.profile.createProfile(authed, 'A');
      final p = await endpoints.profile.createProfile(authed, 'B');
      expect(
        () => endpoints.profile.deleteProfile(sessionBuilder, p.id!),
        throwsA(isA<Exception>()),
      );
    });

    test('activateProfile rejects unauthenticated caller', () async {
      final p = await endpoints.profile.createProfile(authed, 'P');
      expect(
        () => endpoints.profile.activateProfile(sessionBuilder, p.id!),
        throwsA(isA<Exception>()),
      );
    });

    test('duplicateProfile rejects unauthenticated caller', () async {
      final p = await endpoints.profile.createProfile(authed, 'P');
      expect(
        () =>
            endpoints.profile.duplicateProfile(sessionBuilder, p.id!, 'Copy'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
