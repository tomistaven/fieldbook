import '../entities/flashcard.dart';

/// Contract for persisting flashcard decks and cards.
abstract class FlashcardRepository {
  /// Emits all decks with card and learned counts, newest first.
  Stream<List<Deck>> watchDecks();

  /// Returns the new deck's id.
  Future<int> createDeck(String name);

  Future<void> renameDeck(int id, String name);

  /// Also deletes the deck's cards.
  Future<void> deleteDeck(int id);

  /// Moves every card in the deck back to [Leitner.minBox].
  Future<void> resetProgress(int deckId);

  /// Emits the deck's cards, oldest first, on every change.
  Stream<List<Flashcard>> watchCards(int deckId);

  Future<List<Flashcard>> getCards(int deckId);

  Future<void> addCard(int deckId, {required String front, required String back});

  Future<void> editCard(int id, {required String front, required String back});

  Future<void> deleteCard(int id);

  /// Re-inserts a deleted card with its original id (undo).
  Future<void> restoreCard(Flashcard card);

  /// Applies [Leitner.next] to the card's box and stamps the review time.
  Future<void> recordAnswer(Flashcard card, {required bool knew});
}
