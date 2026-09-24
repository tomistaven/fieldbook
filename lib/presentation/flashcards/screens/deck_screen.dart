import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../domain/entities/flashcard.dart';
import '../../../domain/repositories/flashcard_repository.dart';
import '../../../injection_container.dart';
import '../../settings/widgets/add_button_side.dart';
import '../cubit/deck_cards_cubit.dart';
import '../cubit/deck_cards_state.dart';
import '../cubit/decks_cubit.dart';
import '../cubit/decks_state.dart';
import '../widgets/card_tile.dart';
import 'deck_actions.dart';

class DeckScreen extends StatefulWidget {
  const DeckScreen({super.key, required this.deckId});

  final int deckId;

  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> with DeckActions {
  // Screen-scoped: created and closed with this screen.
  @override
  late final DeckCardsCubit cardsCubit = DeckCardsCubit(
    sl<FlashcardRepository>(),
    widget.deckId,
  );

  @override
  void dispose() {
    cardsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read here, not in _buildDeck: that runs inside the BlocBuilder below,
    // where this State's context is not the one being built.
    final fabLocation = context.addButtonLocation;
    return BlocProvider.value(
      value: cardsCubit,
      child: BlocBuilder<DecksCubit, DecksState>(
        builder: (context, decksState) {
          final deck = decksState.byId(widget.deckId);
          // Deck was deleted; the pop is already under way.
          if (deck == null) return const Scaffold();
          return _buildDeck(deck, fabLocation);
        },
      ),
    );
  }

  Widget _buildDeck(Deck deck, FloatingActionButtonLocation fabLocation) {
    return Scaffold(
      appBar: AppBar(
        title: Text(deck.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => switch (value) {
              'rename' => renameDeck(deck),
              'reset' => resetProgress(deck),
              'delete' => deleteDeck(deck),
              _ => null,
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename deck')),
              PopupMenuItem(value: 'reset', child: Text('Reset progress')),
              PopupMenuItem(value: 'delete', child: Text('Delete deck')),
            ],
          ),
        ],
      ),
      body: BlocBuilder<DeckCardsCubit, DeckCardsState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${deck.cardCount} cards · ${deck.learnedCount} learned',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: state.cards.isEmpty
                          ? null
                          : () => startStudy(deck),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Study'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: state.cards.isEmpty
                    ? const EmptyState(
                        icon: Icons.note_add_outlined,
                        message: 'No cards yet. Tap + to add some.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: state.cards.length,
                        itemBuilder: (context, i) {
                          final card = state.cards[i];
                          return CardTile(
                            card: card,
                            onTap: () => editCard(card),
                            onDelete: () => deleteCard(card),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: fabLocation,
      floatingActionButton: FloatingActionButton(
        heroTag: 'deck-fab',
        tooltip: 'New card',
        onPressed: addCards,
        child: const Icon(Icons.add),
      ),
    );
  }
}