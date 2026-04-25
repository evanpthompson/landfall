import 'package:landfall_shared/src/models/settings/display_settings.dart';

export 'package:landfall_shared/src/models/settings/display_settings.dart';

abstract class DisplaySettingsRepository {
  /// Returns the current display settings, or defaults if never saved.
  Future<DisplaySettings> getSettings();

  /// Persists [settings], replacing any previously saved value.
  Future<void> saveSettings(DisplaySettings settings);
}
