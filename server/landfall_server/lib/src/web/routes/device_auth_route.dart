import 'dart:async';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';

import '../../auth/device_auth_service.dart';
import '../../auth/otp_service.dart';
import '../../net/lan_base_url.dart';

/// POST /auth/device/start
///
/// Creates a new device authorization request. No authentication required.
/// Returns JSON: {userCode, deviceCode, verificationUri, expiresIn, interval}
class DeviceAuthStartRoute extends Route {
  DeviceAuthStartRoute({Future<String> Function()? resolveBaseUrl})
      : _resolveBaseUrl = resolveBaseUrl ?? resolveLanBaseUrl,
        super(methods: {Method.post});

  /// Resolves the LAN-reachable base URL for the verification page. Injectable
  /// so tests can pin the URL without depending on the host's interfaces.
  final Future<String> Function() _resolveBaseUrl;

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    // The phone that visits this URL is on the household LAN, NOT the host the
    // TV used to reach the server. The TV hits the server over loopback on the
    // Pi (LANDFALL_WEB_SERVER_URL=http://127.0.0.1:8082/), so trusting
    // request.url.host would tell the user to open "127.0.0.1:8082/device" —
    // unreachable from a phone. Resolve the LAN-reachable base instead
    // (Caddy-fronted domain on the Pi, RFC1918 IP in direct-connect dev), and
    // only fall back to the request origin if no LAN address is available.
    final base = await _resolveBaseUrl();
    final origin = base.isNotEmpty ? base : _originFromRequest(request);
    final verificationUri = '$origin/device';

    final result = DeviceAuthService.startFlow(
      verificationUri: verificationUri,
    );

    return Response(
      200,
      body: Body.fromString(
        jsonEncode({
          'userCode': result.userCode,
          'deviceCode': result.deviceCode,
          'verificationUri': result.verificationUri,
          'expiresIn': result.expiresIn,
          'interval': result.interval,
        }),
        mimeType: MimeType.json,
      ),
    );
  }

  /// Last-resort origin derived from the inbound request. Only used when no
  /// LAN-reachable base could be resolved (no LANDFALL_DOMAIN and no RFC1918
  /// interface), e.g. a fully isolated dev box.
  static String _originFromRequest(Request request) {
    final host = request.url.host;
    final port = request.url.port;
    final scheme = request.url.scheme.isNotEmpty ? request.url.scheme : 'http';
    return port == 0 || port == 80 || port == 443
        ? '$scheme://$host'
        : '$scheme://$host:$port';
  }
}

/// POST /auth/device/poll
///
/// Body JSON: `{"deviceCode": "value"}`
///
/// Polls for authorization status. Returns one of:
///   `{"status": "authorization_pending"}`
///   `{"status": "expired_token"}`
///   `{"status": "authorized", "accessToken": "jwt"}`
class DeviceAuthPollRoute extends Route {
  DeviceAuthPollRoute() : super(methods: {Method.post});

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    final rawBody = await request.readAsString();
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(rawBody) as Map<String, dynamic>;
    } catch (_) {
      return Response(
        400,
        body: Body.fromString(
          jsonEncode({'error': 'invalid JSON body'}),
          mimeType: MimeType.json,
        ),
      );
    }

    final deviceCode = body['deviceCode'];
    if (deviceCode is! String || deviceCode.isEmpty) {
      return Response(
        400,
        body: Body.fromString(
          jsonEncode({'error': 'deviceCode is required'}),
          mimeType: MimeType.json,
        ),
      );
    }

    final poll = DeviceAuthService.pollFlow(deviceCode);

    final Map<String, dynamic> responseBody = switch (poll.status) {
      DevicePollStatus.authorized => {
        'status': 'authorized',
        'authSuccess': poll.authSuccessJson,
      },
      DevicePollStatus.authorizationPending => {
        'status': 'authorization_pending',
      },
      DevicePollStatus.expiredToken => {
        'status': 'expired_token',
      },
    };

    return Response(
      200,
      body: Body.fromString(
        jsonEncode(responseBody),
        mimeType: MimeType.json,
      ),
    );
  }
}

