import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/database/app_database.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/theme_toggle_button.dart';
import 'shopping_cubit.dart';
import 'widgets/item_edit_dialog.dart';
import 'widgets/shopping_tile.dart';

class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping'),
        actions: [
          const ThemeToggleButton(),
          PopupMenuButton<String>(
            onSelected: (value) => switch (value) {
              'clear' => _clearChecked(context),
              'all' => _deleteAll(context),
              _ => null,
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'clear', child: Text('Clear checked')),
              PopupMenuItem(value: 'all', child: Text('Delete all')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ShoppingCubit, ShoppingState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.shopping_basket_outlined,
                    message: 'List is empty. Add items below.',
                  );
                }
                final toBuy = state.toBuy;
                final inCart = state.inCart;
                return ListView(
                  children: [
                    for (final item in toBuy) _tile(context, item),
                    if (inCart.isNotEmpty) ...[
                      _SectionHeader('In cart (${inCart.length})'),
                      for (final item in inCart) _tile(context, item),
                    ],
                  ],
                );
              },
            ),
          ),
          const _QuickAddBar(),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, ShoppingItem item) {
    final cubit = context.read<ShoppingCubit>();
    return ShoppingTile(
      item: item,
      onToggle: () => cubit.toggle(item),
      onEdit: () async {
        final edit = await showItemEditDialog(context, item);
        if (edit != null) {
          await cubit.edit(item.id, name: edit.name, quantity: edit.quantity);
        }
      },
      onDelete: () {
        cubit.delete(item);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('Removed "${item.name}"'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => cubit.restore(item),
            ),
          ));
      },
    );
  }

  Future<void> _clearChecked(BuildContext context) async {
    await context.read<ShoppingCubit>().clearChecked();
  }

  Future<void> _deleteAll(BuildContext context) async {
    final cubit = context.read<ShoppingCubit>();
    if (cubit.state.items.isEmpty) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete all items?',
      message: 'This empties the whole shopping list.',
      confirmLabel: 'Delete all',
    );
    if (confirmed) await cubit.deleteAll();
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Always-visible input for fast consecutive entry.
class _QuickAddBar extends StatefulWidget {
  const _QuickAddBar();

  @override
  State<_QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends State<_QuickAddBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    context.read<ShoppingCubit>().add(name);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'Add item',
                  counterText: '',
                ),
                // onEditingComplete (instead of onSubmitted) suppresses the
                // default unfocus, so the keyboard stays open between items.
                onEditingComplete: _add,
              ),
            ),
            IconButton(
              tooltip: 'Add',
              icon: const Icon(Icons.add_circle),
              onPressed: _add,
            ),
          ],
        ),
      ),
    );
  }
}
