import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';

/// Tap to check off, long-press to edit, swipe left to delete.
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
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: AppColors.danger,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        onTap: onToggle,
        onLongPress: onEdit,
        leading: Icon(
          item.checked ? Icons.check_box : Icons.check_box_outline_blank,
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
            : Text(
                quantity,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
      ),
    );
  }
}
