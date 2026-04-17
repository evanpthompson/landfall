import 'package:landfall_shared/src/models/clock/clock_entity.dart';

/// Abstract interface for the clock data source.
///
/// Implementations:
/// - [SystemClockRepository] — production, emits the real system time every second
/// - Mock implementations — used in unit and widget tests
abstract interface class ClockRepository {
  /// Emits a new [ClockEntity] every second.
  ///
  /// The stream does not complete — it ticks until cancelled.
  Stream<ClockEntity> clockStream();
}
