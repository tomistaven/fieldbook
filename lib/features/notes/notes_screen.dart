import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/dialogs.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/theme_toggle_button.dart';
import 'note.dart';
import 'note_editor_screen.dart';
import 'notes_cubit.dart';
import 'widgets/note_card.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: const [ThemeToggleButton()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              onChanged: context.read<NotesCubit>().search,
              decoration: const InputDecoration(
                hintText: 'Search notes',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<NotesCubit, NotesState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final notes = state.visible;
                if (notes.isEmpty) {
                  return EmptyState(
                    icon: Icons.sticky_note_2_outlined,
                    message: state.notes.isEmpty
                        ? 'No notes yet. Tap + to write one.'
                        : 'No notes match "${state.query.trim()}"',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: notes.length,
                  itemBuilder: (context, i) {
                    final note = notes[i];
                    return NoteCard(
                      note: note,
                      onTap: () => _open(context, note.id),
                      onLongPress: () => _showActions(context, note),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notes-fab',
        tooltip: 'New note',
        onPressed: () => _open(context, null),
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }

  void _open(BuildContext context, int? id) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: id)),
    );
  }

  Future<void> _showActions(BuildContext context, Note note) async {
    final cubit = context.read<NotesCubit>();
    final action = await showModalBottomSheet<String>(
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
              onTap: () => Navigator.pop(context, 'pin'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case 'pin':
        await cubit.togglePin(note);
      case 'delete':
        final confirmed = await showConfirmDialog(
          context,
          title: 'Delete note?',
          message: '"${note.displayTitle}" will be deleted permanently.',
        );
        if (confirmed) await cubit.delete(note);
    }
  }
}
