import 'package:landfall_shared/landfall_shared.dart';

sealed class DisplaySettingsState {
  const DisplaySettingsState();
}

final class DisplaySettingsLoading extends DisplaySettingsState {
  const DisplaySettingsLoading();
}

final class DisplaySettingsLoaded extends DisplaySettingsState {
  const DisplaySettingsLoaded(this.settings);
  final DisplaySettings settings;
}
