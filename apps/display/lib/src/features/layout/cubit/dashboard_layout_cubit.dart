import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';
import 'package:display/src/features/layout/cubit/dashboard_layout_state.dart';

/// Manages dashboard layouts and the active preset selection.
///
/// Responsibilities:
/// - Loading and persisting layouts via [DashboardLayoutRepository]
/// - Surfacing all preset layouts to the Settings preset switcher
/// - Switching the active preset
class DashboardLayoutCubit extends Cubit<DashboardLayoutState> {
  DashboardLayoutCubit(this._repository) : super(const DashboardLayoutLoading());

  final DashboardLayoutRepository _repository;

  /// Loads the active layout.
  Future<void> loadLayout() async {
    emit(const DashboardLayoutLoading());
    try {
      final layout = await _repository.getActiveLayout();
      final all = await _repository.getAllLayouts();
      emit(DashboardLayoutLoaded(layout, allLayouts: all));
    } catch (e) {
      emit(DashboardLayoutError(e.toString()));
    }
  }

  /// Persists [layout] and refreshes state.
  Future<void> saveLayout(DashboardLayout layout) async {
    try {
      await _repository.saveLayout(layout);
      final all = await _repository.getAllLayouts();
      emit(DashboardLayoutLoaded(layout, allLayouts: all));
    } catch (e) {
      emit(DashboardLayoutError(e.toString()));
    }
  }

  /// Resets the active layout back to its canonical preset defaults,
  /// discarding any user customisations.
  Future<void> resetCurrentPreset() async {
    final current = state;
    if (current is! DashboardLayoutLoaded) return;
    final canonical = DashboardLayout.forPreset(current.layout.presetType);
    await saveLayout(canonical);
  }

  /// Switches to the layout for [preset], loading its saved version or
  /// the built-in default if it has not been customised yet.
  Future<void> switchPreset(LayoutPresetType preset) async {
    final current = state;
    final allLayouts = current is DashboardLayoutLoaded
        ? current.allLayouts
        : await _repository.getAllLayouts();

    final target = allLayouts.firstWhere(
      (l) => l.presetType == preset,
      orElse: () => DashboardLayout.forPreset(preset),
    );

    try {
      await _repository.setActiveLayout(target.id);
      final refreshed = await _repository.getActiveLayout();
      final all = await _repository.getAllLayouts();
      emit(DashboardLayoutLoaded(refreshed, allLayouts: all));
    } catch (e) {
      emit(DashboardLayoutError(e.toString()));
    }
  }
}
