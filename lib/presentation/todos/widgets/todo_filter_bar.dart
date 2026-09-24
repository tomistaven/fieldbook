import 'package:flutter/material.dart';

import '../cubit/todo_state.dart';

/// Horizontal chip row: Active / Done / All, each with its count.
class TodoFilterBar extends StatelessWidget {
  const TodoFilterBar({
    super.key,
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  final TodoFilter selected;
  final int Function(TodoFilter) countFor;
  final ValueChanged<TodoFilter> onSelected;

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
                label: Text('${f.label} (${countFor(f)})'),
                selected: selected == f,
                labelStyle: TextStyle(
                  color: selected == f ? scheme.surface : scheme.onSurface,
                ),
                onSelected: (_) => onSelected(f),
              ),
            ),
        ],
      ),
    );
  }
}
