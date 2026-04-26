import 'package:landfall_shared/src/models/dashboard/dashboard_layout.dart';

/// Abstract interface for dashboard layout persistence.
///
/// Implementations:
/// - [DriftDashboardLayoutRepository] — local-only, stores in SQLite (offline fallback)
/// - [ServerpodLayoutRepository] — production, syncs with server for multi-display
/// - Mock implementations — used in unit and widget tests
abstract interface class DashboardLayoutRepository {
  /// Returns the currently active layout.
  ///
  /// Falls back to [DashboardLayout.defaultLayout()] if no layout is saved.
  Future<DashboardLayout> getActiveLayout();

  /// Persists [layout] and marks it as active.
  Future<void> saveLayout(DashboardLayout layout);

  /// Returns all saved layouts (one per preset type + any custom layouts).
  ///
  /// Returns the three built-in preset defaults if no layouts have been saved yet.
  Future<List<DashboardLayout>> getAllLayouts();

  /// Makes the layout identified by [layoutId] the active one.
  Future<void> setActiveLayout(String layoutId);
}
