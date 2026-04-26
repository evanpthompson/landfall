import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_kit/ui_kit.dart';

import 'package:display/src/data/local/app_database.dart';
import 'package:display/src/data/server/server_health_checker.dart';
import 'package:display/src/data/settings/drift_display_settings_repository.dart';
import 'package:display/src/features/setup/cubit/setup_wizard_cubit.dart';
import 'package:display/src/features/setup/screens/setup_wizard_screen.dart';

/// Minimal app shell for the first-run setup wizard.
///
/// Built instead of [LandfallApp] when [DisplaySettings.serverUrl] is empty
/// or [DisplaySettings.wizardComplete] is false. [onComplete] is called with
/// the confirmed server URL; the caller rebuilds the root app via [runApp].
class SetupWizardApp extends StatelessWidget {
  const SetupWizardApp({
    super.key,
    required this.database,
    required this.onComplete,
  });

  final AppDatabase database;
  final ValueChanged<String> onComplete;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SetupWizardCubit(
        settingsRepository: DriftDisplaySettingsRepository(database),
        healthChecker: const HttpServerHealthChecker(),
      )..init(),
      child: MaterialApp(
        title: 'Landfall Setup',
        debugShowCheckedModeBanner: false,
        theme: LandfallTheme.dark,
        home: SetupWizardScreen(onComplete: onComplete),
      ),
    );
  }
}
