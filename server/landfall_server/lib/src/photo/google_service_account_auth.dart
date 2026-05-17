import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pointycastle/asn1.dart' as asn1;
import 'package:pointycastle/export.dart' as pc;

import 'google_access_token_provider.dart';

/// Mints OAuth 2.0 access tokens for a Google service account using a
/// self-signed JWT (the "JWT-bearer" grant type).
///
/// See [§27 in `~/files/automation/landfall/architecture_decisions.md`] for
/// the rationale behind preferring service accounts over user OAuth for
/// server-to-server Drive access.
///
/// Usage:
/// ```dart
/// final auth = GoogleServiceAccountAuth(
///   clientEmail: passwords['googleServiceAccountEmail']!,
///   privateKeyPem: passwords['googleServiceAccountPrivateKey']!,
///   scopes: ['https://www.googleapis.com/auth/drive.readonly'],
/// );
/// final token = await auth.getAccessToken();
/// ```
///
/// The token is cached in memory until it is within [_refreshSkew] of
/// expiry, so callers can invoke [getAccessToken] without worrying about
/// rate limits.
class GoogleServiceAccountAuth implements GoogleAccessTokenProvider {
  GoogleServiceAccountAuth({
    required this.clientEmail,
    required this.privateKeyPem,
    required this.scopes,
    http.Client? httpClient,
    DateTime Function()? clock,
  })  : _http = httpClient ?? http.Client(),
        _clock = clock ?? DateTime.now {
    if (clientEmail.isEmpty) {
      throw ArgumentError.value(
          clientEmail, 'clientEmail', 'must not be empty');
    }
    if (privateKeyPem.isEmpty) {
      throw ArgumentError.value(
          privateKeyPem, 'privateKeyPem', 'must not be empty');
    }
    if (scopes.isEmpty) {
      throw ArgumentError.value(scopes, 'scopes', 'must not be empty');
    }
    // Parse eagerly so a malformed key fails at construction, not on first
    // use under load.
    _privateKey = _parsePkcs8PrivateKey(privateKeyPem);
  }

  /// `client_email` from the service account JSON.
  final String clientEmail;

  /// PEM-encoded PKCS#8 private key. The PEM body Google ships in the JSON
  /// key file is exactly this format, with `\n` between lines.
  final String privateKeyPem;

  /// OAuth scopes to request. At least one required.
  final List<String> scopes;

  final http.Client _http;
  final DateTime Function() _clock;
  late final pc.RSAPrivateKey _privateKey;
  _CachedToken? _cached;

  /// Refresh tokens this far before they actually expire. Avoids using a
  /// token that's about to expire mid-request.
  static const _refreshSkew = Duration(minutes: 5);

  /// JWT lifetime. Google permits up to 1 hour.
  static const _jwtLifetime = Duration(hours: 1);

  static final _tokenEndpoint = Uri.parse('https://oauth2.googleapis.com/token');

  /// Returns a fresh access token, minting one if the cached value is absent
  /// or within [_refreshSkew] of expiry.
  @override
  Future<String> getAccessToken() async {
    final now = _clock().toUtc();
    final cached = _cached;
    if (cached != null && cached.expiresAt.isAfter(now.add(_refreshSkew))) {
      return cached.token;
    }

    final assertion = _signAssertion(now);
    final response = await _http.post(
      _tokenEndpoint,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': assertion,
      },
    );
    if (response.statusCode != 200) {
      throw StateError(
        'Google service account token exchange failed '
        '(${response.statusCode}): ${response.body}',
      );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final token = json['access_token'] as String;
    final expiresIn = (json['expires_in'] as num).toInt();
    _cached = _CachedToken(
      token: token,
      expiresAt: now.add(Duration(seconds: expiresIn)),
    );
    return token;
  }

