import 'package:drift/drift.dart';

import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../datasources/app_database.dart';
import '../models/todo_model.dart';

class TodoRepositoryImpl implements TodoRepository {
  const TodoRepositoryImpl(this._db);

  final AppDatabase _db;

  // Ordering is done in TodoState, where it depends on the active filter.
  @override
  Stream<List<Todo>> watchAll() => _db
      .select(_db.todos)
      .watch()
      .map((rows) => rows.map(TodoModel.fromRow).toList());

  @override
  Future<void> add({required String title, String? note, DateTime? dueDate}) {
    return _db
        .into(_db.todos)
        .insert(
          TodosCompanion.insert(
            title: title,
            note: Value(note),
            dueDate: Value(dueDate),
          ),
        );
  }

  @override
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

  @override
  Future<void> setDone(int id, {required bool done}) {
    return (_db.update(_db.todos)..where((t) => t.id.equals(id))).write(
      TodosCompanion(
        done: Value(done),
        completedAt: Value(done ? DateTime.now() : null),
      ),
    );
  }

  @override
  Future<void> delete(int id) =>
      (_db.delete(_db.todos)..where((t) => t.id.equals(id))).go();

  @override
  Future<void> restore(Todo todo) =>
      _db.into(_db.todos).insert(TodoModel.toRow(todo));

  @override
  Future<int> clearCompleted() =>
      (_db.delete(_db.todos)..where((t) => t.done.equals(true))).go();
}
