import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/dialogs.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/theme_toggle_button.dart';
import 'deck_screen.dart';
import 'decks_cubit.dart';
import 'flashcard_repository.dart';

class DecksScreen extends StatelessWidget {
  const DecksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: const [ThemeToggleButton()],
      ),
      body: BlocBuilder<DecksCubit, DecksState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.decks.isEmpty) {
            return const EmptyState(
              icon: Icons.style_outlined,
              message: 'No decks yet. Tap + to create one.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 88),
            itemCount: state.decks.length,
            itemBuilder: (context, i) => _DeckTile(deck: state.decks[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'decks-fab',
        tooltip: 'New deck',
        onPressed: () => _create(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final cubit = context.read<DecksCubit>();
    final name = await showTextPrompt(
      context,
      title: 'New deck',
      hint: 'e.g. Estonian vocabulary',
      confirmLabel: 'Create',
    );
    if (name == null) return;
    final id = await cubit.create(name);
    if (context.mounted) openDeck(context, id);
  }
}

void openDeck(BuildContext context, int deckId) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => DeckScreen(deckId: deckId)),
  );
}

class _DeckTile extends StatelessWidget {
  const _DeckTile({required this.deck});

  final DeckSummary deck;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = deck.cardCount == 0 ? 0.0 : deck.learnedCount / deck.cardCount;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openDeck(context, deck.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deck.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '${deck.cardCount} cards · ${deck.learnedCount} learned',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: scheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
