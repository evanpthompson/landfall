import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:window_manager/window_manager.dart';

import 'package:display/src/app/app_config.dart';
import 'package:display/src/app/startup_decision.dart';
import 'package:display/src/data/local/app_database.dart';
import 'package:display/src/data/settings/drift_display_settings_repository.dart';
import 'package:display/app.dart';
import 'package:display/setup_wizard_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    await windowManager.ensureInitialized();
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

  void launchApp(String serverUrl) {
    runApp(LandfallApp(database: database, serverUrl: serverUrl));
  }

  final settings = kIntegrationTestWizardMode
      ? const DisplaySettings()
      : await settingsRepository.getSettings();
  final decision = resolveStartupDecision(
    settings: settings,
    integrationTestServerUrl: kIntegrationTestServerUrl,
    integrationTestWizardMode: kIntegrationTestWizardMode,
    defaultServerUrl: kLandfallDefaultServerUrl,
  );

  if (decision.target == StartupTarget.display) {
    if (decision.persistDefaultSettings) {
      await settingsRepository.saveSettings(
        settings.copyWith(
          serverUrl: decision.serverUrl,
          wizardComplete: true,
        ),
      );
    }
    launchApp(decision.serverUrl);
    return;
  }

  runApp(SetupWizardApp(database: database, onComplete: launchApp));
}
