import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Handles Stripe webhook events at POST `/stripe/webhook`.
///
/// Verifies the `Stripe-Signature` header using HMAC-SHA256 before processing.
/// The webhook secret must be set in `passwords.yaml` as:
///   `stripeWebhookSecret: '<secret>'`
///
/// Supported events:
///   - `checkout.session.completed` → issues a license key or grants a pack
///
/// Stripe metadata conventions:
///   license purchase: `{ purchase_type: "license", tier: "pro"|"founding_member" }`
///   pack purchase:    `{ purchase_type: "pack", pack_id: "<id>", user_id: "<uuid>" }`
class StripeWebhookRoute extends Route {
  StripeWebhookRoute() : super(methods: {Method.post});

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    final bodyString = await request.readAsString();
    final signature = (request.headers['stripe-signature'] as String?) ?? '';
    final secret = session.passwords['stripeWebhookSecret'] ?? '';

    if (secret.isNotEmpty && !_verifySignature(bodyString, signature, secret)) {
      return Response.badRequest(
        body: Body.fromString('Invalid Stripe signature'),
      );
    }

    final Map<String, dynamic> event;
    try {
      event = jsonDecode(bodyString) as Map<String, dynamic>;
    } catch (_) {
      return Response.badRequest(body: Body.fromString('Invalid JSON'));
    }

    final eventType = event['type'] as String?;
    if (eventType == 'checkout.session.completed') {
      await _handleCheckoutCompleted(session, event);
    }

    return Response.ok(body: Body.fromString('ok'));
  }

  Future<void> _handleCheckoutCompleted(
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

    if (purchaseType == 'license') {
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
    } else if (purchaseType == 'pack') {
      final packId = metadata['pack_id'] as String?;
      final userId = metadata['user_id'] as String?;
      if (packId != null && userId != null) {
        await OwnedPack.db.insertRow(
          session,
          OwnedPack(
            userId: userId,
            packId: packId,
            grantedAt: DateTime.now().toUtc(),
            stripeSessionId: sessionId,
          ),
        );
        session.log(
          'Pack granted: $packId to user $userId',
          level: LogLevel.info,
        );
      }
    }
  }

  String _generateLicenseKey(String tier) {
    final tierCode = tier == 'founding_member' ? 'FM' : 'PRO';
    final now = DateTime.now().microsecondsSinceEpoch;
    final hash = sha256.convert(utf8.encode('$now-$tierCode')).toString();
    final part1 = hash.substring(0, 4).toUpperCase();
    final part2 = hash.substring(4, 8).toUpperCase();
    return 'LF-$tierCode-$part1-$part2';
  }

  bool _verifySignature(String body, String signature, String secret) {
    String? timestamp;
    String? v1;
    for (final part in signature.split(',')) {
      if (part.startsWith('t=')) timestamp = part.substring(2);
      if (part.startsWith('v1=')) v1 = part.substring(3);
    }
    if (timestamp == null || v1 == null) return false;

    final payload = '$timestamp.$body';
    final expected = Hmac(sha256, utf8.encode(secret))
        .convert(utf8.encode(payload))
        .toString();
    return expected == v1;
  }
}
