import 'package:landfall_shared/landfall_shared.dart';

/// Use case: retrieve a continuous stream of the current time.
///
/// Encapsulates [ClockRepository] behind the domain boundary so that
/// [ClockCubit] does not depend directly on the data layer.
class GetCurrentTimeUseCase {
  const GetCurrentTimeUseCase(this._repository);

  final ClockRepository _repository;

  /// Returns a stream that emits a new [ClockEntity] every second.
  Stream<ClockEntity> call() => _repository.clockStream();
}
