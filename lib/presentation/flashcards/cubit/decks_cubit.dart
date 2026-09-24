import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/flashcard.dart';
import '../../../domain/repositories/flashcard_repository.dart';
import 'decks_state.dart';

class DecksCubit extends Cubit<DecksState> {
  DecksCubit(this._repository) : super(const DecksState()) {
    _subscription = _repository.watchDecks().listen(
          (decks) => emit(DecksState(decks: decks, loading: false)),
        );
  }

  final FlashcardRepository _repository;
  late final StreamSubscription<List<Deck>> _subscription;

  Future<int> create(String name) => _repository.createDeck(name);

  Future<void> rename(int id, String name) => _repository.renameDeck(id, name);

  Future<void> delete(int id) => _repository.deleteDeck(id);

  Future<void> resetProgress(int id) => _repository.resetProgress(id);

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
