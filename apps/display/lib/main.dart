import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:display/src/data/local/app_database.dart';
import 'package:display/src/data/settings/drift_display_settings_repository.dart';
import 'package:display/app.dart';
import 'package:display/setup_wizard_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape — the display is always a TV or monitor.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide system UI chrome for an immersive ambient display.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final database = AppDatabase();

  void launchApp(String serverUrl) {
    runApp(LandfallApp(database: database, serverUrl: serverUrl));
  }

  final settings =
      await DriftDisplaySettingsRepository(database).getSettings();

  if (settings.serverUrl.isEmpty || !settings.wizardComplete) {
    runApp(SetupWizardApp(database: database, onComplete: launchApp));
  } else {
    launchApp(settings.serverUrl);
  }
}
