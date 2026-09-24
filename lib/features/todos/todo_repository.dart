import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';

class TodoRepository {
  TodoRepository(this._db);

  final AppDatabase _db;

  /// Emits on every change to the table. Ordering is done in TodoCubit.
  Stream<List<Todo>> watchAll() => _db.select(_db.todos).watch();

  Future<void> add({
    required String title,
    String? note,
    DateTime? dueDate,
  }) {
    return _db.into(_db.todos).insert(
          TodosCompanion.insert(
            title: title,
            note: Value(note),
            dueDate: Value(dueDate),
          ),
        );
  }

  Future<void> edit(
    int id, {
    required String title,
    String? note,
    DateTime? dueDate,
  }) {
    return (_db.update(_db.todos)..where((t) => t.id.equals(id))).write(
      TodosCompanion(
        title: Value(title),
        note: Value(note),
        dueDate: Value(dueDate),
      ),
    );
  }

  Future<void> setDone(int id, bool done) {
    return (_db.update(_db.todos)..where((t) => t.id.equals(id))).write(
      TodosCompanion(
        done: Value(done),
        completedAt: Value(done ? DateTime.now() : null),
      ),
    );
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.todos)..where((t) => t.id.equals(id))).go();

  /// Re-inserts a deleted row with its original id (undo).
  Future<void> restore(Todo todo) => _db.into(_db.todos).insert(todo);

  Future<int> clearCompleted() =>
      (_db.delete(_db.todos)..where((t) => t.done.equals(true))).go();
}
