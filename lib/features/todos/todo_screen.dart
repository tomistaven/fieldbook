import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/database/app_database.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/theme_toggle_button.dart';
import 'todo_cubit.dart';
import 'widgets/todo_editor_sheet.dart';
import 'widgets/todo_tile.dart';

class TodoScreen extends StatelessWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos'),
        actions: [
          const ThemeToggleButton(),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') _clearCompleted(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'clear', child: Text('Clear completed')),
            ],
          ),
        ],
      ),
      body: BlocBuilder<TodoCubit, TodoState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = state.visible;
          return Column(
            children: [
              _FilterBar(state: state),
              Expanded(
                child: items.isEmpty
                    ? EmptyState(
                        icon: Icons.check_circle_outline,
                        message: switch (state.filter) {
                          TodoFilter.active => 'Nothing to do. Tap + to add.',
                          TodoFilter.done => 'No completed todos',
                          TodoFilter.all => 'No todos yet. Tap + to add.',
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final todo = items[i];
                          return TodoTile(
                            todo: todo,
                            onToggle: () =>
                                context.read<TodoCubit>().toggle(todo),
                            onTap: () => _edit(context, todo),
                            onDelete: () => _delete(context, todo),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'todos-fab',
        tooltip: 'New todo',
        onPressed: () => _create(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final draft = await showTodoEditor(context);
    if (draft == null || !context.mounted) return;
    await context.read<TodoCubit>().add(
          title: draft.title,
          note: draft.note,
          dueDate: draft.dueDate,
        );
  }

  Future<void> _edit(BuildContext context, Todo todo) async {
    final draft = await showTodoEditor(context, existing: todo);
    if (draft == null || !context.mounted) return;
    await context.read<TodoCubit>().edit(
          todo.id,
          title: draft.title,
          note: draft.note,
          dueDate: draft.dueDate,
        );
  }

  void _delete(BuildContext context, Todo todo) {
    final cubit = context.read<TodoCubit>();
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

  Future<void> _clearCompleted(BuildContext context) async {
    final cubit = context.read<TodoCubit>();
    if (cubit.state.doneCount == 0) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Clear completed?',
      message: 'Delete ${cubit.state.doneCount} completed todo(s).',
      confirmLabel: 'Clear',
    );
    if (confirmed) await cubit.clearCompleted();
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.state});

  final TodoState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (final f in TodoFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${f.label} (${state.countFor(f)})'),
                selected: state.filter == f,
                labelStyle: TextStyle(
                  color: state.filter == f ? scheme.surface : scheme.onSurface,
                ),
                onSelected: (_) => context.read<TodoCubit>().setFilter(f),
              ),
            ),
        ],
      ),
    );
  }
}
