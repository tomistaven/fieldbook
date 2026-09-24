import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'flashcard_repository.dart';

class DecksState {
  const DecksState({this.decks = const [], this.loading = true});

  final List<DeckSummary> decks;
  final bool loading;

  DeckSummary? byId(int id) {
    for (final d in decks) {
      if (d.id == id) return d;
    }
    return null;
  }
}

class DecksCubit extends Cubit<DecksState> {
  DecksCubit(this._repository) : super(const DecksState()) {
    _subscription = _repository.watchDecks().listen(
          (decks) => emit(DecksState(decks: decks, loading: false)),
        );
  }

  final FlashcardRepository _repository;
  late final StreamSubscription<List<DeckSummary>> _subscription;

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
