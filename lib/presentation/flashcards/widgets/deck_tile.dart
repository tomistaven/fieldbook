import 'package:flutter/material.dart';

import '../../../domain/entities/flashcard.dart';

/// Deck card with name, counts and a learned-progress bar.
class DeckTile extends StatelessWidget {
  const DeckTile({super.key, required this.deck, required this.onTap});

  final Deck deck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(deck.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '${deck.cardCount} cards · ${deck.learnedCount} learned',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: deck.learnedRatio,
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
