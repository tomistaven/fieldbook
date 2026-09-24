import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/todo.dart';
import '../../../domain/repositories/todo_repository.dart';
import 'todo_state.dart';

class TodoCubit extends Cubit<TodoState> {
  TodoCubit(this._repository) : super(const TodoState()) {
    _subscription = _repository.watchAll().listen(
          (todos) => emit(state.copyWith(todos: todos, loading: false)),
        );
  }

  final TodoRepository _repository;
  late final StreamSubscription<List<Todo>> _subscription;

  void setFilter(TodoFilter filter) => emit(state.copyWith(filter: filter));

  Future<void> add({required String title, String? note, DateTime? dueDate}) =>
      _repository.add(title: title, note: note, dueDate: dueDate);

  Future<void> edit(int id,
          {required String title, String? note, DateTime? dueDate}) =>
      _repository.edit(id, title: title, note: note, dueDate: dueDate);

  Future<void> toggle(Todo todo) =>
      _repository.setDone(todo.id, done: !todo.done);

  /// Removes from state immediately: Dismissible asserts if the swiped
  /// widget is still in the tree on the next frame, and the Drift stream
  /// update arrives asynchronously.
  Future<void> delete(Todo todo) {
    emit(state.copyWith(
      todos: state.todos.where((t) => t.id != todo.id).toList(),
    ));
    return _repository.delete(todo.id);
  }

  Future<void> restore(Todo todo) => _repository.restore(todo);

  Future<int> clearCompleted() => _repository.clearCompleted();

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
