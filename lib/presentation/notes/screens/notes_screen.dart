import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/empty_state.dart';
import '../../settings/widgets/settings_button.dart';
import '../cubit/notes_cubit.dart';
import '../cubit/notes_state.dart';
import '../widgets/note_card.dart';
import 'notes_actions.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with NotesActions {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: const [SettingsButton()],
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
                      onTap: () => openNote(note.id),
                      onLongPress: () => showNoteActions(note),
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
        onPressed: () => openNote(null),
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }
}
