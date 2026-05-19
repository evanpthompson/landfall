import 'dart:async';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';

import '../../auth/device_auth_service.dart';
import '../../auth/otp_service.dart';

/// POST /auth/device/start
///
/// Creates a new device authorization request. No authentication required.
/// Returns JSON: {userCode, deviceCode, verificationUri, expiresIn, interval}
class DeviceAuthStartRoute extends Route {
  DeviceAuthStartRoute() : super(methods: {Method.post});

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    final host = request.url.host;
    final port = request.url.port;
    final scheme = request.url.scheme.isNotEmpty ? request.url.scheme : 'http';
    final origin = port == 0 || port == 80 || port == 443
        ? '$scheme://$host'
        : '$scheme://$host:$port';
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
          'accessToken': poll.accessToken,
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

/// GET /device
///
/// Serves a minimal HTML page with a form for phone-side code entry.
/// The user enters the 6-char code shown on their TV plus their email + OTP.
class DevicePageGetRoute extends Route {
  DevicePageGetRoute() : super(methods: {Method.get});

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    return _html(200, _devicePageHtml());
  }
}

/// POST /device
///
/// Form submission: userCode + email + code (OTP).
/// On success: verifies OTP, pairs the device, returns a success page.
/// On failure: returns an error page.
class DevicePagePostRoute extends Route {
  DevicePagePostRoute() : super(methods: {Method.post});

  final _otpService = OtpService();

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    final rawBody = await request.readAsString();
    final params = Uri.splitQueryString(rawBody);

    final userCode = (params['userCode'] ?? '').trim().toUpperCase();
    final email = (params['email'] ?? '').trim().toLowerCase();
    final code = (params['code'] ?? '').trim();

    if (userCode.isEmpty || email.isEmpty || code.isEmpty) {
      return _html(400, _errorPageHtml('All fields are required.'));
    }

    if (!DeviceAuthService.isValidUserCode(userCode)) {
      return _html(400, _errorPageHtml('Invalid or expired code. Please try again.'));
    }

    final AuthSuccess authResult;
    try {
      authResult = await _otpService.verifyCode(session, email, code);
    } catch (e) {
      return _html(400, _errorPageHtml('Invalid or expired code. Please try again.'));
    }

    DeviceAuthService.completeFlow(userCode, authResult.token);

    return _html(200, _successPageHtml());
  }
}

// ── HTML templates ─────────────────────────────────────────────────────────

Result _html(int status, String body) => Response(
      status,
      body: Body.fromString(body, mimeType: MimeType.html),
    );

String _devicePageHtml() => '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Sign in to Landfall</title>
  <style>
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
  </style>
</head>
<body>
  <div class="card">
    <h1>LANDFALL</h1>
    <p>Enter the code shown on your TV, your email address, and the one-time code sent to your email.</p>
    <form method="POST" action="/device">
      <label for="userCode">Code from TV</label>
      <input id="userCode" name="userCode" type="text" maxlength="6"
             placeholder="A1B2C3" autocomplete="off" autocapitalize="characters" required>
      <label for="email">Email address</label>
      <input id="email" name="email" type="email" placeholder="you@example.com"
             autocomplete="email" required>
      <label for="code">One-time code</label>
      <input id="code" name="code" type="text" inputmode="numeric" maxlength="6"
             placeholder="000000" autocomplete="one-time-code" required>
      <button type="submit">Sign in</button>
    </form>
  </div>
  <script>
    // Auto-request OTP when email is entered and code-from-TV is valid.
    // Note: The user must have already triggered sendCode via the Landfall app
    // or request it separately. This form just pairs the device.
  </script>
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

String _errorPageHtml(String message) => '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Error — Landfall</title>
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
    .error { color: #ff6b6b; font-size: 14px; margin-bottom: 20px; }
    a { color: #4a9eff; text-decoration: none; font-size: 14px; }
  </style>
</head>
<body>
  <div class="card">
    <h1>LANDFALL</h1>
    <p class="error">$message</p>
    <a href="/device">&larr; Try again</a>
  </div>
</body>
</html>
''';
