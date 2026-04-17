import 'package:landfall_shared/landfall_shared.dart';

/// Production [ClockRepository] backed by the system clock.
///
/// Emits a new [ClockEntity] every second using [Stream.periodic].
/// The stream never completes — it is cancelled when the subscriber
/// (i.e. [ClockCubit]) closes.
class SystemClockRepository implements ClockRepository {
  const SystemClockRepository();

  @override
  Stream<ClockEntity> clockStream() {
    return Stream.periodic(
      const Duration(seconds: 1),
      (_) => ClockEntity(DateTime.now()),
    ).asBroadcastStream();
  }
}
