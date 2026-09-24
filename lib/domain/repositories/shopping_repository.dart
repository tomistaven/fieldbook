import '../entities/shopping_item.dart';

/// Contract for persisting the shopping list.
abstract class ShoppingRepository {
  /// Emits all items, oldest first, on every change.
  Stream<List<ShoppingItem>> watchAll();

  Future<void> add(String name, {String? quantity});

  Future<void> edit(int id, {required String name, String? quantity});

  Future<void> setChecked(int id, {required bool checked});

  Future<void> delete(int id);

  /// Re-inserts a deleted item with its original id (undo).
  Future<void> restore(ShoppingItem item);

  Future<int> clearChecked();

  Future<int> deleteAll();
}
