import '../../domain/entities/flashcard.dart';
import '../datasources/app_database.dart';

/// Maps between Drift [FlashcardRow]s and the [Flashcard] entity.
abstract final class FlashcardModel {
  static Flashcard fromRow(FlashcardRow row) => Flashcard(
    id: row.id,
    deckId: row.deckId,
    front: row.front,
    back: row.back,
    box: row.box,
    lastReviewedAt: row.lastReviewedAt,
    createdAt: row.createdAt,
  );

  static FlashcardRow toRow(Flashcard card) => FlashcardRow(
    id: card.id,
    deckId: card.deckId,
    front: card.front,
    back: card.back,
    box: card.box,
    lastReviewedAt: card.lastReviewedAt,
    createdAt: card.createdAt,
  );
}
