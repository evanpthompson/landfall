import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pointycastle/asn1.dart' as asn1;
import 'package:pointycastle/export.dart' as pc;
import 'package:test/test.dart';

import 'package:landfall_server/src/photo/google_service_account_auth.dart';

/// Stub [http.Client] that records all POSTs and replays canned responses.
class _StubClient extends http.BaseClient {
  _StubClient(this.responder);

  final FutureOr<http.Response> Function(http.Request) responder;
  final List<http.Request> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // BaseRequest in tests is always Request — read the body.
    final body = request is http.Request ? request.body : '';
    final captured = http.Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..body = body;
    requests.add(captured);
    final response = await responder(captured);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }
}

/// Generates a 2048-bit RSA keypair for use in tests.
///
/// Deliberately not deterministic — different runs use different keys. The
/// public half is exposed so tests can verify the JWT signature.
class _TestKeyPair {
  _TestKeyPair._(this.privateKeyPem, this.publicKey);

  final String privateKeyPem;
  final pc.RSAPublicKey publicKey;

  static _TestKeyPair generate() {
    final keyGen = pc.RSAKeyGenerator()
      ..init(pc.ParametersWithRandom(
        pc.RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
        _seededRandom(),
      ));
    final pair = keyGen.generateKeyPair();
    final private = pair.privateKey;
    final public = pair.publicKey;
    return _TestKeyPair._(_encodePkcs8Pem(private), public);
  }

  static pc.SecureRandom _seededRandom() {
    final rnd = pc.FortunaRandom();
    final seed = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
    rnd.seed(pc.KeyParameter(seed));
    return rnd;
  }

  static String _encodePkcs8Pem(pc.RSAPrivateKey k) {
    // PKCS#8 PrivateKeyInfo:
    //   SEQUENCE {
    //     version           INTEGER (0),
    //     algorithm         AlgorithmIdentifier (rsaEncryption + NULL),
    //     privateKey        OCTET STRING (PKCS#1 RSAPrivateKey)
    //   }
    final rsaInner = asn1.ASN1Sequence(elements: [
      asn1.ASN1Integer(BigInt.zero),                              // version
      asn1.ASN1Integer(k.modulus!),                               // n
      asn1.ASN1Integer(k.publicExponent!),                        // e
      asn1.ASN1Integer(k.privateExponent!),                       // d
      asn1.ASN1Integer(k.p!),                                     // p
      asn1.ASN1Integer(k.q!),                                     // q
      asn1.ASN1Integer(k.privateExponent! % (k.p! - BigInt.one)), // dP
      asn1.ASN1Integer(k.privateExponent! % (k.q! - BigInt.one)), // dQ
      asn1.ASN1Integer(k.q!.modInverse(k.p!)),                    // qInv
    ]);
    rsaInner.encode();

    final algorithm = asn1.ASN1Sequence(elements: [
      asn1.ASN1ObjectIdentifier.fromName('rsaEncryption'),
      asn1.ASN1Null(),
    ]);

    final pkcs8 = asn1.ASN1Sequence(elements: [
      asn1.ASN1Integer(BigInt.zero),
      algorithm,
      asn1.ASN1OctetString(octets: rsaInner.encodedBytes),
    ]);
    final der = pkcs8.encode();
    final b64 = base64.encode(der);
    final lines = <String>[];
    for (var i = 0; i < b64.length; i += 64) {
      lines.add(b64.substring(i, i + 64 > b64.length ? b64.length : i + 64));
    }
    return [
      '-----BEGIN PRIVATE KEY-----',
      ...lines,
      '-----END PRIVATE KEY-----',
      '',
    ].join('\n');
  }
}

