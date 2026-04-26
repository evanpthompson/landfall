import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/data/server/server_health_checker.dart';
import 'setup_wizard_state.dart';

export 'setup_wizard_state.dart';

class SetupWizardCubit extends Cubit<SetupWizardState> {
  SetupWizardCubit({
    required DisplaySettingsRepository settingsRepository,
    required ServerHealthChecker healthChecker,
  })  : _settings = settingsRepository,
        _health = healthChecker,
        super(const SetupWizardAt(SetupWizardStep.serverUrl));

  final DisplaySettingsRepository _settings;
  final ServerHealthChecker _health;

  String _serverUrl = '';

  /// Called on startup to resume at the correct step if a previous run
  /// partially completed.
  Future<void> init() async {
    final s = await _settings.getSettings();
    _serverUrl = s.serverUrl;

    if (s.serverUrl.isEmpty) {
      emit(const SetupWizardAt(SetupWizardStep.serverUrl));
    } else if (s.locationName.isEmpty) {
      emit(SetupWizardAt(SetupWizardStep.location, serverUrl: s.serverUrl));
    } else {
      emit(SetupWizardAt(SetupWizardStep.linkAccount, serverUrl: s.serverUrl));
    }
  }

  /// Validates [raw] as a reachable server URL, then advances to step 2.
  Future<void> submitServerUrl(String raw) async {
    emit(const SetupWizardValidating());

    final trimmed = raw.trim();
    final url = trimmed.endsWith('/') ? trimmed : '$trimmed/';

    final reachable = await _health.ping(url);
    if (!reachable) {
      emit(const SetupWizardStepError(
        'Could not reach the server. Check the URL and try again.',
        SetupWizardStep.serverUrl,
      ));
      return;
    }

    _serverUrl = url;
    final current = await _settings.getSettings();
    await _settings.saveSettings(current.copyWith(serverUrl: url));
    emit(SetupWizardAt(SetupWizardStep.location, serverUrl: _serverUrl));
  }

  /// Saves [locationName] (may be empty if skipped) and advances to step 3.
  Future<void> submitLocation(String locationName) async {
    final current = await _settings.getSettings();
    await _settings.saveSettings(
      current.copyWith(locationName: locationName.trim()),
    );
    emit(SetupWizardAt(SetupWizardStep.linkAccount, serverUrl: _serverUrl));
  }

  /// Advances from the link-account step to the done step.
  void advanceToDone() {
    emit(SetupWizardAt(SetupWizardStep.done, serverUrl: _serverUrl));
  }

  /// Marks the wizard as complete and emits [SetupWizardComplete].
  ///
  /// The app root listens for this state and calls [runApp] with
  /// [LandfallApp] using the confirmed [serverUrl].
  Future<void> complete() async {
    final current = await _settings.getSettings();
    await _settings.saveSettings(current.copyWith(wizardComplete: true));
    emit(SetupWizardComplete(serverUrl: _serverUrl));
  }
}
