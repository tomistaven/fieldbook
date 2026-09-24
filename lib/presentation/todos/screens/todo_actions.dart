import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/dialogs.dart';
import '../../../domain/entities/todo.dart';
import '../cubit/todo_cubit.dart';
import '../widgets/todo_editor_sheet.dart';
import 'todo_screen.dart';

/// Action flows for [TodoScreen]: sheets, dialogs and snackbars.
mixin TodoActions on State<TodoScreen> {
  TodoCubit get _cubit => context.read<TodoCubit>();

  Future<void> createTodo() async {
    final draft = await showTodoEditor(context);
    if (draft == null || !mounted) return;
    await _cubit.add(
      title: draft.title,
      note: draft.note,
      dueDate: draft.dueDate,
    );
  }

  Future<void> editTodo(Todo todo) async {
    final draft = await showTodoEditor(context, existing: todo);
    if (draft == null || !mounted) return;
    await _cubit.edit(
      todo.id,
      title: draft.title,
      note: draft.note,
      dueDate: draft.dueDate,
    );
  }

  void deleteTodo(Todo todo) {
    final cubit = _cubit;
    cubit.delete(todo);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Deleted "${todo.title}"'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => cubit.restore(todo),
          ),
        ),
      );
  }

  Future<void> clearCompleted() async {
    final cubit = _cubit;
    final count = cubit.state.doneCount;
    if (count == 0) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Clear completed?',
      message: 'Delete $count completed todo${count == 1 ? '' : 's'}.',
      confirmLabel: 'Clear',
    );
    if (confirmed) await cubit.clearCompleted();
  }
}
