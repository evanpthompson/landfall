import 'package:landfall_shared/landfall_shared.dart';

/// States for [CardCubit].
sealed class CardState {
  const CardState();
}

/// Initial state while cards are being loaded from the server.
final class CardLoading extends CardState {
  const CardLoading();
}

/// Cards have loaded successfully.
final class CardLoaded extends CardState {
  const CardLoaded(this.cards);

  final List<Card> cards;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardLoaded &&
          cards.length == other.cards.length &&
          List.generate(cards.length, (i) => cards[i] == other.cards[i])
              .every((e) => e);

  @override
  int get hashCode => Object.hashAll(cards);
}

/// An error occurred while loading or managing cards.
final class CardError extends CardState {
  const CardError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardError && message == other.message;

  @override
  int get hashCode => message.hashCode;
}
