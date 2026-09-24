import 'package:flutter/material.dart';

import '../../../core/widgets/delete_swipe_background.dart';
import '../../../domain/entities/flashcard.dart';

/// Card row showing both sides and the Leitner box. Tap to edit, swipe left
/// to delete.
class CardTile extends StatelessWidget {
  const CardTile({
    super.key,
    required this.card,
    required this.onTap,
    required this.onDelete,
  });

  final Flashcard card;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('card-${card.id}'),
      direction: DismissDirection.endToStart,
      background: const DeleteSwipeBackground(),
      onDismissed: (_) => onDelete(),
      child: Card(
        child: ListTile(
          onTap: onTap,
          title: Text(card.front, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            card.back,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: BoxBadge(box: card.box),
        ),
      ),
    );
  }
}

/// Five small bars, filled up to the card's Leitner box.
class BoxBadge extends StatelessWidget {
  const BoxBadge({super.key, required this.box});

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
