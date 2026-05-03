import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Business logic for Stripe webhook purchase recording.
///
/// Extracted from [StripeWebhookRoute] so that integration tests can call
/// [handleCheckoutCompleted] directly via a [Session] without needing to
/// simulate HTTP.
class StripePurchaseService {
  const StripePurchaseService._();

  static Future<void> handleCheckoutCompleted(
    Session session,
    Map<String, dynamic> event,
  ) async {
    final obj = event['data']?['object'] as Map<String, dynamic>? ?? {};
    final metadata = obj['metadata'] as Map<String, dynamic>? ?? {};
    final sessionId = obj['id'] as String? ?? '';
    final customerEmail =
        (obj['customer_details']?['email'] as String?) ??
            (obj['customer_email'] as String?);

    final purchaseType = metadata['purchase_type'] as String?;

    switch (purchaseType) {
      case 'license':
        await _handleLicense(session, metadata, sessionId, customerEmail);
      case 'pack':
        await _handlePack(session, metadata, sessionId);
      case 'theme':
        await _handleTheme(session, metadata, sessionId);
    }
  }

  static Future<void> _handleLicense(
    Session session,
    Map<String, dynamic> metadata,
    String sessionId,
    String? customerEmail,
  ) async {
    final tier = metadata['tier'] as String? ?? 'pro';
    final key = _generateLicenseKey(tier);
    await LicenseKey.db.insertRow(
      session,
      LicenseKey(
        key: key,
        tier: tier,
        purchasedAt: DateTime.now().toUtc(),
        stripeSessionId: sessionId,
        buyerEmail: customerEmail,
      ),
    );
    session.log(
      'License key issued: $key for $customerEmail (tier: $tier)',
      level: LogLevel.info,
    );
  }

  static Future<void> _handlePack(
    Session session,
    Map<String, dynamic> metadata,
    String sessionId,
  ) async {
    final packId = metadata['pack_id'] as String?;
    final userId = metadata['user_id'] as String?;
    if (packId == null || userId == null) return;

    await OwnedPack.db.insertRow(
      session,
      OwnedPack(
        userId: userId,
        packId: packId,
        grantedAt: DateTime.now().toUtc(),
        stripeSessionId: sessionId,
      ),
    );
    session.log('Pack granted: $packId to user $userId', level: LogLevel.info);
  }

  static Future<void> _handleTheme(
    Session session,
    Map<String, dynamic> metadata,
    String sessionId,
  ) async {
    final themeIdStr = metadata['theme_id'] as String?;
    final userId = metadata['user_id'] as String?;
    if (themeIdStr == null || userId == null) return;

    final themeId = int.tryParse(themeIdStr);
    if (themeId == null) return;

    // Idempotency: skip if already recorded for this user+theme.
    final existing = await ThemePurchase.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId) & t.themeId.equals(themeId),
    );
    if (existing != null) return;

    await ThemePurchase.db.insertRow(
      session,
      ThemePurchase(
        userId: userId,
        themeId: themeId,
        purchasedAt: DateTime.now().toUtc(),
        stripePaymentIntentId: sessionId.isEmpty ? null : sessionId,
      ),
    );
    session.log(
      'Theme purchased: themeId=$themeId by user=$userId',
      level: LogLevel.info,
    );
  }

  static String _generateLicenseKey(String tier) {
    final tierCode = tier == 'founding_member' ? 'FM' : 'PRO';
    final now = DateTime.now().microsecondsSinceEpoch;
    final hash = sha256.convert(utf8.encode('$now-$tierCode')).toString();
    final part1 = hash.substring(0, 4).toUpperCase();
    final part2 = hash.substring(4, 8).toUpperCase();
    return 'LF-$tierCode-$part1-$part2';
  }
}
