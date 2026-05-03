import 'package:test/test.dart';

import 'package:landfall_server/src/generated/protocol.dart';
import 'package:landfall_server/src/license/stripe_purchase_service.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given StripePurchaseService — theme purchase',
    (sessionBuilder, endpoints) {
      late LandfallTheme paidTheme;
      const buyerUserId = 'stripe-theme-test-user';

      setUp(() async {
        final session = sessionBuilder.build();
        paidTheme = await LandfallTheme.db.insertRow(
          session,
          LandfallTheme(
            slug: 'webhook-test-theme',
            name: 'Webhook Test Theme',
            schemaVersion: '1.0',
            tokensJson: '{}',
            resolvedJson: '{"color.accent":"#123456"}',
            isBuiltIn: false,
            isMarketplace: true,
            priceUsd: 499,
            stripeProductId: 'prod_webhook_test',
            createdAt: DateTime.now().toUtc(),
          ),
        );
      });

      Map<String, dynamic> event0(Map<String, dynamic> metadata,
              {String? email, String? sessionId}) =>
          {
            'type': 'checkout.session.completed',
            'data': {
              'object': {
                'id': sessionId ?? 'cs_test_${DateTime.now().microsecondsSinceEpoch}',
                'customer_email': email,
                'metadata': metadata,
              },
            },
          };

      test('creates ThemePurchase record for theme purchase', () async {
        final session = sessionBuilder.build();
        await StripePurchaseService.handleCheckoutCompleted(
          session,
          event0(
            {
              'purchase_type': 'theme',
              'theme_id': '${paidTheme.id}',
              'user_id': buyerUserId,
            },
            email: 'buyer@example.com',
            sessionId: 'cs_theme_test_001',
          ),
        );

        final purchases = await ThemePurchase.db.find(
          session,
          where: (t) => t.userId.equals(buyerUserId),
        );
        expect(purchases, hasLength(1));
        expect(purchases.first.themeId, equals(paidTheme.id));
        expect(purchases.first.stripePaymentIntentId, equals('cs_theme_test_001'));
      });

      test('duplicate call with same session id does not insert duplicate',
          () async {
        final session = sessionBuilder.build();
        const csId = 'cs_theme_idempotent_001';
        final event = event0(
          {
            'purchase_type': 'theme',
            'theme_id': '${paidTheme.id}',
            'user_id': buyerUserId,
          },
          sessionId: csId,
        );

        await StripePurchaseService.handleCheckoutCompleted(session, event);
        await StripePurchaseService.handleCheckoutCompleted(session, event);

        final purchases = await ThemePurchase.db.find(
          session,
          where: (t) =>
              t.userId.equals(buyerUserId) & t.themeId.equals(paidTheme.id!),
        );
        expect(purchases, hasLength(1));
      });

      test('missing theme_id silently ignored — no purchase created', () async {
        final session = sessionBuilder.build();
        await StripePurchaseService.handleCheckoutCompleted(
          session,
          event0({'purchase_type': 'theme', 'user_id': buyerUserId}),
        );

        final purchases = await ThemePurchase.db.find(
          session,
          where: (t) => t.userId.equals(buyerUserId),
        );
        expect(purchases, isEmpty);
      });

      test('missing user_id silently ignored — no purchase created', () async {
        final session = sessionBuilder.build();
        await StripePurchaseService.handleCheckoutCompleted(
          session,
          event0({'purchase_type': 'theme', 'theme_id': '${paidTheme.id}'}),
        );

        final purchases = await ThemePurchase.db.find(session);
        expect(purchases, isEmpty);
      });

      test('unknown purchase_type does not throw', () async {
        final session = sessionBuilder.build();
        // Should complete without error.
        await StripePurchaseService.handleCheckoutCompleted(
          session,
          event0({'purchase_type': 'unknown_type'}),
        );
      });

      test('existing license purchase still creates LicenseKey', () async {
        final session = sessionBuilder.build();
        await StripePurchaseService.handleCheckoutCompleted(
          session,
          event0(
            {'purchase_type': 'license', 'tier': 'pro'},
            email: 'licensee@example.com',
          ),
        );

        final keys = await LicenseKey.db.find(
          session,
          where: (t) => t.buyerEmail.equals('licensee@example.com'),
        );
        expect(keys, hasLength(1));
        expect(keys.first.tier, equals('pro'));
      });
    },
  );
}
