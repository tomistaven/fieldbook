import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/database/app_database.dart';
import 'flashcard_repository.dart';

class DeckCardsState {
  const DeckCardsState({this.cards = const [], this.loading = true});

  final List<Flashcard> cards;
  final bool loading;
}

/// Cards of a single deck; created per DeckScreen.
class DeckCardsCubit extends Cubit<DeckCardsState> {
  DeckCardsCubit(this._repository, this.deckId)
      : super(const DeckCardsState()) {
    _subscription = _repository.watchCards(deckId).listen(
          (cards) => emit(DeckCardsState(cards: cards, loading: false)),
        );
  }

  final FlashcardRepository _repository;
  final int deckId;
  late final StreamSubscription<List<Flashcard>> _subscription;

  Future<void> add({required String front, required String back}) =>
      _repository.addCard(deckId, front: front, back: back);

  Future<void> edit(int id, {required String front, required String back}) =>
      _repository.editCard(id, front: front, back: back);

  /// Optimistic removal; see TodoCubit.delete.
  Future<void> delete(Flashcard card) {
    emit(DeckCardsState(
      cards: state.cards.where((c) => c.id != card.id).toList(),
      loading: false,
    ));
    return _repository.deleteCard(card.id);
  }

  Future<void> restore(Flashcard card) => _repository.restoreCard(card);

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