/// GET+POST /device
///
/// Two-step flow:
///
/// Step 1 — GET /device
///   Shows form: TV code + email. User submits → POST with step=send.
///
/// Step 1 — POST /device (step=send)
///   Calls [OtpService.sendCode], then redirects to:
///   GET /device?userCode=XXX&email=yyy  (step 2 view)
///
/// Step 2 — GET /device?userCode=XXX&email=yyy
///   Shows OTP entry form pre-filled with userCode and email.
///
/// Step 2 — POST /device (step=verify)
///   Verifies OTP, pairs the device, returns success page.
class DevicePageRoute extends Route {
  DevicePageRoute() : super(methods: {Method.get, Method.post});

  final _otpService = OtpService();

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    if (request.method == Method.get) {
      final userCode = request.url.queryParameters['userCode'] ?? '';
      final email = request.url.queryParameters['email'] ?? '';
      if (userCode.isNotEmpty && email.isNotEmpty) {
        return _html(200, _deviceStep2Html(userCode: userCode, email: email));
      }
      return _html(200, _deviceStep1Html());
    }

    final rawBody = await request.readAsString();
    final params = Uri.splitQueryString(rawBody);
    final step = params['step'] ?? 'verify';

    if (step == 'send') {
      // Step 1 → send OTP to email, then redirect to step 2.
      final userCode = (params['userCode'] ?? '').trim().toUpperCase();
      final email = (params['email'] ?? '').trim().toLowerCase();

      if (userCode.isEmpty || email.isEmpty) {
        return _html(
          400,
          _deviceStep1Html(error: 'TV code and email are required.'),
        );
      }
      if (!DeviceAuthService.isValidUserCode(userCode)) {
        return _html(
          400,
          _deviceStep1Html(
            error:
                'Invalid or expired TV code. Check the code on your TV and try again.',
          ),
        );
      }

      try {
        await _otpService.sendCode(session, email);
      } catch (_) {
        return _html(
          400,
          _deviceStep1Html(
            error:
                'Could not send code. Check your email address and try again.',
          ),
        );
      }

      final redirectUri = Uri.parse('/device').replace(
        queryParameters: {
          'userCode': userCode,
          'email': email,
        },
      );
      return Response.seeOther(redirectUri);
    }

    // Step 2 → verify OTP and pair device.
    final userCode = (params['userCode'] ?? '').trim().toUpperCase();
    final email = (params['email'] ?? '').trim().toLowerCase();
    final code = (params['code'] ?? '').trim();

    if (userCode.isEmpty || email.isEmpty || code.isEmpty) {
      return _html(
        400,
        _deviceStep2Html(
          userCode: userCode,
          email: email,
          error: 'All fields are required.',
        ),
      );
    }
    if (!DeviceAuthService.isValidUserCode(userCode)) {
      return _html(
        400,
        _deviceStep2Html(
          userCode: userCode,
          email: email,
          error: 'Invalid or expired TV code. Please start over on your TV.',
        ),
      );
    }

    final AuthSuccess authResult;
    try {
      authResult = await _otpService.verifyCode(session, email, code);
    } catch (_) {
      return _html(
        400,
        _deviceStep2Html(
          userCode: userCode,
          email: email,
          error: 'Invalid or expired code. Check your email and try again.',
        ),
      );
    }

    DeviceAuthService.completeFlow(userCode, authResult.toJson());
    return _html(200, _successPageHtml());
  }
}

// ── HTML templates ─────────────────────────────────────────────────────────

Result _html(int status, String body) => Response(
  status,
  body: Body.fromString(body, mimeType: MimeType.html),
);

