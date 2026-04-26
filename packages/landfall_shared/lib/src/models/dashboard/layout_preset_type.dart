/// The preset category for a [DashboardLayout].
///
/// Each preset starts from a different default card arrangement. Once
/// customised, the preset type remains set so the Settings UI can group
/// layouts by their original purpose.
enum LayoutPresetType {
  /// Work-day focus — clock, weather, forecast, calendar.
  weekday,

  /// Leisure / weekend — clock, photos, calendar.
  weekend,

  /// Minimal night-stand mode — clock only.
  night,

  /// User-defined layout that does not map to a built-in preset.
  custom;

  /// Human-readable label shown in the Settings preset switcher.
  String get label => switch (this) {
        LayoutPresetType.weekday => 'Weekday',
        LayoutPresetType.weekend => 'Weekend',
        LayoutPresetType.night => 'Night',
        LayoutPresetType.custom => 'Custom',
      };
}
