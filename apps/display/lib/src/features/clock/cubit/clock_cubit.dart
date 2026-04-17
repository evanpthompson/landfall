import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/domain/use_cases/get_current_time_use_case.dart';
import 'package:display/src/features/clock/cubit/clock_state.dart';

/// Drives the clock widget by subscribing to a 1-second tick stream.
///
/// Call [startTicking] once from [DisplayScreen.initState] to begin.
/// The cubit holds the stream subscription and cancels it on [close].
class ClockCubit extends Cubit<ClockState> {
  ClockCubit(this._getCurrentTime) : super(const ClockInitial());

  final GetCurrentTimeUseCase _getCurrentTime;
  StreamSubscription<ClockEntity>? _subscription;

  /// Subscribes to the clock stream and emits [ClockTicking] on each tick.
  ///
  /// If [startTicking] was called previously, the existing subscription is
  /// cancelled before a new one is created.
  Future<void> startTicking() async {
    await _subscription?.cancel();
    _subscription = _getCurrentTime().listen(
      (entity) => emit(ClockTicking(entity)),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
