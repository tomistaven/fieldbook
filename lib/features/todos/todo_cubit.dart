import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/database/app_database.dart';
import 'todo_repository.dart';

enum TodoFilter {
  active('Active'),
  done('Done'),
  all('All');

  const TodoFilter(this.label);
  final String label;
}

class TodoState extends Equatable {
  const TodoState({
    this.todos = const [],
    this.filter = TodoFilter.active,
    this.loading = true,
  });

  final List<Todo> todos;
  final TodoFilter filter;
  final bool loading;

  int get activeCount => todos.where((t) => !t.done).length;
  int get doneCount => todos.length - activeCount;

  int countFor(TodoFilter f) => switch (f) {
        TodoFilter.active => activeCount,
        TodoFilter.done => doneCount,
        TodoFilter.all => todos.length,
      };

  List<Todo> get visible {
    final list = switch (filter) {
      TodoFilter.active => todos.where((t) => !t.done).toList(),
      TodoFilter.done => todos.where((t) => t.done).toList(),
      TodoFilter.all => List.of(todos),
    };
    list.sort(_compare);
    return list;
  }

  /// Open before done; open items by due date (undated last), then newest;
  /// done items by most recently completed.
  static int _compare(Todo a, Todo b) {
    if (a.done != b.done) return a.done ? 1 : -1;
    if (a.done) {
      final ac = a.completedAt ?? a.createdAt;
      final bc = b.completedAt ?? b.createdAt;
      return bc.compareTo(ac);
    }
    final ad = a.dueDate, bd = b.dueDate;
    if (ad != null && bd != null && ad != bd) return ad.compareTo(bd);
    if (ad != null && bd == null) return -1;
    if (ad == null && bd != null) return 1;
    return b.createdAt.compareTo(a.createdAt);
  }

  TodoState copyWith({List<Todo>? todos, TodoFilter? filter, bool? loading}) {
    return TodoState(
      todos: todos ?? this.todos,
      filter: filter ?? this.filter,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [todos, filter, loading];
}

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

  Future<void> toggle(Todo todo) => _repository.setDone(todo.id, !todo.done);

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
