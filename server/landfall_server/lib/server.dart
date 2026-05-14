import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/passkey.dart';

import 'src/calendar/calendar_refresh_call.dart';
import 'src/generated/endpoints.dart';
import 'src/generated/protocol.dart';
import 'src/license/stripe_webhook_route.dart';
import 'src/theme/theme_seeder.dart';
import 'src/theme/marketplace_seeder.dart';
import 'src/photo/photo_refresh_call.dart';
import 'src/profile/profile_schedule_call.dart';
import 'src/web/routes/app_config_route.dart';
import 'src/web/routes/build_manifest_route.dart';
import 'src/web/routes/rest/card_detail_route.dart';
import 'src/web/routes/rest/cards_route.dart';
import 'src/web/routes/rest/telemetry_route.dart';
import 'src/web/routes/rest/ticker_route.dart';
import 'src/web/routes/calendar_oauth_route.dart';
import 'src/web/routes/microsoft_calendar_oauth_route.dart';
import 'src/web/routes/photo_serve_route.dart';
import 'src/web/routes/companion/companion_page_route.dart';
import 'src/web/routes/root.dart';
import 'src/weather/weather_refresh_call.dart';

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  _checkPasswordsYamlPermissions();

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
  pod.registerFutureCall(ProfileScheduleCall(), 'profileSchedule');

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

  // Companion interaction web page — serves the Flutter web build at
  // /companion/{uuid} with the display ID injected, plus static assets.
  pod.webServer.addRoute(CompanionPageRoute(), '/c/**');

  // REST API — agent card push/list/dismiss over plain HTTP.
  // Authentication: Authorization: Bearer <api_key>
  pod.webServer.addRoute(CardsRoute(), '/api/v1/cards');
  pod.webServer.addRoute(CardDetailRoute(), '/api/v1/cards/**');
  pod.webServer.addRoute(TickerRoute(), '/api/v1/ticker');

  // Build manifest receipt — what actually shipped in this image. Baked at
  // build time into /etc/landfall/build-manifest.json; see deploy/pi-gen/build.sh.
  pod.webServer.addRoute(BuildManifestRoute(), '/health/build');

  // Dev-build-only self-hosted telemetry. Production builds (Pi appliance
  // image, public Fire TV APK, public macOS dmg) are built WITHOUT
  // LANDFALL_TELEMETRY_ENDPOINT and therefore never POST to this route.
  // See docs/build_defines.md.
  pod.webServer.addRoute(TelemetryRoute(), '/api/v1/telemetry/event');

  // Start the server.
  await pod.start();

  // Seed built-in themes and marketplace themes if not already present.
  // Also clean up any orphaned companion profiles left by prior server versions.
  final seedSession = await pod.createSession();
  try {
    await ThemeSeeder.seed(seedSession);
    await MarketplaceSeeder.seed(seedSession);
    await MarketplaceSeeder.cleanupOrphanedCompanionProfiles(seedSession);
  } finally {
    await seedSession.close();
  }

  // ignore: deprecated_member_use
  await pod.futureCallWithDelay('weatherRefresh', null, Duration.zero);
  // ignore: deprecated_member_use
  await pod.futureCallWithDelay('calendarRefresh', null, Duration.zero);
  // ignore: deprecated_member_use
  await pod.futureCallWithDelay('photoRefresh', null, Duration.zero);
  // ignore: deprecated_member_use
  await pod.futureCallWithDelay('profileSchedule', null, Duration.zero);
}

/// Warns if config/passwords.yaml is world-readable (A02:2025).
///
/// On non-POSIX platforms (Windows) the check is skipped since permission
/// bits work differently. On POSIX, if the file is readable by "other"
/// (mode & 0x4 != 0), the server logs a prominent warning but continues —
/// a hard exit would prevent recovery in single-user dev setups where the
/// file is intentionally 644.
void _checkPasswordsYamlPermissions() {
  if (!Platform.isLinux && !Platform.isMacOS) return;
  final file = File('config/passwords.yaml');
  if (!file.existsSync()) return;
  final stat = file.statSync();
  // Bit 2 of the lowest octet = world-read permission.
  if (stat.mode & 0x4 != 0) {
    // ignore: avoid_print
    print(
      '\n⚠️  SECURITY WARNING: config/passwords.yaml is world-readable '
      '(mode ${stat.mode.toRadixString(8)}). '
      'Run: chmod 600 config/passwords.yaml\n',
    );
  }
}

