/// User-configurable display settings persisted in the local Drift database.
///
/// Defaults are sensible for a home wall display: dim at 10 pm, brighten at
/// 7 am, reduce to 15% brightness during the dim window.
class DisplaySettings {
  const DisplaySettings({
    this.dimEnabled = true,
    this.dimStartHour = 22,
    this.dimEndHour = 7,
    this.dimLevel = 0.85,
    this.locationName = '',
    this.serverUrl = '',
    this.wizardComplete = false,
  });

  /// Whether the scheduled dim mode is active.
  final bool dimEnabled;

  /// Hour (0–23) at which dimming begins.
  final int dimStartHour;

  /// Hour (0–23) at which dimming ends (display brightens).
  final int dimEndHour;

  /// Opacity of the dim overlay (0.0 = transparent, 1.0 = fully black).
  ///
  /// At the default of 0.85 the display is still viewable but noticeably
  /// dimmer — appropriate for a bedroom or living room at night.
  final double dimLevel;

  /// Optional display-name override for the location shown in weather cards.
  ///
  /// Empty string means use the name returned by the weather API.
  final String locationName;

  /// The Serverpod server URL entered during first-run setup.
  ///
  /// Empty string means setup has not been completed. The app shows the
  /// first-run wizard until this is populated and [wizardComplete] is true.
  final String serverUrl;

  /// Whether the first-run setup wizard has been completed.
  ///
  /// Set to true when the user taps "Launch Landfall" at the final wizard step.
  /// Prevents re-showing the wizard after setup even if [serverUrl] changes.
  final bool wizardComplete;

  DisplaySettings copyWith({
    bool? dimEnabled,
    int? dimStartHour,
    int? dimEndHour,
    double? dimLevel,
    String? locationName,
    String? serverUrl,
    bool? wizardComplete,
  }) {
    return DisplaySettings(
      dimEnabled: dimEnabled ?? this.dimEnabled,
      dimStartHour: dimStartHour ?? this.dimStartHour,
      dimEndHour: dimEndHour ?? this.dimEndHour,
      dimLevel: dimLevel ?? this.dimLevel,
      locationName: locationName ?? this.locationName,
      serverUrl: serverUrl ?? this.serverUrl,
      wizardComplete: wizardComplete ?? this.wizardComplete,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DisplaySettings &&
          dimEnabled == other.dimEnabled &&
          dimStartHour == other.dimStartHour &&
          dimEndHour == other.dimEndHour &&
          dimLevel == other.dimLevel &&
          locationName == other.locationName &&
          serverUrl == other.serverUrl &&
          wizardComplete == other.wizardComplete;

  @override
  int get hashCode => Object.hash(
        dimEnabled,
        dimStartHour,
        dimEndHour,
        dimLevel,
        locationName,
        serverUrl,
        wizardComplete,
      );
}
