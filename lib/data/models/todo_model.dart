import '../../domain/entities/todo.dart';
import '../datasources/app_database.dart';

/// Maps between Drift [TodoRow]s and the [Todo] domain entity.
abstract final class TodoModel {
  static Todo fromRow(TodoRow row) => Todo(
    id: row.id,
    title: row.title,
    note: row.note,
    dueDate: row.dueDate,
    done: row.done,
    createdAt: row.createdAt,
    completedAt: row.completedAt,
  );

  static TodoRow toRow(Todo todo) => TodoRow(
    id: todo.id,
    title: todo.title,
    note: todo.note,
    dueDate: todo.dueDate,
    done: todo.done,
    createdAt: todo.createdAt,
    completedAt: todo.completedAt,
  );
}
