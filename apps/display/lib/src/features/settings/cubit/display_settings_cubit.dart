import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'display_settings_state.dart';

export 'display_settings_state.dart';

class DisplaySettingsCubit extends Cubit<DisplaySettingsState> {
  DisplaySettingsCubit(this._repository) : super(const DisplaySettingsLoading());

  final DisplaySettingsRepository _repository;

  Future<void> loadSettings() async {
    final settings = await _repository.getSettings();
    emit(DisplaySettingsLoaded(settings));
  }

  Future<void> updateSettings(DisplaySettings settings) async {
    await _repository.saveSettings(settings);
    emit(DisplaySettingsLoaded(settings));
  }
}
