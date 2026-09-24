import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/database/app_database.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/empty_state.dart';
import 'deck_cards_cubit.dart';
import 'decks_cubit.dart';
import 'flashcard_repository.dart';
import 'study_screen.dart';
import 'widgets/card_editor_sheet.dart';

class DeckScreen extends StatelessWidget {
  const DeckScreen({super.key, required this.deckId});

  final int deckId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DeckCardsCubit(context.read<FlashcardRepository>(), deckId),
      child: BlocBuilder<DecksCubit, DecksState>(
        builder: (context, decksState) {
          final deck = decksState.byId(deckId);
          // Deck was deleted; the pop is already under way.
          if (deck == null) return const Scaffold();
          return _DeckView(deck: deck);
        },
      ),
    );
  }
}

class _DeckView extends StatelessWidget {
  const _DeckView({required this.deck});

  final DeckSummary deck;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(deck.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => _onMenu(context, v),
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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StudyScreen(
                                    deckId: deck.id,
                                    deckName: deck.name,
                                  ),
                                ),
                              ),
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
                        itemBuilder: (context, i) =>
                            _CardTile(card: state.cards[i]),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'deck-fab',
        tooltip: 'New card',
        onPressed: () {
          final cubit = context.read<DeckCardsCubit>();
          showCardEditor(
            context,
            onSave: (front, back) => cubit.add(front: front, back: back),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _onMenu(BuildContext context, String value) async {
    final decks = context.read<DecksCubit>();
    switch (value) {
      case 'rename':
        final name = await showTextPrompt(
          context,
          title: 'Rename deck',
          initialValue: deck.name,
        );
        if (name != null) await decks.rename(deck.id, name);
      case 'reset':
        final ok = await showConfirmDialog(
          context,
          title: 'Reset progress?',
          message: 'All cards in "${deck.name}" go back to unlearned.',
          confirmLabel: 'Reset',
        );
        if (ok) await decks.resetProgress(deck.id);
      case 'delete':
        final ok = await showConfirmDialog(
          context,
          title: 'Delete deck?',
          message: '"${deck.name}" and its ${deck.cardCount} cards will be '
              'deleted permanently.',
        );
        if (!ok || !context.mounted) return;
        Navigator.of(context).pop();
        await decks.delete(deck.id);
    }
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card});

  final Flashcard card;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DeckCardsCubit>();
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey('card-${card.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: scheme.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        cubit.delete(card);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: const Text('Card deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => cubit.restore(card),
            ),
          ));
      },
      child: ListTile(
        title: Text(card.front, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle:
            Text(card.back, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: _BoxBadge(box: card.box),
        onTap: () => showCardEditor(
          context,
          existing: card,
          onSave: (front, back) =>
              cubit.edit(card.id, front: front, back: back),
        ),
      ),
    );
  }
}

/// Five small bars; filled up to the card's Leitner box.
class _BoxBadge extends StatelessWidget {
  const _BoxBadge({required this.box});

  final int box;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Box $box of ${Leitner.maxBox}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= Leitner.maxBox; i++)
            Container(
              width: 4,
              height: 6.0 + i * 2,
              margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(
                color: i <= box ? scheme.primary : scheme.outline,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }
}
