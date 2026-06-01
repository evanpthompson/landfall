import 'package:landfall_shared/landfall_shared.dart';
import 'package:timezone/timezone.dart' as tz;

/// Production [ClockRepository] backed by the system clock.
///
/// Emits a new [ClockEntity] every [tick] (1 second in production) using
/// [Stream.periodic]. The stream never completes — it is cancelled when the
/// subscriber (i.e. [ClockCubit]) closes.
///
/// By default the emitted time is device-local ([DateTime.now]). Once the
/// server-configured timezone is known, call [alignTo] with the resolved
/// [tz.Location] and subsequent ticks switch to that zone's wall-clock time —
/// so the clock reads correctly even when the device OS clock is in another
/// zone (most importantly the Pi, whose server container defaults to UTC).
/// The closure reads the active location on every tick, so [alignTo] takes
/// effect on the next emission without resubscribing.
class SystemClockRepository implements ClockRepository {
  SystemClockRepository({
    tz.Location? location,
    DateTime Function()? localNow,
    Duration tick = const Duration(seconds: 1),
  })  : _location = location,
        _localNow = localNow ?? DateTime.now,
        _tick = tick;

  tz.Location? _location;
  final DateTime Function() _localNow;
  final Duration _tick;

  /// Aligns subsequent ticks to [location] (the server-configured zone), or
  /// restores device-local time when [location] is null.
  void alignTo(tz.Location? location) => _location = location;

  @override
  Stream<ClockEntity> clockStream() {
    return Stream.periodic(
      _tick,
      (_) => ClockEntity(_currentTime()),
    ).asBroadcastStream();
  }

  DateTime _currentTime() {
    final location = _location;
    return location == null ? _localNow() : tz.TZDateTime.now(location);
  }
}
