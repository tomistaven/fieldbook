import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/database/app_database.dart';
import 'shopping_repository.dart';

class ShoppingState extends Equatable {
  const ShoppingState({this.items = const [], this.loading = true});

  final List<ShoppingItem> items;
  final bool loading;

  List<ShoppingItem> get toBuy => items.where((i) => !i.checked).toList();
  List<ShoppingItem> get inCart => items.where((i) => i.checked).toList();

  @override
  List<Object?> get props => [items, loading];
}

class ShoppingCubit extends Cubit<ShoppingState> {
  ShoppingCubit(this._repository) : super(const ShoppingState()) {
    _subscription = _repository.watchAll().listen(
          (items) => emit(ShoppingState(items: items, loading: false)),
        );
  }

  final ShoppingRepository _repository;
  late final StreamSubscription<List<ShoppingItem>> _subscription;

  Future<void> add(String name, {String? quantity}) =>
      _repository.add(name, quantity: quantity);

  Future<void> edit(int id, {required String name, String? quantity}) =>
      _repository.edit(id, name: name, quantity: quantity);

  Future<void> toggle(ShoppingItem item) =>
      _repository.setChecked(item.id, !item.checked);

  /// Optimistic removal; see TodoCubit.delete.
  Future<void> delete(ShoppingItem item) {
    emit(ShoppingState(
      items: state.items.where((i) => i.id != item.id).toList(),
      loading: false,
    ));
    return _repository.delete(item.id);
  }

  Future<void> restore(ShoppingItem item) => _repository.restore(item);

  Future<int> clearChecked() => _repository.clearChecked();

  Future<int> deleteAll() => _repository.deleteAll();

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
