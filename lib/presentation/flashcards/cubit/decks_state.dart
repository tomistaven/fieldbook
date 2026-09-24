import 'package:equatable/equatable.dart';

import '../../../domain/entities/flashcard.dart';

class DecksState extends Equatable {
  const DecksState({this.decks = const [], this.loading = true});

  final List<Deck> decks;
  final bool loading;

  Deck? byId(int id) {
    for (final d in decks) {
      if (d.id == id) return d;
    }
    return null;
  }

  @override
  List<Object> get props => [decks, loading];
}
