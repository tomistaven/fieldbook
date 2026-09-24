import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/database/app_database.dart';
import 'flashcard_repository.dart';

class StudyState extends Equatable {
  const StudyState({
    this.queue = const [],
    this.position = 0,
    this.revealed = false,
    this.total = 0,
    this.correctFirstTry = 0,
    this.loading = true,
  });

  /// Cards still to show; missed cards are appended to the end.
  final List<Flashcard> queue;
  final int position;
  final bool revealed;

  /// Number of distinct cards in the session.
  final int total;
  final int correctFirstTry;
  final bool loading;

  bool get finished => !loading && position >= queue.length;
  Flashcard? get current => finished || loading ? null : queue[position];

  StudyState copyWith({
    List<Flashcard>? queue,
    int? position,
    bool? revealed,
    int? total,
    int? correctFirstTry,
    bool? loading,
  }) {
    return StudyState(
      queue: queue ?? this.queue,
      position: position ?? this.position,
      revealed: revealed ?? this.revealed,
      total: total ?? this.total,
      correctFirstTry: correctFirstTry ?? this.correctFirstTry,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props =>
      [queue, position, revealed, total, correctFirstTry, loading];
}

/// One pass through a deck. Weakest cards (lowest Leitner box) come first,
/// shuffled within each box. Missed cards come back at the end of the pass.
class StudyCubit extends Cubit<StudyState> {
  StudyCubit(this._repository, this.deckId) : super(const StudyState()) {
    start();
  }

  final FlashcardRepository _repository;
  final int deckId;
  final Set<int> _answered = {};

  Future<void> start() async {
    emit(const StudyState());
    _answered.clear();
    final cards = await _repository.getCards(deckId);

    final byBox = <int, List<Flashcard>>{};
    for (final c in cards) {
      byBox.putIfAbsent(c.box, () => []).add(c);
    }
    final ordered = <Flashcard>[];
    for (final box in byBox.keys.toList()..sort()) {
      ordered.addAll(byBox[box]!..shuffle());
    }

    if (isClosed) return;
    emit(StudyState(queue: ordered, total: ordered.length, loading: false));
  }

  void reveal() {
    if (state.current == null) return;
    emit(state.copyWith(revealed: true));
  }

  void answer({required bool knew}) {
    final card = state.current;
    if (card == null) return;

    _repository.recordAnswer(card, knew: knew);

    var correct = state.correctFirstTry;
    if (_answered.add(card.id) && knew) correct++;

    final queue = List.of(state.queue);
    if (!knew) {
      queue.add(card.copyWith(box: Leitner.next(card.box, knew: false)));
    }

    emit(state.copyWith(
      queue: queue,
      position: state.position + 1,
      revealed: false,
      correctFirstTry: correct,
    ));
  }
}
