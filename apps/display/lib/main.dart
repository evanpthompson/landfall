import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:window_manager/window_manager.dart';

import 'package:display/src/app/app_config.dart';
import 'package:display/src/app/landfall_root.dart';
import 'package:display/src/app/telemetry.dart';
import 'package:display/src/data/clock/display_config_client.dart';
import 'package:display/src/data/clock/system_clock_repository.dart';
import 'package:display/src/data/local/app_database.dart';
import 'package:display/src/data/settings/drift_display_settings_repository.dart';
import 'package:display/app.dart';
import 'package:display/setup_wizard_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Dev-build-only: fires only when LANDFALL_TELEMETRY_ENDPOINT was baked in.
  Telemetry.event('app_launched');

  // Load the bundled IANA tz database so the clock can render the
  // server-configured zone (see [_alignClockTimezone]).
  tz_data.initializeTimeZones();

  // Desktop window setup. On Linux the pi-gen image bypasses this path —
  // GTK fullscreen is set in native C++ (linux/runner/my_application.cc)
  // so the kiosk hits its target dimensions before Dart starts and any
  // window_manager calls become redundant. The block remains for desktop
  // dev (macOS + Linux outside the kiosk image) and Windows.
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(const Size(1280, 720));
    await windowManager.setFullScreen(true);
  }

  // Lock to landscape — the display is always a TV or monitor.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide system UI chrome for an immersive ambient display.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Wizard integration tests use an in-memory database so settings are always
  // empty (fresh-install state) regardless of prior test runs.
  final database = kIntegrationTestWizardMode
      ? AppDatabase.forTesting(NativeDatabase.memory())
      : AppDatabase();
  final settingsRepository = DriftDisplaySettingsRepository(database);

  final clockRepository = SystemClockRepository();

  // LandfallRoot owns the server-URL source of truth: it reads settings,
  // resolves the startup decision, and rebuilds the tree on relaunch() when the
  // URL changes (setup wizard, or "change server address" from the app).
  runApp(LandfallRoot(
    settingsRepository: settingsRepository,
    buildDisplay: (serverUrl, displayId) {
      final webServerUrl =
          kLandfallWebServerUrl.isNotEmpty ? kLandfallWebServerUrl : serverUrl;
      // Fire-and-forget: align the clock to the server-configured zone. The
      // clock shows device-local time until this resolves, and stays
      // device-local if the server is unreachable — launch is never blocked.
      unawaited(_alignClockTimezone(clockRepository, webServerUrl));
      return LandfallApp(
        // Key on the URL so changing servers replaces the whole subtree
        // (Serverpod client, repos, auth) rather than mutating it in place.
        key: ValueKey(serverUrl),
        database: database,
        serverUrl: serverUrl,
        displayId: displayId,
        clockRepository: clockRepository,
      );
    },
    buildWizard: (onComplete) => SetupWizardApp(
      database: database,
      onComplete: (_) => onComplete(),
    ),
  ));
}

/// Fetches the server-configured timezone and aligns [clock] to it. Best-effort
/// and silent: any failure leaves the clock on device-local time.
Future<void> _alignClockTimezone(
  SystemClockRepository clock,
  String webServerUrl,
) async {
  final location = await resolveServerTimezone(
    HttpDisplayConfigClient(serverUrl: webServerUrl),
  );
  if (location != null) clock.alignTo(location);
}
