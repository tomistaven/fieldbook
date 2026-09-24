import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/delete_swipe_background.dart';
import '../../../domain/entities/shopping_item.dart';

/// Card row. Tap to check off, long-press to edit, swipe left to delete.
class ShoppingTile extends StatelessWidget {
  const ShoppingTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final ShoppingItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final quantity = item.quantity;
    return Dismissible(
      key: ValueKey('shop-${item.id}'),
      direction: DismissDirection.endToStart,
      background: const DeleteSwipeBackground(),
      onDismissed: (_) => onDelete(),
      child: Card(
        child: ListTile(
          onTap: onToggle,
          onLongPress: onEdit,
          leading: Icon(
            item.checked ? Icons.check_circle : Icons.circle_outlined,
            color: item.checked ? AppColors.accent : scheme.onSurfaceVariant,
          ),
          title: Text(
            item.name,
            style: TextStyle(
              decoration: item.checked ? TextDecoration.lineThrough : null,
              color: item.checked ? scheme.onSurfaceVariant : scheme.onSurface,
            ),
          ),
          trailing: (quantity == null || quantity.isEmpty)
              ? null
              : Text(quantity, style: TextStyle(color: scheme.onSurfaceVariant)),
        ),
      ),
    );
  }
}
