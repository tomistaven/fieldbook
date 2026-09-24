import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../domain/entities/shopping_item.dart';
import '../../settings/widgets/add_button_side.dart';
import '../../settings/widgets/settings_button.dart';
import '../cubit/shopping_cubit.dart';
import '../cubit/shopping_state.dart';
import '../widgets/quick_add_bar.dart';
import '../widgets/shopping_tile.dart';
import 'shopping_actions.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> with ShoppingActions {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ShoppingCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => switch (value) {
              'clear' => cubit.clearChecked(),
              'all' => deleteAll(),
              _ => null,
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'clear', child: Text('Clear checked')),
              PopupMenuItem(value: 'all', child: Text('Delete all')),
            ],
          ),
          const SettingsButton(),
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
                    message: 'Nothing to buy yet. Add items below.',
                  );
                }
                final toBuy = state.toBuy;
                final inCart = state.inCart;
                return ListView(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  children: [
                    for (final item in toBuy) _tile(item),
                    if (inCart.isNotEmpty) ...[
                      _SectionHeader('In cart (${inCart.length})'),
                      for (final item in inCart) _tile(item),
                    ],
                  ],
                );
              },
            ),
          ),
          QuickAddBar(
            onAdd: cubit.add,
            buttonOnLeft: context.addButtonsOnLeft,
          ),
        ],
      ),
    );
  }

  Widget _tile(ShoppingItem item) => ShoppingTile(
    item: item,
    onToggle: () => context.read<ShoppingCubit>().toggle(item),
    onEdit: () => editItem(item),
    onDelete: () => deleteItem(item),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
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