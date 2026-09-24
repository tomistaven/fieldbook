import 'package:equatable/equatable.dart';

import '../../../domain/entities/note.dart';

class NotesState extends Equatable {
  const NotesState({
    this.notes = const [],
    this.query = '',
    this.loading = true,
  });

  final List<Note> notes;
  final String query;
  final bool loading;

  List<Note> get visible {
    final q = query.trim();
    return q.isEmpty ? notes : notes.where((n) => n.matches(q)).toList();
  }

  NotesState copyWith({List<Note>? notes, String? query, bool? loading}) {
    return NotesState(
      notes: notes ?? this.notes,
      query: query ?? this.query,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [notes, query, loading];
}
