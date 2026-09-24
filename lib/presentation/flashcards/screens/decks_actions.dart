import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/dialogs.dart';
import '../cubit/decks_cubit.dart';
import 'deck_screen.dart';
import 'decks_screen.dart';

/// Action flows for [DecksScreen].
mixin DecksActions on State<DecksScreen> {
  void openDeck(int deckId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => DeckScreen(deckId: deckId)),
    );
  }

  Future<void> createDeck() async {
    final cubit = context.read<DecksCubit>();
    final name = await showTextPrompt(
      context,
      title: 'New deck',
      hint: 'e.g. Estonian vocabulary',
      confirmLabel: 'Create',
    );
    if (name == null) return;
    final id = await cubit.create(name);
    if (mounted) openDeck(id);
  }
}
