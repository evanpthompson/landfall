import 'package:landfall_shared/src/models/card/card.dart';

/// Abstract interface for card data access.
///
/// Implementations:
/// - [ServerpodCardRepository] — production, calls the Serverpod endpoint
/// - Mock implementations — used in unit and widget tests
abstract interface class CardRepository {
  /// Returns all currently active cards, newest first.
  ///
  /// Active = not dismissed AND (persistent OR not yet expired).
  /// Expiry is authoritative on the server — this returns whatever
  /// the server considers active at the time of the call.
  Future<List<Card>> getActiveCards();

  /// Dismisses a card by its [cardId].
  ///
  /// Returns true if the card was found and dismissed.
  /// Returns false if no card with [cardId] exists.
  Future<bool> dismissCard(String cardId);
}
