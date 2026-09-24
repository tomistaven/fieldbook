import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';

class ShoppingRepository {
  ShoppingRepository(this._db);

  final AppDatabase _db;

  Stream<List<ShoppingItem>> watchAll() {
    return (_db.select(_db.shoppingItems)
          ..orderBy([(i) => OrderingTerm.asc(i.createdAt)]))
        .watch();
  }

  Future<void> add(String name, {String? quantity}) {
    return _db.into(_db.shoppingItems).insert(
          ShoppingItemsCompanion.insert(name: name, quantity: Value(quantity)),
        );
  }

  Future<void> edit(int id, {required String name, String? quantity}) {
    return (_db.update(_db.shoppingItems)..where((i) => i.id.equals(id)))
        .write(ShoppingItemsCompanion(
      name: Value(name),
      quantity: Value(quantity),
    ));
  }

  Future<void> setChecked(int id, bool checked) {
    return (_db.update(_db.shoppingItems)..where((i) => i.id.equals(id)))
        .write(ShoppingItemsCompanion(checked: Value(checked)));
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.shoppingItems)..where((i) => i.id.equals(id))).go();

  Future<void> restore(ShoppingItem item) =>
      _db.into(_db.shoppingItems).insert(item);

  Future<int> clearChecked() => (_db.delete(_db.shoppingItems)
        ..where((i) => i.checked.equals(true)))
      .go();

  Future<int> deleteAll() => _db.delete(_db.shoppingItems).go();
}
