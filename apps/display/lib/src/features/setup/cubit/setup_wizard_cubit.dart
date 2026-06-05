import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/data/server/server_health_checker.dart';
import 'package:display/src/data/server/server_url_validator.dart';
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
  /// partially completed. When no URL is stored, starts at the server-URL step.
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

  /// Goes one step backwards. Called by [PopScope] when the user presses Back.
  ///
  /// No-op on the first step ([SetupWizardStep.serverUrl]) — the system handles
  /// the back event there, so the app can exit or pop normally.
  void previousStep() {
    final current = state;
    if (current is! SetupWizardAt) return;
    switch (current.step) {
      case SetupWizardStep.serverUrl:
        break; // first step — let system handle Back
      case SetupWizardStep.location:
        emit(const SetupWizardAt(SetupWizardStep.serverUrl));
      case SetupWizardStep.linkAccount:
        emit(SetupWizardAt(SetupWizardStep.location, serverUrl: _serverUrl));
      case SetupWizardStep.done:
        emit(
            SetupWizardAt(SetupWizardStep.linkAccount, serverUrl: _serverUrl));
    }
  }

  /// Validates [raw] as a reachable server URL, then advances to step 2.
  Future<void> submitServerUrl(String raw) async {
    emit(const SetupWizardValidating());

    final outcome = await ServerUrlValidator(_health).validate(raw);
    if (!outcome.isOk) {
      emit(SetupWizardStepError(outcome.error!, SetupWizardStep.serverUrl));
      return;
    }

    final url = outcome.normalizedUrl!;
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
  Future<void> complete() async {
    final current = await _settings.getSettings();
    await _settings.saveSettings(current.copyWith(wizardComplete: true));
    emit(SetupWizardComplete(serverUrl: _serverUrl));
  }
}
