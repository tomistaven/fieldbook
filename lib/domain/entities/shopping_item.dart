import 'package:equatable/equatable.dart';

class ShoppingItem extends Equatable {
  const ShoppingItem({
    required this.id,
    required this.name,
    required this.checked,
    required this.createdAt,
    this.quantity,
  });

  final int id;
  final String name;

  /// Free text so "2", "500 g" and "1 pack" all work.
  final String? quantity;
  final bool checked;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, quantity, checked, createdAt];
}
