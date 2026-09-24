import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/delete_swipe_background.dart';
import '../../../domain/entities/todo.dart';

/// Checkbox row with title, due-date label and note preview.
/// Swipe left to delete.
class TodoTile extends StatelessWidget {
  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final due = todo.dueDate;
    final overdue = !todo.done && due != null && DateLabels.isOverdue(due);
    final note = todo.note;

    return Dismissible(
      key: ValueKey('todo-${todo.id}'),
      direction: DismissDirection.endToStart,
      background: const DeleteSwipeBackground(),
      onDismissed: (_) => onDelete(),
      child: Card(
        child: ListTile(
          onTap: onTap,
          leading: Checkbox(
            value: todo.done,
            onChanged: (_) => onToggle(),
            shape: const CircleBorder(),
          ),
          title: Text(
            todo.title,
            style: TextStyle(
              decoration: todo.done ? TextDecoration.lineThrough : null,
              color: todo.done ? scheme.onSurfaceVariant : scheme.onSurface,
            ),
          ),
          subtitle: (due == null && (note == null || note.isEmpty))
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (due != null)
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: 14,
                            color: overdue
                                ? AppColors.danger
                                : scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateLabels.relativeDay(due),
                            style: TextStyle(
                              fontSize: 13,
                              color: overdue
                                  ? AppColors.danger
                                  : scheme.onSurfaceVariant,
                              fontWeight: overdue ? FontWeight.w600 : null,
                            ),
                          ),
                        ],
                      ),
                    if (note != null && note.isNotEmpty)
                      Text(
                        note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
