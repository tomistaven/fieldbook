import 'package:equatable/equatable.dart';

/// Leitner boxes: a correct answer moves a card up one box (max 5), a miss
/// sends it back to box 1. Cards in box 3+ (answered correctly at least
/// twice in a row) count as learned.
abstract final class Leitner {
  static const int minBox = 1;
  static const int maxBox = 5;
  static const int learnedFrom = 3;

  static int next(int box, {required bool knew}) =>
      knew ? (box + 1).clamp(minBox, maxBox) : minBox;
}

class Deck extends Equatable {
  const Deck({
    required this.id,
    required this.name,
    required this.cardCount,
    required this.learnedCount,
  });

  final int id;
  final String name;
  final int cardCount;
  final int learnedCount;

  double get learnedRatio => cardCount == 0 ? 0 : learnedCount / cardCount;

  @override
  List<Object?> get props => [id, name, cardCount, learnedCount];
}

class Flashcard extends Equatable {
  const Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.box,
    required this.createdAt,
    this.lastReviewedAt,
  });

  final int id;
  final int deckId;
  final String front;
  final String back;

  /// Leitner box, [Leitner.minBox] to [Leitner.maxBox].
  final int box;
  final DateTime? lastReviewedAt;
  final DateTime createdAt;

  Flashcard withBox(int box) => Flashcard(
    id: id,
    deckId: deckId,
    front: front,
    back: back,
    box: box,
    createdAt: createdAt,
    lastReviewedAt: lastReviewedAt,
  );

  @override
  List<Object?> get props =>
      [id, deckId, front, back, box, lastReviewedAt, createdAt];
}
