import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/empty_state.dart';
import '../../settings/widgets/add_button_side.dart';
import '../../settings/widgets/settings_button.dart';
import '../cubit/todo_cubit.dart';
import '../cubit/todo_state.dart';
import '../widgets/todo_filter_bar.dart';
import '../widgets/todo_tile.dart';
import 'todo_actions.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> with TodoActions {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') clearCompleted();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'clear', child: Text('Clear completed')),
            ],
          ),
          const SettingsButton(),
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
              TodoFilterBar(
                selected: state.filter,
                countFor: state.countFor,
                onSelected: context.read<TodoCubit>().setFilter,
              ),
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
                            onTap: () => editTodo(todo),
                            onDelete: () => deleteTodo(todo),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: context.addButtonLocation,
      floatingActionButton: FloatingActionButton(
        heroTag: 'todos-fab',
        tooltip: 'New todo',
        onPressed: createTodo,
        child: const Icon(Icons.add),
      ),
    );
  }
}