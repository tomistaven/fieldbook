import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../domain/repositories/note_repository.dart';
import '../../../injection_container.dart';

/// Create/edit screen with autosave.
///
/// Saves shortly after the last keystroke, when leaving the screen and when
/// the app is backgrounded. A new note is not created until it has content;
/// an existing note emptied out is deleted on exit.
class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, this.noteId});

  final int? noteId;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen>
    with WidgetsBindingObserver {
  final NoteRepository _repo = sl<NoteRepository>();
  final _title = TextEditingController();
  final _body = TextEditingController();

  int? _id;
  String _savedTitle = '';
  String _savedBody = '';
  bool _loading = false;
  bool _deleted = false;
  Timer? _debounce;

  // Serializes writes so a create always finishes before the next update.
  Future<void> _chain = Future.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _id = widget.noteId;
    if (_id != null) _load(_id!);
    _title.addListener(_scheduleSave);
    _body.addListener(_scheduleSave);
  }

  Future<void> _load(int id) async {
    setState(() => _loading = true);
    final note = await _repo.getById(id);
    if (!mounted) return;
    if (note != null) {
      _savedTitle = note.title;
      _savedBody = note.body;
      _title.text = note.title;
      _body.text = note.body;
    }
    setState(() => _loading = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _save();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _scheduleSave() {
    if (_loading) return;
    _debounce?.cancel();
    _debounce = Timer(AppConstants.noteAutosaveDelay, _save);
  }

  Future<void> _save() {
    _debounce?.cancel();
    if (_deleted || _loading) return _chain;
    final title = _title.text;
    final body = _body.text;
    if (title == _savedTitle && body == _savedBody) return _chain;
    _chain = _chain.then((_) => _persist(title, body));
    return _chain;
  }

  Future<void> _persist(String title, String body) async {
    final isEmpty = title.trim().isEmpty && body.trim().isEmpty;
    final id = _id;
    if (id == null) {
      if (isEmpty) return;
      _id = await _repo.create(title: title, body: body);
    } else {
      await _repo.update(id, title: title, body: body);
    }
    _savedTitle = title;
    _savedBody = body;
  }

  Future<void> _onExit() async {
    final isEmpty = _title.text.trim().isEmpty && _body.text.trim().isEmpty;
    await _save();
    final id = _id;
    if (isEmpty && id != null && !_deleted) {
      await _chain;
      await _repo.delete(id);
    }
  }

  Future<void> _delete() async {
    final id = _id;
    if (id == null) {
      Navigator.pop(context);
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete note?',
      message: 'This cannot be undone.',
    );
    if (!confirmed || !mounted) return;
    _deleted = true;
    _debounce?.cancel();
    await _chain;
    await _repo.delete(id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _copy() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    final text = [title, body].where((s) => s.isNotEmpty).join('\n\n');
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _onExit();
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy_outlined),
              onPressed: _copy,
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    TextField(
                      controller: _title,
                      autofocus: widget.noteId == null,
                      textCapitalization: TextCapitalization.sentences,
                      style: Theme.of(context).textTheme.headlineMedium,
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                    Divider(color: scheme.outline),
                    Expanded(
                      child: TextField(
                        controller: _body,
                        expands: true,
                        maxLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: const InputDecoration(
                          hintText: 'Start writing…',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
