import 'package:landfall_shared/src/models/dashboard/dashboard_layout.dart';

/// Abstract interface for dashboard layout persistence.
///
/// Implementations:
/// - [DriftDashboardLayoutRepository] — production, stores in local SQLite via Drift
/// - Mock implementations — used in unit and widget tests
abstract interface class DashboardLayoutRepository {
  /// Returns the currently saved layout, or [DashboardLayout.defaultLayout()]
  /// if no layout has been saved yet.
  Future<DashboardLayout> getActiveLayout();

  /// Persists [layout] as the active layout.
  Future<void> saveLayout(DashboardLayout layout);
}
