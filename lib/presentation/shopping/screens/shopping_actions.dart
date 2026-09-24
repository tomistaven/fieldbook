import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/dialogs.dart';
import '../../../domain/entities/shopping_item.dart';
import '../cubit/shopping_cubit.dart';
import '../widgets/item_edit_dialog.dart';
import 'shopping_screen.dart';

/// Action flows for [ShoppingScreen]: dialogs and snackbars.
mixin ShoppingActions on State<ShoppingScreen> {
  ShoppingCubit get _cubit => context.read<ShoppingCubit>();

  Future<void> editItem(ShoppingItem item) async {
    final cubit = _cubit;
    final edit = await showItemEditDialog(context, item);
    if (edit == null) return;
    await cubit.edit(item.id, name: edit.name, quantity: edit.quantity);
  }

  void deleteItem(ShoppingItem item) {
    final cubit = _cubit;
    cubit.delete(item);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed "${item.name}"'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => cubit.restore(item),
          ),
        ),
      );
  }

  Future<void> deleteAll() async {
    final cubit = _cubit;
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
