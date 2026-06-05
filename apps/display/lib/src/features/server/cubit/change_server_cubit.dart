import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/data/server/server_health_checker.dart';
import 'package:display/src/data/server/server_url_validator.dart';

part 'change_server_state.dart';

/// Drives the "change server address" flow: validate a URL (rejecting a wrong
/// origin up front), persist it as the new source-of-truth server URL, then
/// signal [ChangeServerSaved] so the UI can relaunch the app against it.
class ChangeServerCubit extends Cubit<ChangeServerState> {
  ChangeServerCubit({
    required ServerHealthChecker healthChecker,
    required DisplaySettingsRepository settingsRepository,
  })  : _validator = ServerUrlValidator(healthChecker),
        _settings = settingsRepository,
        super(const ChangeServerEditing());

  final ServerUrlValidator _validator;
  final DisplaySettingsRepository _settings;

  Future<void> submit(String raw) async {
    emit(const ChangeServerValidating());

    final outcome = await _validator.validate(raw);
    if (!outcome.isOk) {
      emit(ChangeServerEditing(error: outcome.error));
      return;
    }

    final url = outcome.normalizedUrl!;
    final current = await _settings.getSettings();
    await _settings.saveSettings(
      current.copyWith(serverUrl: url, wizardComplete: true),
    );
    emit(ChangeServerSaved(url));
  }
}
