import 'package:drift/drift.dart';

import '../../domain/entities/shopping_item.dart';
import '../../domain/repositories/shopping_repository.dart';
import '../datasources/app_database.dart';
import '../models/shopping_item_model.dart';

class ShoppingRepositoryImpl implements ShoppingRepository {
  const ShoppingRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<ShoppingItem>> watchAll() {
    return (_db.select(_db.shoppingItems)
          ..orderBy([(i) => OrderingTerm.asc(i.createdAt)]))
        .watch()
        .map((rows) => rows.map(ShoppingItemModel.fromRow).toList());
  }

  @override
  Future<void> add(String name, {String? quantity}) {
    return _db
        .into(_db.shoppingItems)
        .insert(
          ShoppingItemsCompanion.insert(name: name, quantity: Value(quantity)),
        );
  }

  @override
  Future<void> edit(int id, {required String name, String? quantity}) {
    return (_db.update(_db.shoppingItems)..where((i) => i.id.equals(id)))
        .write(
          ShoppingItemsCompanion(name: Value(name), quantity: Value(quantity)),
        );
  }

  @override
  Future<void> setChecked(int id, {required bool checked}) {
    return (_db.update(_db.shoppingItems)..where((i) => i.id.equals(id)))
        .write(ShoppingItemsCompanion(checked: Value(checked)));
  }

  @override
  Future<void> delete(int id) =>
      (_db.delete(_db.shoppingItems)..where((i) => i.id.equals(id))).go();

  @override
  Future<void> restore(ShoppingItem item) =>
      _db.into(_db.shoppingItems).insert(ShoppingItemModel.toRow(item));

  @override
  Future<int> clearChecked() => (_db.delete(
    _db.shoppingItems,
  )..where((i) => i.checked.equals(true))).go();

  @override
  Future<int> deleteAll() => _db.delete(_db.shoppingItems).go();
}
