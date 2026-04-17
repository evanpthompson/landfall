import 'package:landfall_shared/landfall_shared.dart';

/// States for [ClockCubit].
sealed class ClockState {
  const ClockState();
}

/// Initial state — clock has not yet started ticking.
final class ClockInitial extends ClockState {
  const ClockInitial();
}

/// The clock is ticking and [entity] holds the current time.
final class ClockTicking extends ClockState {
  const ClockTicking(this.entity);

  final ClockEntity entity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClockTicking && entity == other.entity;

  @override
  int get hashCode => entity.hashCode;
}
