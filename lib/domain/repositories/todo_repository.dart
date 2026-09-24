import '../entities/todo.dart';

/// Contract for persisting todos. Cubits depend only on this interface.
abstract class TodoRepository {
  /// Emits the full list on every change.
  Stream<List<Todo>> watchAll();

  Future<void> add({required String title, String? note, DateTime? dueDate});

  Future<void> edit(
    int id, {
    required String title,
    String? note,
    DateTime? dueDate,
  });

  Future<void> setDone(int id, {required bool done});

  Future<void> delete(int id);

  /// Re-inserts a deleted todo with its original id (undo).
  Future<void> restore(Todo todo);

  /// Returns the number of deleted todos.
  Future<int> clearCompleted();
}
