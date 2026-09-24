import 'package:drift/drift.dart';

import '../../domain/entities/flashcard.dart';
import '../../domain/repositories/flashcard_repository.dart';
import '../datasources/app_database.dart';
import '../models/flashcard_model.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  const FlashcardRepositoryImpl(this._db);

  final AppDatabase _db;

  // ---------- Decks ----------

  @override
  Stream<List<Deck>> watchDecks() {
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
        .map(
          (rows) => rows
              .map(
                (r) => Deck(
                  id: r.read<int>('id'),
                  name: r.read<String>('name'),
                  cardCount: r.read<int>('card_count'),
                  learnedCount: r.read<int>('learned_count'),
                ),
              )
              .toList(),
        );
  }

  @override
  Future<int> createDeck(String name) =>
      _db.into(_db.decks).insert(DecksCompanion.insert(name: name));

  @override
  Future<void> renameDeck(int id, String name) {
    return (_db.update(_db.decks)..where((d) => d.id.equals(id))).write(
      DecksCompanion(name: Value(name)),
    );
  }

  /// Cards are removed by the ON DELETE CASCADE foreign key.
  @override
  Future<void> deleteDeck(int id) =>
      (_db.delete(_db.decks)..where((d) => d.id.equals(id))).go();

  @override
  Future<void> resetProgress(int deckId) {
    return (_db.update(
      _db.flashcards,
    )..where((f) => f.deckId.equals(deckId))).write(
      const FlashcardsCompanion(
        box: Value(Leitner.minBox),
        lastReviewedAt: Value(null),
      ),
    );
  }

  // ---------- Cards ----------

  @override
  Stream<List<Flashcard>> watchCards(int deckId) {
    return (_db.select(_db.flashcards)
          ..where((f) => f.deckId.equals(deckId))
          ..orderBy([(f) => OrderingTerm.asc(f.createdAt)]))
        .watch()
        .map((rows) => rows.map(FlashcardModel.fromRow).toList());
  }

  @override
  Future<List<Flashcard>> getCards(int deckId) async {
    final rows = await (_db.select(
      _db.flashcards,
    )..where((f) => f.deckId.equals(deckId))).get();
    return rows.map(FlashcardModel.fromRow).toList();
  }

  @override
  Future<void> addCard(
    int deckId, {
    required String front,
    required String back,
  }) {
    return _db
        .into(_db.flashcards)
        .insert(
          FlashcardsCompanion.insert(deckId: deckId, front: front, back: back),
        );
  }

  @override
  Future<void> editCard(int id, {required String front, required String back}) {
    return (_db.update(_db.flashcards)..where((f) => f.id.equals(id))).write(
      FlashcardsCompanion(front: Value(front), back: Value(back)),
    );
  }

  @override
  Future<void> deleteCard(int id) =>
      (_db.delete(_db.flashcards)..where((f) => f.id.equals(id))).go();

  @override
  Future<void> restoreCard(Flashcard card) =>
      _db.into(_db.flashcards).insert(FlashcardModel.toRow(card));

  @override
  Future<void> recordAnswer(Flashcard card, {required bool knew}) {
    return (_db.update(_db.flashcards)..where((f) => f.id.equals(card.id)))
        .write(
          FlashcardsCompanion(
            box: Value(Leitner.next(card.box, knew: knew)),
            lastReviewedAt: Value(DateTime.now()),
          ),
        );
  }
}
