import 'package:landfall_shared/landfall_shared.dart';

sealed class ThemeState {
  const ThemeState();
}

final class ThemeInitial extends ThemeState {
  const ThemeInitial();
}

final class ThemeLoading extends ThemeState {
  const ThemeLoading();
}

final class ThemeLoaded extends ThemeState {
  const ThemeLoaded(this.active, {this.themes = const []});

  /// The currently applied/selected theme.
  final ThemeInfo active;

  /// All available themes (built-in + imported), ordered by name.
  final List<ThemeInfo> themes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeLoaded &&
          active == other.active &&
          themes.length == other.themes.length;

  @override
  int get hashCode => Object.hash(active, Object.hashAll(themes));
}

final class ThemeError extends ThemeState {
  const ThemeError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeError && message == other.message;

  @override
  int get hashCode => message.hashCode;
}
