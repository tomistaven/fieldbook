import 'package:equatable/equatable.dart';

import '../../../domain/entities/todo.dart';

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
