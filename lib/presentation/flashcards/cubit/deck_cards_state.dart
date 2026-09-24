import 'package:equatable/equatable.dart';

import '../../../domain/entities/flashcard.dart';

class DeckCardsState extends Equatable {
  const DeckCardsState({this.cards = const [], this.loading = true});

  final List<Flashcard> cards;
  final bool loading;

  @override
  List<Object> get props => [cards, loading];
}
