import 'dart:convert';
import 'package:crypto/crypto.dart';

/// HMAC-SHA256 signed URL tokens for unauthenticated photo serving.
///
/// The token encodes the photo ID and expiry epoch so the route can verify
/// the token without a database lookup. Only the server that holds the signing
/// secret can generate or verify tokens.
///
/// URL format: `/photos/{id}?token=<base64url_hmac>&exp=<epoch_seconds>`
class PhotoSigningService {
  static const tokenLifetime = Duration(minutes: 5);

  const PhotoSigningService(this._secret);

  final String _secret;

  /// Returns a (token, exp) pair for [photoId] valid for [tokenLifetime].
  ({String token, int exp}) sign(int photoId) {
    final exp =
        DateTime.now().toUtc().add(tokenLifetime).millisecondsSinceEpoch ~/
        1000;
    return (token: signStatic(photoId: photoId, expEpoch: exp, secret: _secret), exp: exp);
  }

  /// Returns true if [token] is a valid, unexpired HMAC for [photoId] at [exp].
  bool verify(int photoId, String token, int exp) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    if (now > exp) return false;
    return token == signStatic(photoId: photoId, expEpoch: exp, secret: _secret);
  }

  /// Computes an HMAC token for [photoId]:[expEpoch] using [secret].
  /// Exposed so tests can pre-compute tokens with known parameters.
  static String signStatic({
    required int photoId,
    required int expEpoch,
    required String secret,
  }) {
    final message = '$photoId:$expEpoch';
    final hmac = Hmac(sha256, utf8.encode(secret));
    return base64Url.encode(hmac.convert(utf8.encode(message)).bytes);
  }
}
