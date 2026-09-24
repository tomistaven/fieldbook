import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/flashcard.dart';
import '../../../domain/repositories/flashcard_repository.dart';
import 'study_state.dart';

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
      queue.add(card.withBox(Leitner.next(card.box, knew: false)));
    }

    emit(state.copyWith(
      queue: queue,
      position: state.position + 1,
      revealed: false,
      correctFirstTry: correct,
    ));
  }
}
