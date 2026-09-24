import '../../domain/entities/shopping_item.dart';
import '../datasources/app_database.dart';

/// Maps between Drift [ShoppingItemRow]s and the [ShoppingItem] entity.
abstract final class ShoppingItemModel {
  static ShoppingItem fromRow(ShoppingItemRow row) => ShoppingItem(
    id: row.id,
    name: row.name,
    quantity: row.quantity,
    checked: row.checked,
    createdAt: row.createdAt,
  );

  static ShoppingItemRow toRow(ShoppingItem item) => ShoppingItemRow(
    id: item.id,
    name: item.name,
    quantity: item.quantity,
    checked: item.checked,
    createdAt: item.createdAt,
  );
}
