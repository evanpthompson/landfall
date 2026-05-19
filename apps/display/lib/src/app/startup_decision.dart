import 'package:landfall_shared/landfall_shared.dart';

enum StartupTarget { display, setupWizard }

class StartupDecision {
  const StartupDecision._({
    required this.target,
    this.serverUrl = '',
    this.persistDefaultSettings = false,
  });

  const StartupDecision.display(
    String serverUrl, {
    bool persistDefaultSettings = false,
  }) : this._(
          target: StartupTarget.display,
          serverUrl: serverUrl,
          persistDefaultSettings: persistDefaultSettings,
        );

  const StartupDecision.setupWizard()
      : this._(target: StartupTarget.setupWizard);

  final StartupTarget target;
  final String serverUrl;
  final bool persistDefaultSettings;
}

StartupDecision resolveStartupDecision({
  required DisplaySettings settings,
  required String integrationTestServerUrl,
  required bool integrationTestWizardMode,
  required String defaultServerUrl,
}) {
  if (integrationTestServerUrl.isNotEmpty) {
    return StartupDecision.display(integrationTestServerUrl);
  }

  if (integrationTestWizardMode) {
    return const StartupDecision.setupWizard();
  }

  // A baked-in default that differs from the stored URL wins and is
  // persisted. Without this, a stale serverUrl in the local DB (e.g. an
  // old Mac dev IP) survives every dart-define swap and rebuild.
  if (defaultServerUrl.isNotEmpty && defaultServerUrl != settings.serverUrl) {
    return StartupDecision.display(
      defaultServerUrl,
      persistDefaultSettings: true,
    );
  }

  if (settings.serverUrl.isNotEmpty && settings.wizardComplete) {
    return StartupDecision.display(settings.serverUrl);
  }

  if (defaultServerUrl.isNotEmpty) {
    return StartupDecision.display(
      defaultServerUrl,
      persistDefaultSettings: true,
    );
  }

  return const StartupDecision.setupWizard();
}
