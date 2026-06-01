import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';

import 'package:display/src/app/app_config.dart';
import 'package:display/src/app/startup_decision.dart';
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

  void launchApp(String serverUrl, String displayId) {
    final webServerUrl =
        kLandfallWebServerUrl.isNotEmpty ? kLandfallWebServerUrl : serverUrl;
    // Fire-and-forget: align the clock to the server-configured zone. The clock
    // shows device-local time until this resolves, and stays device-local if
    // the server is unreachable — launch is never blocked on it.
    unawaited(_alignClockTimezone(clockRepository, webServerUrl));
    runApp(LandfallApp(
      database: database,
      serverUrl: serverUrl,
      displayId: displayId,
      clockRepository: clockRepository,
    ));
  }

  var settings = kIntegrationTestWizardMode
      ? const DisplaySettings()
      : await settingsRepository.getSettings();

  // Generate a stable display UUID on first launch and persist it.
  if (settings.displayId.isEmpty && !kIntegrationTestWizardMode) {
    final displayId = const Uuid().v4();
    settings = settings.copyWith(displayId: displayId);
    await settingsRepository.saveSettings(settings);
  }

  final decision = resolveStartupDecision(
    settings: settings,
    integrationTestServerUrl: kIntegrationTestServerUrl,
    integrationTestWizardMode: kIntegrationTestWizardMode,
    defaultServerUrl: kLandfallDefaultServerUrl,
  );

  if (decision.target == StartupTarget.display) {
    if (decision.persistDefaultSettings) {
      await settingsRepository.saveSettings(
        settings.copyWith(serverUrl: decision.serverUrl, wizardComplete: true),
      );
    }
    launchApp(decision.serverUrl, settings.displayId);
    return;
  }

  runApp(SetupWizardApp(
    database: database,
    onComplete: (serverUrl) => launchApp(serverUrl, settings.displayId),
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