  /// Builds the signed assertion JWT.
  String _signAssertion(DateTime now) {
    final header = _b64UrlEncode(utf8.encode(
      jsonEncode({'alg': 'RS256', 'typ': 'JWT'}),
    ));
    final issuedAtSeconds = now.millisecondsSinceEpoch ~/ 1000;
    final expiresAtSeconds =
        now.add(_jwtLifetime).millisecondsSinceEpoch ~/ 1000;
    final claims = _b64UrlEncode(utf8.encode(jsonEncode({
      'iss': clientEmail,
      'scope': scopes.join(' '),
      'aud': _tokenEndpoint.toString(),
      'iat': issuedAtSeconds,
      'exp': expiresAtSeconds,
    })));
    final signingInput = '$header.$claims';
    final signature = _rs256Sign(utf8.encode(signingInput), _privateKey);
    return '$signingInput.${_b64UrlEncode(signature)}';
  }
}

class _CachedToken {
  _CachedToken({required this.token, required this.expiresAt});
  final String token;
  final DateTime expiresAt;
}

// ── RSA / PEM helpers ────────────────────────────────────────────────────────

Uint8List _rs256Sign(List<int> input, pc.RSAPrivateKey key) {
  // OID 0609608648016503040201 = id-sha256 (RFC 3447); pointycastle uses it
  // as the digest-algorithm identifier embedded in PKCS#1 v1.5 signatures.
  final signer = pc.RSASigner(pc.SHA256Digest(), '0609608648016503040201')
    ..init(true, pc.PrivateKeyParameter<pc.RSAPrivateKey>(key));
  final sig = signer.generateSignature(Uint8List.fromList(input));
  return sig.bytes;
}

String _b64UrlEncode(List<int> bytes) {
  // JWT base64url uses no padding.
  return base64Url.encode(bytes).replaceAll('=', '');
}

/// Parses a PEM-encoded PKCS#8 RSA private key.
///
/// Google service account JSON ships keys in this exact format. PKCS#1
/// (`-----BEGIN RSA PRIVATE KEY-----`) is rejected with a helpful message
/// because it indicates the user pasted the wrong field.
pc.RSAPrivateKey _parsePkcs8PrivateKey(String pem) {
  if (pem.contains('BEGIN RSA PRIVATE KEY')) {
    throw const FormatException(
      'Service account private key must be PKCS#8 '
      '("-----BEGIN PRIVATE KEY-----"). The PKCS#1 form '
      '("-----BEGIN RSA PRIVATE KEY-----") suggests the wrong field was '
      'pasted — Google service account JSON contains the PKCS#8 form in '
      'the "private_key" field.',
    );
  }
  if (!pem.contains('BEGIN PRIVATE KEY')) {
    throw const FormatException(
      'Service account private key is not a PEM-encoded PKCS#8 key '
      '(expected "-----BEGIN PRIVATE KEY-----" header).',
    );
  }

  final body = pem
      .replaceAll('-----BEGIN PRIVATE KEY-----', '')
      .replaceAll('-----END PRIVATE KEY-----', '')
      .replaceAll(RegExp(r'\s+'), '');

  final Uint8List der;
  try {
    der = base64.decode(body);
  } catch (e) {
    throw FormatException('PKCS#8 key body is not valid base64: $e');
  }

  try {
    // PKCS#8 PrivateKeyInfo:
    //   SEQUENCE {
    //     version           INTEGER,
    //     algorithm         AlgorithmIdentifier,
    //     privateKey        OCTET STRING -- contains a PKCS#1 RSAPrivateKey
    //   }
    final topLevel = asn1.ASN1Parser(der).nextObject() as asn1.ASN1Sequence;
    final privateKeyOctet = topLevel.elements![2] as asn1.ASN1OctetString;

    // PKCS#1 RSAPrivateKey:
    //   SEQUENCE { version, n, e, d, p, q, dP, dQ, qInv }
    final inner = asn1.ASN1Parser(privateKeyOctet.valueBytes!).nextObject()
        as asn1.ASN1Sequence;
    final modulus = (inner.elements![1] as asn1.ASN1Integer).integer!;
    final privateExp = (inner.elements![3] as asn1.ASN1Integer).integer!;
    final p = (inner.elements![4] as asn1.ASN1Integer).integer!;
    final q = (inner.elements![5] as asn1.ASN1Integer).integer!;
    return pc.RSAPrivateKey(modulus, privateExp, p, q);
  } on FormatException {
    rethrow;
  } catch (e) {
    throw FormatException('Could not parse PKCS#8 RSA private key: $e');
  }
}
