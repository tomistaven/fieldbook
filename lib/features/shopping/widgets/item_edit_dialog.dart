import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';

class ItemEdit {
  const ItemEdit(this.name, this.quantity);

  final String name;
  final String? quantity;
}

/// Name + quantity editor. Returns null on cancel or empty name.
Future<ItemEdit?> showItemEditDialog(
  BuildContext context,
  ShoppingItem item,
) async {
  final name = TextEditingController(text: item.name);
  final quantity = TextEditingController(text: item.quantity);
  final result = await showDialog<ItemEdit>(
    context: context,
    builder: (context) {
      void submit() {
        final n = name.text.trim();
        if (n.isEmpty) return;
        final q = quantity.text.trim();
        Navigator.pop(context, ItemEdit(n, q.isEmpty ? null : q));
      }

      return AlertDialog(
        title: const Text('Edit item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  const InputDecoration(hintText: 'Item', counterText: ''),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantity,
              decoration: const InputDecoration(
                hintText: 'Quantity (e.g. 2, 500 g)',
              ),
              onSubmitted: (_) => submit(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(onPressed: submit, child: const Text('Save')),
        ],
      );
    },
  );
  name.dispose();
  quantity.dispose();
  return result;
}
