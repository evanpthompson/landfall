import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'display_settings_state.dart';

export 'display_settings_state.dart';

class DisplaySettingsCubit extends Cubit<DisplaySettingsState> {
  DisplaySettingsCubit(this._repository, {this.onAfterSave})
      : super(const DisplaySettingsLoading());

  final DisplaySettingsRepository _repository;

  /// Called synchronously after every [updateSettings] save.
  /// Intended for fire-and-forget write-through to the remote server.
  final void Function(DisplaySettings)? onAfterSave;

  Future<void> loadSettings() async {
    final settings = await _repository.getSettings();
    emit(DisplaySettingsLoaded(settings));
  }

  Future<void> updateSettings(DisplaySettings settings) async {
    await _repository.saveSettings(settings);
    onAfterSave?.call(settings);
    emit(DisplaySettingsLoaded(settings));
  }
}
