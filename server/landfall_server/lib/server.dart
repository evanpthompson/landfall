import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/passkey.dart';

import 'src/calendar/calendar_refresh_call.dart';
import 'src/generated/endpoints.dart';
import 'src/generated/protocol.dart';
import 'src/license/stripe_webhook_route.dart';
import 'src/photo/photo_refresh_call.dart';
import 'src/web/routes/app_config_route.dart';
import 'src/web/routes/calendar_oauth_route.dart';
import 'src/web/routes/microsoft_calendar_oauth_route.dart';
import 'src/web/routes/photo_serve_route.dart';
import 'src/web/routes/root.dart';
import 'src/weather/weather_refresh_call.dart';

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(args, Protocol(), Endpoints());

  // Initialize authentication services for the server.
  // Token managers will be used to validate and issue authentication keys,
  // and the identity providers will be the authentication options available for users.
  pod.initializeAuthServices(
    tokenManagerBuilders: [
      // Use JWT for authentication keys towards the server.
      JwtConfigFromPasswords(),
    ],
    identityProviderBuilders: [
      // Passkey (WebAuthn/FIDO2) is the primary identity provider.
      // passkeyHostname must be set in passwords.yaml (e.g. 'localhost' for dev).
      PasskeyIdpConfigFromPasswords(),
    ],
  );

  // Setup a default page at the web root.
  // These are used by the default page.
  pod.webServer.addRoute(RootRoute(), '/');
  pod.webServer.addRoute(RootRoute(), '/index.html');

  // Serve all files in the web/static relative directory under /.
  // These are used by the default web page.
  final root = Directory(Uri(path: 'web/static').toFilePath());
  pod.webServer.addRoute(StaticRoute.directory(root));

  // Setup the app config route.
  // We build this configuration based on the servers api url and serve it to
  // the flutter app.
  pod.webServer.addRoute(
    AppConfigRoute(apiConfig: pod.config.apiServer),
    '/app/assets/assets/config.json',
  );

  // Checks if the flutter web app has been built and serves it if it has.
  final appDir = Directory(Uri(path: 'web/app').toFilePath());
  if (appDir.existsSync()) {
    // Serve the flutter web app under the /app path.
    pod.webServer.addRoute(
      FlutterRoute(
        Directory(
          Uri(path: 'web/app').toFilePath(),
        ),
      ),
      '/app',
    );
  } else {
    // If the flutter web app has not been built, serve the build app page.
    pod.webServer.addRoute(
      StaticRoute.file(
        File(
          Uri(path: 'web/pages/build_flutter_app.html').toFilePath(),
        ),
      ),
      '/app/**',
    );
  }

  // Register future calls.
  pod.registerFutureCall(WeatherRefreshCall(), 'weatherRefresh');
  pod.registerFutureCall(CalendarRefreshCall(), 'calendarRefresh');
  pod.registerFutureCall(PhotoRefreshCall(), 'photoRefresh');

  // OAuth routes for connecting calendar providers.
  pod.webServer.addRoute(CalendarOAuthStartRoute(), '/calendar/oauth/start');
  pod.webServer.addRoute(
    CalendarOAuthCallbackRoute(),
    '/calendar/oauth/callback',
  );
  pod.webServer.addRoute(
    MicrosoftCalendarOAuthStartRoute(),
    '/calendar/microsoft/oauth/start',
  );
  pod.webServer.addRoute(
    MicrosoftCalendarOAuthCallbackRoute(),
    '/calendar/microsoft/oauth/callback',
  );

  // Photo serve route — proxies image bytes from the upstream provider.
  // Uses /photos/** so any path under /photos/ is matched.
  pod.webServer.addRoute(PhotoServeRoute(), '/photos/**');

  // Stripe webhook — receives purchase confirmation events.
  // Verifies Stripe-Signature using stripeWebhookSecret from passwords.yaml.
  pod.webServer.addRoute(StripeWebhookRoute(), '/stripe/webhook');

  // Start the server.
  await pod.start();

  // ignore: deprecated_member_use
  // Schedule the first weather refresh immediately after startup.
  // ignore: deprecated_member_use
  await pod.futureCallWithDelay('weatherRefresh', null, Duration.zero);
  // ignore: deprecated_member_use
  // Calendar refresh starts immediately; skips quietly if no credentials exist.
  // ignore: deprecated_member_use
  await pod.futureCallWithDelay('calendarRefresh', null, Duration.zero);
  // ignore: deprecated_member_use
  // Photo refresh starts immediately; skips quietly if no folder is configured.
  // ignore: deprecated_member_use
  await pod.futureCallWithDelay('photoRefresh', null, Duration.zero);
}

