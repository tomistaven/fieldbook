import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/dialogs.dart';
import '../../../domain/entities/note.dart';
import '../cubit/notes_cubit.dart';
import 'note_editor_screen.dart';
import 'notes_screen.dart';

/// Action flows for [NotesScreen]: navigation, sheets and dialogs.
mixin NotesActions on State<NotesScreen> {
  void openNote(int? id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => NoteEditorScreen(noteId: id)),
    );
  }

  Future<void> showNoteActions(Note note) async {
    final cubit = context.read<NotesCubit>();
    final action = await showModalBottomSheet<_NoteAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                note.pinned ? Icons.push_pin_outlined : Icons.push_pin,
              ),
              title: Text(note.pinned ? 'Unpin' : 'Pin to top'),
              onTap: () => Navigator.pop(context, _NoteAction.pin),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context, _NoteAction.delete),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _NoteAction.pin:
        await cubit.togglePin(note);
      case _NoteAction.delete:
        final confirmed = await showConfirmDialog(
          context,
          title: 'Delete note?',
          message: '"${note.displayTitle}" will be deleted permanently.',
        );
        if (confirmed) await cubit.delete(note);
    }
  }
}

enum _NoteAction { pin, delete }
