import 'package:landfall_shared/src/models/theme/theme_info.dart';

/// Abstract interface for theme persistence and application.
///
/// Implementations:
/// - [ServerpodThemeRepository] — production, backed by [ThemeEndpoint]
abstract interface class ThemeRepository {
  /// Returns all themes available on this display (built-in + imported),
  /// ordered by name.
  Future<List<ThemeInfo>> listThemes();

  /// Validates and stores [yaml] (YAML or JSON theme definition).
  ///
  /// Returns the stored [ThemeInfo] on success. Throws on validation failure.
  Future<ThemeInfo> uploadTheme(String yaml);

  /// Fetches a theme from the HTTPS [url], validates, and stores it.
  ///
  /// Returns the stored [ThemeInfo] on success. Throws on fetch or validation
  /// failure.
  Future<ThemeInfo> importTheme(String url);

  /// Links the theme identified by [themeId] to [profileId].
  ///
  /// When [profileId] is null, the call is a no-op at the profile level
  /// (placeholder for a future global theme preference).
  ///
  /// Throws [StateError] when [themeId] does not exist.
  Future<void> applyTheme(int themeId, {int? profileId});

  /// Deletes the theme identified by [id].
  ///
  /// Throws when attempting to delete a built-in theme.
  Future<void> deleteTheme(int id);
}
