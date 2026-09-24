import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/empty_state.dart';
import '../../settings/widgets/add_button_side.dart';
import '../../settings/widgets/settings_button.dart';
import '../cubit/decks_cubit.dart';
import '../cubit/decks_state.dart';
import '../widgets/deck_tile.dart';
import 'decks_actions.dart';

class DecksScreen extends StatefulWidget {
  const DecksScreen({super.key});

  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> with DecksActions {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: const [SettingsButton()],
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
            itemBuilder: (context, i) {
              final deck = state.decks[i];
              return DeckTile(deck: deck, onTap: () => openDeck(deck.id));
            },
          );
        },
      ),
      floatingActionButtonLocation: context.addButtonLocation,
      floatingActionButton: FloatingActionButton(
        heroTag: 'decks-fab',
        tooltip: 'New deck',
        onPressed: createDeck,
        child: const Icon(Icons.add),
      ),
    );
  }
}