import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/shopping_item.dart';

class ItemEdit {
  const ItemEdit(this.name, this.quantity);

  final String name;
  final String? quantity;
}

/// Name + quantity editor. Returns null on cancel.
Future<ItemEdit?> showItemEditDialog(BuildContext context, ShoppingItem item) {
  return showDialog<ItemEdit>(
    context: context,
    builder: (_) => _ItemEditDialog(item: item),
  );
}

/// Owns its controllers; see _TextPromptDialog in core/widgets/dialogs.dart.
class _ItemEditDialog extends StatefulWidget {
  const _ItemEditDialog({required this.item});

  final ShoppingItem item;

  @override
  State<_ItemEditDialog> createState() => _ItemEditDialogState();
}

class _ItemEditDialogState extends State<_ItemEditDialog> {
  late final _name = TextEditingController(text: widget.item.name);
  late final _quantity = TextEditingController(text: widget.item.quantity);

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final quantity = _quantity.text.trim();
    Navigator.pop(context, ItemEdit(name, quantity.isEmpty ? null : quantity));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: AppConstants.maxShoppingNameLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Item', counterText: ''),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quantity,
            decoration: const InputDecoration(
              hintText: 'Quantity (e.g. 2, 500 g)',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
