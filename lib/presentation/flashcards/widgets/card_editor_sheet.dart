import 'package:flutter/material.dart';

import '../../../domain/entities/flashcard.dart';

typedef CardSaver = Future<void> Function(String front, String back);

/// New card: "Add" saves and clears the fields so several cards can be
/// entered in a row. Existing card: "Save" saves and closes.
Future<void> showCardEditor(
  BuildContext context, {
  Flashcard? existing,
  required CardSaver onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CardEditorSheet(existing: existing, onSave: onSave),
  );
}

class _CardEditorSheet extends StatefulWidget {
  const _CardEditorSheet({this.existing, required this.onSave});

  final Flashcard? existing;
  final CardSaver onSave;

  @override
  State<_CardEditorSheet> createState() => _CardEditorSheetState();
}

class _CardEditorSheetState extends State<_CardEditorSheet> {
  late final _front = TextEditingController(text: widget.existing?.front);
  late final _back = TextEditingController(text: widget.existing?.back);
  final _frontFocus = FocusNode();
  String? _error;
  int _added = 0;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    _frontFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final front = _front.text.trim();
    final back = _back.text.trim();
    if (front.isEmpty || back.isEmpty) {
      setState(() => _error = 'Both sides are required');
      return;
    }
    await widget.onSave(front, back);
    if (!mounted) return;
    if (_isEdit) {
      Navigator.pop(context);
    } else {
      _front.clear();
      _back.clear();
      setState(() {
        _error = null;
        _added++;
      });
      _frontFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
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
            _isEdit ? 'Edit card' : 'New card',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _front,
            focusNode: _frontFocus,
            autofocus: !_isEdit,
            minLines: 1,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Front (question)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _back,
            minLines: 1,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Back (answer)',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!_isEdit && _added > 0)
                Text(
                  'Added $_added',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: _submit,
                child: Text(_isEdit ? 'Save' : 'Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
