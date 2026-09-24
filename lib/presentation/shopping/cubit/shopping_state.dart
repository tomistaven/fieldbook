import 'package:equatable/equatable.dart';

import '../../../domain/entities/shopping_item.dart';

class ShoppingState extends Equatable {
  const ShoppingState({this.items = const [], this.loading = true});

  final List<ShoppingItem> items;
  final bool loading;

  List<ShoppingItem> get toBuy => items.where((i) => !i.checked).toList();
  List<ShoppingItem> get inCart => items.where((i) => i.checked).toList();

  @override
  List<Object?> get props => [items, loading];
}
