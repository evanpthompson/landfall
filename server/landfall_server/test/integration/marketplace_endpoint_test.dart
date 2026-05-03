import 'package:test/test.dart';

import 'package:landfall_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';

const _testUserId = 'marketplace-test-user-uuid';

TestSessionBuilder _authenticatedSession(TestSessionBuilder base) =>
    base.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(
        _testUserId,
        {},
      ),
    );

void main() {
  withServerpod('Given MarketplaceEndpoint', (sessionBuilder, endpoints) {
    final authed = _authenticatedSession(sessionBuilder);

    late LandfallTheme freeTheme;
    late LandfallTheme paidTheme;
    late LandfallTheme paidTheme2;
    late LandfallTheme builtInTheme;

    setUp(() async {
      final session = authed.build();

      freeTheme = await LandfallTheme.db.insertRow(
        session,
        LandfallTheme(
          slug: 'mkt-free-theme',
          name: 'Free Marketplace Theme',
          schemaVersion: '1.0',
          tokensJson: '{}',
          resolvedJson: '{"color.accent":"#FF0000"}',
          isBuiltIn: false,
          isMarketplace: true,
          priceUsd: 0,
          createdAt: DateTime.now().toUtc(),
        ),
      );

      paidTheme = await LandfallTheme.db.insertRow(
        session,
        LandfallTheme(
          slug: 'mkt-paid-theme',
          name: 'Paid Marketplace Theme',
          schemaVersion: '1.0',
          tokensJson: '{}',
          resolvedJson: '{"color.accent":"#00FF00"}',
          isBuiltIn: false,
          isMarketplace: true,
          priceUsd: 499,
          stripeProductId: 'prod_test_123',
          createdAt: DateTime.now().toUtc(),
        ),
      );

      paidTheme2 = await LandfallTheme.db.insertRow(
        session,
        LandfallTheme(
          slug: 'mkt-paid-theme-2',
          name: 'Second Paid Theme',
          schemaVersion: '1.0',
          tokensJson: '{}',
          resolvedJson: '{"color.accent":"#0000FF"}',
          isBuiltIn: false,
          isMarketplace: true,
          priceUsd: 999,
          stripeProductId: 'prod_test_456',
          createdAt: DateTime.now().toUtc(),
        ),
      );

      // A non-marketplace theme — should never appear in marketplace results.
      builtInTheme = await LandfallTheme.db.insertRow(
        session,
        LandfallTheme(
          slug: 'mkt-builtin-theme',
          name: 'Non-Marketplace Theme',
          schemaVersion: '1.0',
          tokensJson: '{}',
          resolvedJson: '{"color.accent":"#FFFFFF"}',
          isBuiltIn: true,
          isMarketplace: false,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    });

    // ── listMarketplaceThemes ─────────────────────────────────────────────────

    group('listMarketplaceThemes', () {
      test('returns only isMarketplace=true themes', () async {
        final themes =
            await endpoints.marketplace.listMarketplaceThemes(authed);
        final slugs = themes.map((t) => t.slug).toSet();
        expect(slugs, containsAll([freeTheme.slug, paidTheme.slug]));
        expect(slugs, isNot(contains(builtInTheme.slug)));
      });

      test('includes free (priceUsd=0) and paid themes', () async {
        final themes =
            await endpoints.marketplace.listMarketplaceThemes(authed);
        expect(themes.any((t) => t.priceUsd == 0), isTrue);
        expect(themes.any((t) => (t.priceUsd ?? 0) > 0), isTrue);
      });

      test('all themes have non-empty slug and name', () async {
        final themes =
            await endpoints.marketplace.listMarketplaceThemes(authed);
        for (final t in themes) {
          expect(t.slug, isNotEmpty);
          expect(t.name, isNotEmpty);
        }
      });

      test('isOwned defaults to false for authenticated user with no purchases',
          () async {
        final themes =
            await endpoints.marketplace.listMarketplaceThemes(authed);
        expect(themes.every((t) => t.isOwned == false), isTrue);
      });

      test('isOwned is false for unauthenticated session', () async {
        final themes =
            await endpoints.marketplace.listMarketplaceThemes(sessionBuilder);
        expect(themes.every((t) => t.isOwned == false), isTrue);
      });

      test('marks owned theme as isOwned=true when purchase exists', () async {
        final session = authed.build();
        await ThemePurchase.db.insertRow(
          session,
          ThemePurchase(
            userId: _testUserId,
            themeId: paidTheme.id!,
            purchasedAt: DateTime.now().toUtc(),
          ),
        );

        final themes =
            await endpoints.marketplace.listMarketplaceThemes(authed);
        final paid = themes.firstWhere((t) => t.slug == paidTheme.slug);
        final free = themes.firstWhere((t) => t.slug == freeTheme.slug);

        expect(paid.isOwned, isTrue);
        expect(free.isOwned, isFalse);
      });

      test('does not mark other user purchases as owned', () async {
        final session = authed.build();
        await ThemePurchase.db.insertRow(
          session,
          ThemePurchase(
            userId: 'other-user-uuid',
            themeId: paidTheme.id!,
            purchasedAt: DateTime.now().toUtc(),
          ),
        );

        final themes =
            await endpoints.marketplace.listMarketplaceThemes(authed);
        final paid = themes.firstWhere((t) => t.slug == paidTheme.slug);
        expect(paid.isOwned, isFalse);
      });
    });

    // ── getMarketplaceTheme ───────────────────────────────────────────────────

    group('getMarketplaceTheme', () {
      test('returns theme info for a valid marketplace theme id', () async {
        final info = await endpoints.marketplace.getMarketplaceTheme(
          authed,
          paidTheme.id!,
        );
        expect(info.slug, equals(paidTheme.slug));
        expect(info.name, equals(paidTheme.name));
        expect(info.priceUsd, equals(499));
        expect(info.stripeProductId, equals('prod_test_123'));
      });

      test('isOwned is false when theme not purchased', () async {
        final info = await endpoints.marketplace.getMarketplaceTheme(
          authed,
          paidTheme.id!,
        );
        expect(info.isOwned, isFalse);
      });

      test('isOwned is true when theme is purchased by caller', () async {
        final session = authed.build();
        await ThemePurchase.db.insertRow(
          session,
          ThemePurchase(
            userId: _testUserId,
            themeId: paidTheme.id!,
            purchasedAt: DateTime.now().toUtc(),
          ),
        );

        final info = await endpoints.marketplace.getMarketplaceTheme(
          authed,
          paidTheme.id!,
        );
        expect(info.isOwned, isTrue);
      });

      test('throws NotFoundException for unknown id', () async {
        expect(
          () => endpoints.marketplace.getMarketplaceTheme(authed, 999999),
          throwsA(anything),
        );
      });

      test('throws NotFoundException for non-marketplace theme id', () async {
        expect(
          () => endpoints.marketplace
              .getMarketplaceTheme(authed, builtInTheme.id!),
          throwsA(anything),
        );
      });
    });

    // ── getOwnedThemes ────────────────────────────────────────────────────────

    group('getOwnedThemes', () {
      test('returns empty list when user has no purchases', () async {
        final owned = await endpoints.marketplace.getOwnedThemes(authed);
        expect(owned, isEmpty);
      });

      test('returns empty list for unauthenticated session', () async {
        final owned =
            await endpoints.marketplace.getOwnedThemes(sessionBuilder);
        expect(owned, isEmpty);
      });

      test('returns owned theme after ThemePurchase inserted', () async {
        final session = authed.build();
        await ThemePurchase.db.insertRow(
          session,
          ThemePurchase(
            userId: _testUserId,
            themeId: paidTheme.id!,
            purchasedAt: DateTime.now().toUtc(),
          ),
        );

        final owned = await endpoints.marketplace.getOwnedThemes(authed);
        expect(owned, hasLength(1));
        expect(owned.first.slug, equals(paidTheme.slug));
        expect(owned.first.isOwned, isTrue);
      });

      test('returns multiple owned themes', () async {
        final session = authed.build();
        await ThemePurchase.db.insertRow(
          session,
          ThemePurchase(
            userId: _testUserId,
            themeId: paidTheme.id!,
            purchasedAt: DateTime.now().toUtc(),
          ),
        );
        await ThemePurchase.db.insertRow(
          session,
          ThemePurchase(
            userId: _testUserId,
            themeId: paidTheme2.id!,
            purchasedAt: DateTime.now().toUtc(),
          ),
        );

        final owned = await endpoints.marketplace.getOwnedThemes(authed);
        expect(owned, hasLength(2));
        expect(owned.every((t) => t.isOwned), isTrue);
      });

      test('does not include other users purchases', () async {
        final session = authed.build();
        await ThemePurchase.db.insertRow(
          session,
          ThemePurchase(
            userId: 'other-user-uuid',
            themeId: paidTheme.id!,
            purchasedAt: DateTime.now().toUtc(),
          ),
        );

        final owned = await endpoints.marketplace.getOwnedThemes(authed);
        expect(owned, isEmpty);
      });
    });
  });
}
