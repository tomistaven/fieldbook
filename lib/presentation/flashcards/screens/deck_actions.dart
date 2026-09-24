import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/dialogs.dart';
import '../../../domain/entities/flashcard.dart';
import '../cubit/deck_cards_cubit.dart';
import '../cubit/decks_cubit.dart';
import '../widgets/card_editor_sheet.dart';
import 'deck_screen.dart';
import 'study_screen.dart';

/// Action flows for [DeckScreen]. The screen owns the screen-scoped
/// [DeckCardsCubit] and exposes it through [cardsCubit].
mixin DeckActions on State<DeckScreen> {
  DeckCardsCubit get cardsCubit;

  void startStudy(Deck deck) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudyScreen(deckId: deck.id, deckName: deck.name),
      ),
    );
  }

  void addCards() {
    final cubit = cardsCubit;
    showCardEditor(
      context,
      onSave: (front, back) => cubit.add(front: front, back: back),
    );
  }

  void editCard(Flashcard card) {
    final cubit = cardsCubit;
    showCardEditor(
      context,
      existing: card,
      onSave: (front, back) => cubit.edit(card.id, front: front, back: back),
    );
  }

  void deleteCard(Flashcard card) {
    final cubit = cardsCubit;
    cubit.delete(card);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Card deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => cubit.restore(card),
          ),
        ),
      );
  }

  Future<void> renameDeck(Deck deck) async {
    final decks = context.read<DecksCubit>();
    final name = await showTextPrompt(
      context,
      title: 'Rename deck',
      initialValue: deck.name,
    );
    if (name != null) await decks.rename(deck.id, name);
  }

  Future<void> resetProgress(Deck deck) async {
    final decks = context.read<DecksCubit>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reset progress?',
      message: 'All cards in "${deck.name}" go back to unlearned.',
      confirmLabel: 'Reset',
    );
    if (confirmed) await decks.resetProgress(deck.id);
  }

  Future<void> deleteDeck(Deck deck) async {
    final decks = context.read<DecksCubit>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete deck?',
      message:
          '"${deck.name}" and its ${deck.cardCount} cards will be deleted '
          'permanently.',
    );
    if (!confirmed || !mounted) return;
    Navigator.of(context).pop();
    await decks.delete(deck.id);
  }
}
