import 'package:landfall_shared/landfall_shared.dart';

sealed class DashboardProfileState {
  const DashboardProfileState();
}

final class DashboardProfileLoading extends DashboardProfileState {
  const DashboardProfileLoading();
}

/// Profiles loaded successfully.
final class DashboardProfileLoaded extends DashboardProfileState {
  const DashboardProfileLoaded(this.active, {this.profiles = const []});

  /// The currently active profile.
  final ProfileInfo active;

  /// All profiles, ordered by sort order.
  final List<ProfileInfo> profiles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardProfileLoaded &&
          active == other.active &&
          profiles.length == other.profiles.length;

  @override
  int get hashCode => Object.hash(active, Object.hashAll(profiles));
}

final class DashboardProfileError extends DashboardProfileState {
  const DashboardProfileError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardProfileError && message == other.message;

  @override
  int get hashCode => message.hashCode;
}
