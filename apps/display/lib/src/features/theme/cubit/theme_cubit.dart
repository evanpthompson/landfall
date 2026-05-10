import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'theme_state.dart';

/// Manages the available themes and which one is currently active.
///
/// Responsibilities:
/// - Loading all themes from the server and surfacing the active one
/// - Applying a theme (linking it to a profile or globally)
/// - Providing the theme list for [ThemeBrowserScreen]
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit(this._repository, {DashboardProfileRepository? profileRepository})
    : _profileRepository = profileRepository,
      super(const ThemeInitial());

  final ThemeRepository _repository;
  final DashboardProfileRepository? _profileRepository;

  /// Loads all available themes.
  ///
  /// The active theme defaults to `default-dark` if present, otherwise the
  /// first theme in the list.
  Future<void> loadThemes() async {
    emit(const ThemeLoading());
    try {
      final themes = await _repository.listThemes();
      final activeSlug = await _activeProfileThemeSlug();
      final active = themes.firstWhere(
        (t) => t.slug == activeSlug,
        orElse: () {
          return themes.firstWhere(
            (t) => t.slug == 'default-dark',
            orElse: () => themes.first,
          );
        },
      );
      emit(ThemeLoaded(active, themes: themes));
    } catch (e) {
      emit(ThemeError(e.toString()));
    }
  }

  /// Applies the theme identified by [themeId], optionally scoped to
  /// [profileId].
  ///
  /// Reloads the theme list after applying so [ThemeLoaded.active] reflects the
  /// change. Does nothing when the current state is not [ThemeLoaded].
  Future<void> applyTheme(int themeId, {int? profileId}) async {
    if (state is! ThemeLoaded) return;
    try {
      final resolvedProfileId = profileId ?? await _activeProfileId();
      await _repository.applyTheme(themeId, profileId: resolvedProfileId);
      final themes = await _repository.listThemes();
      final active = themes.firstWhere(
        (t) => t.id == themeId,
        orElse: () => themes.first,
      );
      emit(ThemeLoaded(active, themes: themes));
    } catch (e) {
      emit(ThemeError(e.toString()));
    }
  }

  Future<String?> _activeProfileThemeSlug() async {
    final active = await _profileRepository?.getActiveProfile();
    return active?.companionThemeSlug;
  }

  Future<int?> _activeProfileId() async {
    final active = await _profileRepository?.getActiveProfile();
    return active?.id;
  }
}