void main() {
  // Generate the test keypair once for the whole file. 2048-bit gen is slow
  // (~1s); regenerating per test would dominate the test runtime.
  late _TestKeyPair keys;

  setUpAll(() {
    keys = _TestKeyPair.generate();
  });

  group('GoogleServiceAccountAuth — construction', () {
    test('rejects empty client email', () {
      expect(
        () => GoogleServiceAccountAuth(
          clientEmail: '',
          privateKeyPem: keys.privateKeyPem,
          scopes: ['https://www.googleapis.com/auth/drive.readonly'],
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty private key', () {
      expect(
        () => GoogleServiceAccountAuth(
          clientEmail: 'svc@x.iam.gserviceaccount.com',
          privateKeyPem: '',
          scopes: ['https://www.googleapis.com/auth/drive.readonly'],
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty scopes list', () {
      expect(
        () => GoogleServiceAccountAuth(
          clientEmail: 'svc@x.iam.gserviceaccount.com',
          privateKeyPem: keys.privateKeyPem,
          scopes: const [],
        ),
        throwsArgumentError,
      );
    });

    test('rejects malformed PEM', () {
      expect(
        () => GoogleServiceAccountAuth(
          clientEmail: 'svc@x.iam.gserviceaccount.com',
          privateKeyPem: 'not a real key',
          scopes: ['https://www.googleapis.com/auth/drive.readonly'],
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('GoogleServiceAccountAuth — JWT signing', () {
    test('mints a JWT with RS256 header and expected claims', () async {
      final issuedAt = DateTime.utc(2026, 5, 17, 12, 0, 0);
      final client = _StubClient((req) {
        // Inspect the JWT inside the form body.
        final jwt = _parseAssertion(req.body);
        final parts = jwt.split('.');
        expect(parts.length, 3);

        final header = jsonDecode(utf8.decode(_b64UrlDecode(parts[0])));
        expect(header['alg'], 'RS256');
        expect(header['typ'], 'JWT');

        final claims = jsonDecode(utf8.decode(_b64UrlDecode(parts[1])));
        expect(claims['iss'], 'svc@x.iam.gserviceaccount.com');
        expect(claims['scope'],
            'https://www.googleapis.com/auth/drive.readonly');
        expect(claims['aud'], 'https://oauth2.googleapis.com/token');
        expect(claims['iat'], issuedAt.millisecondsSinceEpoch ~/ 1000);
        expect(claims['exp'],
            issuedAt.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000);

        return http.Response(
          jsonEncode({'access_token': 'ya29.test', 'expires_in': 3600}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final auth = GoogleServiceAccountAuth(
        clientEmail: 'svc@x.iam.gserviceaccount.com',
        privateKeyPem: keys.privateKeyPem,
        scopes: ['https://www.googleapis.com/auth/drive.readonly'],
        httpClient: client,
        clock: () => issuedAt,
      );

      await auth.getAccessToken();
      expect(client.requests, hasLength(1));
    });

    test('JWT signature verifies against the public key', () async {
      final client = _StubClient((req) {
        final jwt = _parseAssertion(req.body);
        final parts = jwt.split('.');
        final signingInput = '${parts[0]}.${parts[1]}';
        final signature = _b64UrlDecode(parts[2]);

        final verifier = pc.RSASigner(pc.SHA256Digest(), '0609608648016503040201')
          ..init(false, pc.PublicKeyParameter<pc.RSAPublicKey>(keys.publicKey));
        final ok = verifier.verifySignature(
          Uint8List.fromList(utf8.encode(signingInput)),
          pc.RSASignature(signature),
        );
        expect(ok, isTrue, reason: 'RS256 signature did not verify');

        return http.Response(
          jsonEncode({'access_token': 'ya29.test', 'expires_in': 3600}),
          200,
        );
      });

      final auth = GoogleServiceAccountAuth(
        clientEmail: 'svc@x.iam.gserviceaccount.com',
        privateKeyPem: keys.privateKeyPem,
        scopes: ['https://www.googleapis.com/auth/drive.readonly'],
        httpClient: client,
      );
      await auth.getAccessToken();
    });
  });

  group('GoogleServiceAccountAuth — token exchange', () {
    test('returns access_token from a successful response', () async {
      final client = _StubClient((_) => http.Response(
            jsonEncode({'access_token': 'ya29.unique', 'expires_in': 3600}),
            200,
          ));
      final auth = GoogleServiceAccountAuth(
        clientEmail: 'svc@x.iam.gserviceaccount.com',
        privateKeyPem: keys.privateKeyPem,
        scopes: ['https://www.googleapis.com/auth/drive.readonly'],
        httpClient: client,
      );
      expect(await auth.getAccessToken(), 'ya29.unique');
    });

    test('POSTs to oauth2.googleapis.com/token with the right grant type',
        () async {
      final client = _StubClient((_) => http.Response(
            jsonEncode({'access_token': 'x', 'expires_in': 3600}),
            200,
          ));
      final auth = GoogleServiceAccountAuth(
        clientEmail: 'svc@x.iam.gserviceaccount.com',
        privateKeyPem: keys.privateKeyPem,
        scopes: ['https://www.googleapis.com/auth/drive.readonly'],
        httpClient: client,
      );
      await auth.getAccessToken();
      final req = client.requests.single;
      expect(req.method, 'POST');
      expect(req.url.toString(), 'https://oauth2.googleapis.com/token');
      expect(req.body, contains('grant_type='
          'urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer'));
      expect(req.body, contains('assertion='));
    });

    test('throws with a useful message on HTTP error', () async {
      final client = _StubClient((_) => http.Response(
            jsonEncode({'error': 'invalid_grant'}),
            400,
          ));
      final auth = GoogleServiceAccountAuth(
        clientEmail: 'svc@x.iam.gserviceaccount.com',
        privateKeyPem: keys.privateKeyPem,
        scopes: ['https://www.googleapis.com/auth/drive.readonly'],
        httpClient: client,
      );
      await expectLater(
        auth.getAccessToken(),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('invalid_grant'),
        )),
      );
    });

    test('joins multiple scopes with spaces', () async {
      final client = _StubClient((req) {
        final jwt = _parseAssertion(req.body);
        final claims = jsonDecode(
            utf8.decode(_b64UrlDecode(jwt.split('.')[1])));
        expect(claims['scope'],
            'https://www.googleapis.com/auth/drive.readonly '
            'https://www.googleapis.com/auth/calendar.readonly');
        return http.Response(
          jsonEncode({'access_token': 'x', 'expires_in': 3600}),
          200,
        );
      });
      final auth = GoogleServiceAccountAuth(
        clientEmail: 'svc@x.iam.gserviceaccount.com',
        privateKeyPem: keys.privateKeyPem,
        scopes: const [
          'https://www.googleapis.com/auth/drive.readonly',
          'https://www.googleapis.com/auth/calendar.readonly',
        ],
        httpClient: client,
      );
      await auth.getAccessToken();
    });
  });

  group('GoogleServiceAccountAuth — caching', () {
    test('caches the token for subsequent calls within its lifetime', () async {
      final client = _StubClient((_) => http.Response(
            jsonEncode({'access_token': 'cached', 'expires_in': 3600}),
            200,
          ));
      final auth = GoogleServiceAccountAuth(
        clientEmail: 'svc@x.iam.gserviceaccount.com',
        privateKeyPem: keys.privateKeyPem,
        scopes: ['https://www.googleapis.com/auth/drive.readonly'],
        httpClient: client,
      );
      expect(await auth.getAccessToken(), 'cached');
      expect(await auth.getAccessToken(), 'cached');
      expect(await auth.getAccessToken(), 'cached');
      expect(client.requests, hasLength(1));
    });

    test('refreshes when within the skew window (5 min before expiry)',
        () async {
      var calls = 0;
      final client = _StubClient((_) {
        calls++;
        return http.Response(
          jsonEncode({'access_token': 'token$calls', 'expires_in': 3600}),
          200,
        );
      });
      var now = DateTime.utc(2026, 5, 17, 12, 0, 0);
      final auth = GoogleServiceAccountAuth(
        clientEmail: 'svc@x.iam.gserviceaccount.com',
        privateKeyPem: keys.privateKeyPem,
        scopes: ['https://www.googleapis.com/auth/drive.readonly'],
        httpClient: client,
        clock: () => now,
      );
      expect(await auth.getAccessToken(), 'token1');
      // Advance 55 minutes — within the 5-min skew window.
      now = now.add(const Duration(minutes: 55));
      expect(await auth.getAccessToken(), 'token2');
    });

    test('refreshes after expiry', () async {
      var calls = 0;
      final client = _StubClient((_) {
        calls++;
        return http.Response(
          jsonEncode({'access_token': 'token$calls', 'expires_in': 3600}),
          200,
        );
      });
      var now = DateTime.utc(2026, 5, 17, 12, 0, 0);
      final auth = GoogleServiceAccountAuth(
        clientEmail: 'svc@x.iam.gserviceaccount.com',
        privateKeyPem: keys.privateKeyPem,
        scopes: ['https://www.googleapis.com/auth/drive.readonly'],
        httpClient: client,
        clock: () => now,
      );
      expect(await auth.getAccessToken(), 'token1');
      now = now.add(const Duration(hours: 2));
      expect(await auth.getAccessToken(), 'token2');
    });
  });
}

// ── helpers ──────────────────────────────────────────────────────────────────

Uint8List _b64UrlDecode(String s) {
  final padded = s.padRight((s.length + 3) & ~3, '=');
  return base64Url.decode(padded);
}

String _parseAssertion(String body) {
  // body is application/x-www-form-urlencoded.
  for (final pair in body.split('&')) {
    final i = pair.indexOf('=');
    if (i < 0) continue;
    final key = pair.substring(0, i);
    if (key == 'assertion') {
      return Uri.decodeQueryComponent(pair.substring(i + 1));
    }
  }
  fail('No assertion parameter found in token-exchange body: $body');
}
