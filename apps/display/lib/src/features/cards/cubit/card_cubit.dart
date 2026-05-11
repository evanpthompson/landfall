import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:landfall_shared/landfall_shared.dart';

import 'package:display/src/features/companion/companion_event_bus.dart';
import 'package:display/src/features/cards/cubit/card_state.dart';

/// Manages the active card set displayed on the board.
///
/// Responsibilities:
/// - Fetching active cards from the server via [CardRepository]
/// - Dismissing cards on user action
/// - Reflecting loading, loaded, and error states
///
/// The display refresh cadence (periodic re-fetch) is driven externally —
/// the caller invokes [fetchCards] on each refresh cycle.
class CardCubit extends Cubit<CardState> {
  CardCubit(this._repository, {CompanionEventBus? bus})
      : _bus = bus,
        super(const CardLoading());

  final CardRepository _repository;
  final CompanionEventBus? _bus;

  Set<String> _seenIds = {};

  /// Fetches the current active card set from the server.
  ///
  /// Emits [CardLoading] then [CardLoaded] on success,
  /// or [CardError] if the fetch fails.
  Future<void> fetchCards() async {
    emit(const CardLoading());
    try {
      final cards = await _repository.getActiveCards();
      _emitBusTriggers(cards);
      _seenIds = cards.map((c) => c.id).toSet();
      emit(CardLoaded(cards));
    } catch (e) {
      emit(CardError(e.toString()));
    }
  }

  void _emitBusTriggers(List<Card> cards) {
    final bus = _bus;
    if (bus == null) return;
    for (final card in cards) {
      if (_seenIds.contains(card.id)) continue;
      if (card.priority == CardPriority.ephemeral) {
        bus.emit(CompanionTrigger.cardUrgentArrived);
      } else if (card.persistent) {
        bus.emit(CompanionTrigger.cardCelebratoryArrived);
      }
    }
  }

  /// Dismisses the card with the given [cardId].
  ///
  /// Optimistically removes the card from the current [CardLoaded] state
  /// before the server call completes. If the server call fails, re-fetches
  /// to restore consistent state.
  Future<void> dismissCard(String cardId) async {
    final current = state;
    if (current is CardLoaded) {
      final updated = current.cards.where((c) => c.id != cardId).toList();
      emit(CardLoaded(updated));
    }

    try {
      await _repository.dismissCard(cardId);
    } catch (_) {
      await fetchCards();
    }
  }
}
