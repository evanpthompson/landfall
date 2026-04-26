import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'ticker_state.dart';

export 'ticker_state.dart';

/// Manages the ghost ticker strip buffer.
///
/// The caller refreshes the buffer on a short interval (e.g. every 15 seconds)
/// by calling [loadTicker]. The display subscribes via BlocBuilder.
class TickerCubit extends Cubit<TickerState> {
  TickerCubit(this._repository) : super(const TickerEmpty());

  final CardRepository _repository;

  /// Fetches the current ticker buffer from the server.
  ///
  /// Emits [TickerLoaded] when there are active messages,
  /// [TickerEmpty] when the buffer is empty or the fetch fails.
  Future<void> loadTicker() async {
    try {
      final messages = await _repository.getTickerMessages();
      if (messages.isEmpty) {
        emit(const TickerEmpty());
      } else {
        emit(TickerLoaded(messages));
      }
    } catch (_) {
      emit(const TickerEmpty());
    }
  }
}
