import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:display/src/features/layout/cubit/dashboard_layout_state.dart';

/// Manages the active dashboard layout.
///
/// Responsibilities:
/// - Loading the persisted layout from local storage via [DashboardLayoutRepository]
/// - Saving a modified layout back to local storage
/// - Providing the current layout to the [DisplayScreen]
///
/// On first launch (no saved layout), [getActiveLayout] returns the default
/// layout — this cubit surfaces that default as [DashboardLayoutLoaded].
class DashboardLayoutCubit extends Cubit<DashboardLayoutState> {
  DashboardLayoutCubit(this._repository) : super(const DashboardLayoutLoading());

  final DashboardLayoutRepository _repository;

  /// Loads the active layout from local storage.
  ///
  /// Emits [DashboardLayoutLoading] then [DashboardLayoutLoaded] on success,
  /// or [DashboardLayoutError] if the read fails.
  Future<void> loadLayout() async {
    emit(const DashboardLayoutLoading());
    try {
      final layout = await _repository.getActiveLayout();
      emit(DashboardLayoutLoaded(layout));
    } catch (e) {
      emit(DashboardLayoutError(e.toString()));
    }
  }

  /// Persists [layout] and updates state to [DashboardLayoutLoaded].
  ///
  /// If the save fails, emits [DashboardLayoutError]. The previous [Loaded]
  /// state is not restored — the caller should reload if needed.
  Future<void> saveLayout(DashboardLayout layout) async {
    try {
      await _repository.saveLayout(layout);
      emit(DashboardLayoutLoaded(layout));
    } catch (e) {
      emit(DashboardLayoutError(e.toString()));
    }
  }
}
