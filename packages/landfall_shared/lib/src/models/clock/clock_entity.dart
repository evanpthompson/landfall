/// A snapshot of the current time, used by [ClockCubit] and [ClockCard].
///
/// The clock domain is intentionally thin — this entity exists so that
/// the clock widget stack is testable without depending on [DateTime.now()]
/// directly.
class ClockEntity {
  const ClockEntity(this.now);

  /// The current time at the moment this entity was created.
  final DateTime now;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ClockEntity && now == other.now;

  @override
  int get hashCode => now.hashCode;

  @override
  String toString() {
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    return 'ClockEntity($h:$m:$s)';
  }
}
