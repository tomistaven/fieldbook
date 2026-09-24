import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';

/// Leitner boxes: a correct answer moves a card up one box (max 5),
/// a miss sends it back to box 1. Cards in box 3+ (answered correctly at
/// least twice in a row) count as learned.
class Leitner {
  Leitner._();

  static const int minBox = 1;
  static const int maxBox = 5;
  static const int learnedFrom = 3;

  static int next(int box, {required bool knew}) =>
      knew ? (box + 1).clamp(minBox, maxBox) : minBox;
}

class DeckSummary {
  const DeckSummary({
    required this.id,
    required this.name,
    required this.cardCount,
    required this.learnedCount,
  });

  final int id;
  final String name;
  final int cardCount;
  final int learnedCount;
}

class FlashcardRepository {
  FlashcardRepository(this._db);

  final AppDatabase _db;

  // ---------- Decks ----------

  Stream<List<DeckSummary>> watchDecks() {
    return _db
        .customSelect(
          'SELECT d.id, d.name, COUNT(f.id) AS card_count, '
          'COALESCE(SUM(CASE WHEN f.box >= ${Leitner.learnedFrom} '
          'THEN 1 ELSE 0 END), 0) AS learned_count '
          'FROM decks d LEFT JOIN flashcards f ON f.deck_id = d.id '
          'GROUP BY d.id ORDER BY d.created_at DESC',
          readsFrom: {_db.decks, _db.flashcards},
        )
        .watch()
        .map((rows) => rows
            .map((r) => DeckSummary(
                  id: r.read<int>('id'),
                  name: r.read<String>('name'),
                  cardCount: r.read<int>('card_count'),
                  learnedCount: r.read<int>('learned_count'),
                ))
            .toList());
  }

  Future<int> createDeck(String name) =>
      _db.into(_db.decks).insert(DecksCompanion.insert(name: name));

  Future<void> renameDeck(int id, String name) {
    return (_db.update(_db.decks)..where((d) => d.id.equals(id)))
        .write(DecksCompanion(name: Value(name)));
  }

  /// Cards are removed by the ON DELETE CASCADE foreign key.
  Future<void> deleteDeck(int id) =>
      (_db.delete(_db.decks)..where((d) => d.id.equals(id))).go();

  Future<void> resetProgress(int deckId) {
    return (_db.update(_db.flashcards)..where((f) => f.deckId.equals(deckId)))
        .write(const FlashcardsCompanion(
      box: Value(Leitner.minBox),
      lastReviewedAt: Value(null),
    ));
  }

  // ---------- Cards ----------

  Stream<List<Flashcard>> watchCards(int deckId) {
    return (_db.select(_db.flashcards)
          ..where((f) => f.deckId.equals(deckId))
          ..orderBy([(f) => OrderingTerm.asc(f.createdAt)]))
        .watch();
  }

  Future<List<Flashcard>> getCards(int deckId) {
    return (_db.select(_db.flashcards)..where((f) => f.deckId.equals(deckId)))
        .get();
  }

  Future<void> addCard(int deckId,
      {required String front, required String back}) {
    return _db.into(_db.flashcards).insert(
          FlashcardsCompanion.insert(deckId: deckId, front: front, back: back),
        );
  }

  Future<void> editCard(int id, {required String front, required String back}) {
    return (_db.update(_db.flashcards)..where((f) => f.id.equals(id))).write(
      FlashcardsCompanion(front: Value(front), back: Value(back)),
    );
  }

  Future<void> deleteCard(int id) =>
      (_db.delete(_db.flashcards)..where((f) => f.id.equals(id))).go();

  Future<void> restoreCard(Flashcard card) =>
      _db.into(_db.flashcards).insert(card);

  Future<void> recordAnswer(Flashcard card, {required bool knew}) {
    return (_db.update(_db.flashcards)..where((f) => f.id.equals(card.id)))
        .write(FlashcardsCompanion(
      box: Value(Leitner.next(card.box, knew: knew)),
      lastReviewedAt: Value(DateTime.now()),
    ));
  }
}
