import 'package:test/test.dart';

import 'package:landfall_server/src/generated/protocol.dart';
import 'package:landfall_server/src/theme/marketplace_seeder.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given MarketplaceSeeder', (sessionBuilder, endpoints) {
    late dynamic session;

    setUp(() {
      session = sessionBuilder.build();
    });

    test('seeds exactly 5 free marketplace themes', () async {
      await MarketplaceSeeder.seed(session);

      final free = await LandfallTheme.db.find(
        session,
        where: (t) =>
            t.isMarketplace.equals(true) &
            t.priceUsd.equals(null),
      );
      expect(free.length, equals(5));
    });

    test('seeds exactly 3 paid marketplace themes', () async {
      await MarketplaceSeeder.seed(session);

      final paid = await LandfallTheme.db.find(
        session,
        where: (t) =>
            t.isMarketplace.equals(true) &
            t.priceUsd.notEquals(null),
      );
      expect(paid.length, equals(3));
    });

    test('paid themes have priceUsd and stripeProductId', () async {
      await MarketplaceSeeder.seed(session);

      final paid = await LandfallTheme.db.find(
        session,
        where: (t) =>
            t.isMarketplace.equals(true) &
            t.priceUsd.notEquals(null),
      );
      for (final theme in paid) {
        expect(theme.priceUsd, isNotNull);
        expect(theme.priceUsd, greaterThan(0));
        expect(theme.stripeProductId, isNotNull);
        expect(theme.stripeProductId, isNotEmpty);
      }
    });

    test('all seeded themes have valid resolvedJson', () async {
      await MarketplaceSeeder.seed(session);

      final themes = await LandfallTheme.db.find(
        session,
        where: (t) => t.isMarketplace.equals(true),
      );
      for (final theme in themes) {
        expect(theme.resolvedJson, isNotNull);
        expect(theme.resolvedJson, isNotEmpty);
        expect(theme.resolvedJson, contains('{'));
      }
    });

    test('seeding is idempotent — calling twice does not duplicate rows',
        () async {
      await MarketplaceSeeder.seed(session);
      await MarketplaceSeeder.seed(session);

      final all = await LandfallTheme.db.find(
        session,
        where: (t) => t.isMarketplace.equals(true),
      );
      expect(all.length, equals(8));
    });

    test('seed does not create any companion profiles', () async {
      await MarketplaceSeeder.seed(session);

      final profiles = await DashboardProfile.db.find(session);
      final companionProfiles =
          profiles.where((p) => p.slug.startsWith('companion-')).toList();

      expect(companionProfiles, isEmpty);
    });

    test('cleanupOrphanedCompanionProfiles removes empty companion profiles',
        () async {
      // Manually insert two orphaned companion profiles.
      await DashboardProfile.db.insertRow(
        session,
        DashboardProfile(
          name: 'Synthwave \'84',
          slug: 'companion-synthwave-84',
          themeId: 'synthwave-84',
          cardsJson: '[]',
          createdAt: DateTime.now().toUtc(),
          sortOrder: 100,
        ),
      );
      await DashboardProfile.db.insertRow(
        session,
        DashboardProfile(
          name: 'Colorful Pop',
          slug: 'companion-colorful-pop',
          themeId: 'colorful-pop',
          cardsJson: '[]',
          createdAt: DateTime.now().toUtc(),
          sortOrder: 110,
        ),
      );

      await MarketplaceSeeder.cleanupOrphanedCompanionProfiles(session);

      final remaining = await DashboardProfile.db.find(session);
      final companionProfiles =
          remaining.where((p) => p.slug.startsWith('companion-')).toList();
      expect(companionProfiles, isEmpty);
    });

    test(
        'cleanupOrphanedCompanionProfiles preserves companion profiles with cards',
        () async {
      await DashboardProfile.db.insertRow(
        session,
        DashboardProfile(
          name: 'My Synthwave',
          slug: 'companion-synthwave-84',
          themeId: 'synthwave-84',
          cardsJson: '[{"type":"clock"}]',
          createdAt: DateTime.now().toUtc(),
          sortOrder: 100,
        ),
      );

      await MarketplaceSeeder.cleanupOrphanedCompanionProfiles(session);

      final remaining = await DashboardProfile.db.find(session);
      expect(remaining.any((p) => p.slug == 'companion-synthwave-84'), isTrue);
    });

    test('seeded themes have author and description', () async {
      await MarketplaceSeeder.seed(session);

      final themes = await LandfallTheme.db.find(
        session,
        where: (t) => t.isMarketplace.equals(true),
      );
      for (final theme in themes) {
        expect(theme.author, isNotNull);
        expect(theme.description, isNotNull);
      }
    });
  });
}
