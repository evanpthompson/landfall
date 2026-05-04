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

    test('seeds one companion profile per marketplace theme', () async {
      await MarketplaceSeeder.seed(session);

      final themes = await LandfallTheme.db.find(
        session,
        where: (t) => t.isMarketplace.equals(true),
      );
      final themeSlugs = themes.map((t) => t.slug).toSet();

      final profiles = await DashboardProfile.db.find(session);
      final profileThemeIds =
          profiles.map((p) => p.themeId).whereType<String>().toSet();

      // Every marketplace theme slug must appear as a profile's themeId.
      for (final slug in themeSlugs) {
        expect(profileThemeIds, contains(slug));
      }
    });

    test('companion profile seeding is idempotent', () async {
      await MarketplaceSeeder.seed(session);
      final countAfterFirst = (await DashboardProfile.db.find(session)).length;

      await MarketplaceSeeder.seed(session);
      final countAfterSecond = (await DashboardProfile.db.find(session)).length;

      expect(countAfterSecond, equals(countAfterFirst));
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
