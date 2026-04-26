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
  const DashboardLayoutLoaded(this.layout, {this.allLayouts = const []});

  final DashboardLayout layout;

  /// All saved layouts (one per preset + any custom). Used by the preset switcher.
  final List<DashboardLayout> allLayouts;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardLayoutLoaded &&
          layout == other.layout &&
          allLayouts.length == other.allLayouts.length;

  @override
  int get hashCode => Object.hash(layout, Object.hashAll(allLayouts));
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
