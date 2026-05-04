import 'package:landfall_shared/landfall_shared.dart';
import 'package:test/test.dart';

ProfileInfo _base() => ProfileInfo(
      id: 1,
      name: 'Weekday',
      slug: 'weekday',
      isActive: true,
      layout: DashboardLayout.weekdayLayout(),
      sortOrder: 0,
    );

void main() {
  group('ProfileInfo', () {
    group('companionThemeSlug', () {
      test('defaults to null when not provided', () {
        expect(_base().companionThemeSlug, isNull);
      });

      test('is set when provided', () {
        final p = ProfileInfo(
          id: 1,
          name: 'Gaming',
          slug: 'gaming',
          isActive: false,
          layout: DashboardLayout.weekdayLayout(),
          sortOrder: 1,
          companionThemeSlug: 'neon-arcade',
        );
        expect(p.companionThemeSlug, equals('neon-arcade'));
      });
    });

    group('copyWith', () {
      test('copies companionThemeSlug when provided', () {
        final p = _base().copyWith(companionThemeSlug: 'deep-blue');
        expect(p.companionThemeSlug, equals('deep-blue'));
        expect(p.name, equals('Weekday'));
      });

      test('preserves existing companionThemeSlug when not provided', () {
        final base = _base().copyWith(companionThemeSlug: 'aurora-borealis');
        final copy = base.copyWith(name: 'Updated');
        expect(copy.companionThemeSlug, equals('aurora-borealis'));
        expect(copy.name, equals('Updated'));
      });

      test('can clear companionThemeSlug to null', () {
        final base = _base().copyWith(companionThemeSlug: 'some-theme');
        final copy = base.copyWith(companionThemeSlug: null);
        expect(copy.companionThemeSlug, isNull);
      });
    });

    group('equality', () {
      test('profiles with same companionThemeSlug are equal', () {
        final a = _base().copyWith(companionThemeSlug: 'neon-arcade');
        final b = _base().copyWith(companionThemeSlug: 'neon-arcade');
        expect(a, equals(b));
      });

      test('profiles with different companionThemeSlug are not equal', () {
        final a = _base().copyWith(companionThemeSlug: 'neon-arcade');
        final b = _base().copyWith(companionThemeSlug: 'deep-blue');
        expect(a, isNot(equals(b)));
      });

      test('profile with companionThemeSlug differs from one without', () {
        final a = _base().copyWith(companionThemeSlug: 'neon-arcade');
        final b = _base();
        expect(a, isNot(equals(b)));
      });
    });
  });
}