String _sharedCss() => '''
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #0a0a0a; color: #e0e0e0;
      min-height: 100vh; display: flex; align-items: center; justify-content: center;
    }
    .card {
      background: #141414; border: 1px solid #222; border-radius: 12px;
      padding: 40px; width: 100%; max-width: 400px;
    }
    h1 { font-size: 22px; font-weight: 700; letter-spacing: 4px; color: #fff; margin-bottom: 8px; }
    p { color: #666; font-size: 14px; margin-bottom: 28px; line-height: 1.5; }
    .step { font-size: 11px; color: #555; letter-spacing: 1px; text-transform: uppercase; margin-bottom: 20px; }
    label { display: block; font-size: 12px; color: #888; margin-bottom: 6px; letter-spacing: 0.5px; }
    input {
      width: 100%; padding: 12px 14px; background: #1a1a1a; border: 1px solid #2a2a2a;
      border-radius: 8px; color: #fff; font-size: 15px; margin-bottom: 16px;
      outline: none; transition: border-color 0.15s;
    }
    input:focus { border-color: #4a9eff; }
    input[name="userCode"] { letter-spacing: 6px; font-size: 20px; font-weight: 600; text-align: center; text-transform: uppercase; }
    button {
      width: 100%; padding: 13px; background: #4a9eff; border: none; border-radius: 8px;
      color: #fff; font-size: 15px; font-weight: 600; cursor: pointer; transition: opacity 0.15s;
    }
    button:hover { opacity: 0.85; }
    .error { color: #ff6b6b; font-size: 13px; margin-bottom: 16px; }
''';

String _deviceStep1Html({String? error}) =>
    '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Sign in to Landfall</title>
  <style>${_sharedCss()}</style>
</head>
<body>
  <div class="card">
    <h1>LANDFALL</h1>
    <p class="step">Step 1 of 2</p>
    <p>Enter the 6-character code shown on your TV and your email address. We'll send a sign-in code to your email.</p>
    ${error != null ? '<p class="error">$error</p>' : ''}
    <form method="POST" action="/device">
      <input type="hidden" name="step" value="send">
      <label for="userCode">Code from TV</label>
      <input id="userCode" name="userCode" type="text" maxlength="6"
             placeholder="A1B2C3" autocomplete="off" autocapitalize="characters"
             spellcheck="false" required autofocus>
      <label for="email">Email address</label>
      <input id="email" name="email" type="email" placeholder="you@example.com"
             autocomplete="email" required>
      <button type="submit">Send sign-in code</button>
    </form>
  </div>
</body>
</html>
''';

String _deviceStep2Html({
  required String userCode,
  required String email,
  String? error,
}) =>
    '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Sign in to Landfall</title>
  <style>${_sharedCss()}</style>
</head>
<body>
  <div class="card">
    <h1>LANDFALL</h1>
    <p class="step">Step 2 of 2</p>
    <p>We sent a 6-digit code to <strong style="color:#e0e0e0">$email</strong>. Enter it below to sign in.</p>
    ${error != null ? '<p class="error">$error</p>' : ''}
    <form method="POST" action="/device">
      <input type="hidden" name="step" value="verify">
      <input type="hidden" name="userCode" value="$userCode">
      <input type="hidden" name="email" value="$email">
      <label for="code">Sign-in code from email</label>
      <input id="code" name="code" type="text" inputmode="numeric" maxlength="6"
             placeholder="000000" autocomplete="one-time-code" required autofocus>
      <button type="submit">Sign in</button>
    </form>
    <p style="margin-top:20px;text-align:center">
      <a href="/device" style="color:#555;font-size:13px">Start over</a>
    </p>
  </div>
</body>
</html>
''';

String _successPageHtml() => '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Signed in — Landfall</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #0a0a0a; color: #e0e0e0;
      min-height: 100vh; display: flex; align-items: center; justify-content: center;
    }
    .card {
      background: #141414; border: 1px solid #222; border-radius: 12px;
      padding: 40px; max-width: 400px; text-align: center;
    }
    h1 { font-size: 22px; letter-spacing: 4px; color: #fff; margin-bottom: 16px; }
    p { color: #888; font-size: 14px; line-height: 1.6; }
    .check { font-size: 48px; margin-bottom: 24px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="check">✓</div>
    <h1>LANDFALL</h1>
    <p>You&rsquo;re signed in. Your TV will continue automatically in a moment.</p>
    <p style="margin-top:12px">You can close this window.</p>
  </div>
</body>
</html>
''';
