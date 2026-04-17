import 'package:landfall_shared/landfall_shared.dart';

/// States for [DashboardLayoutCubit].
sealed class DashboardLayoutState {
  const DashboardLayoutState();
}

/// Initial state while the layout is being loaded from local storage.
final class DashboardLayoutLoading extends DashboardLayoutState {
  const DashboardLayoutLoading();
}

/// The layout has loaded successfully.
final class DashboardLayoutLoaded extends DashboardLayoutState {
  const DashboardLayoutLoaded(this.layout);

  final DashboardLayout layout;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardLayoutLoaded && layout == other.layout;

  @override
  int get hashCode => layout.hashCode;
}

/// An error occurred while loading or saving the layout.
final class DashboardLayoutError extends DashboardLayoutState {
  const DashboardLayoutError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardLayoutError && message == other.message;

  @override
  int get hashCode => message.hashCode;
}
