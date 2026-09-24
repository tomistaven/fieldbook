import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_labels.dart';
import '../../../domain/entities/todo.dart';

class TodoDraft {
  const TodoDraft({required this.title, this.note, this.dueDate});

  final String title;
  final String? note;
  final DateTime? dueDate;
}

/// Opens the create/edit sheet. Returns null when dismissed.
Future<TodoDraft?> showTodoEditor(BuildContext context, {Todo? existing}) {
  return showModalBottomSheet<TodoDraft>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TodoEditorSheet(existing: existing),
  );
}

class _TodoEditorSheet extends StatefulWidget {
  const _TodoEditorSheet({this.existing});

  final Todo? existing;

  @override
  State<_TodoEditorSheet> createState() => _TodoEditorSheetState();
}

class _TodoEditorSheetState extends State<_TodoEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  DateTime? _dueDate;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title);
    _note = TextEditingController(text: widget.existing?.note);
    _dueDate = widget.existing?.dueDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Title is required');
      return;
    }
    final note = _note.text.trim();
    Navigator.pop(
      context,
      TodoDraft(
        title: title,
        note: note.isEmpty ? null : note,
        dueDate: _dueDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isEdit ? 'Edit todo' : 'New todo',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            autofocus: !isEdit,
            maxLength: AppConstants.maxTodoTitleLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'What needs doing?',
              errorText: _titleError,
              counterText: '',
            ),
            onChanged: (_) {
              if (_titleError != null) setState(() => _titleError = null);
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Note (optional)'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event, size: 18),
                label: Text(
                  _dueDate == null
                      ? 'Due date'
                      : DateLabels.relativeDay(_dueDate!),
                ),
              ),
              if (_dueDate != null)
                IconButton(
                  tooltip: 'Clear due date',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _dueDate = null),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: _submit,
                child: Text(isEdit ? 'Save' : 'Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
