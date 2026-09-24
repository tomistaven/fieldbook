import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'note.dart';
import 'note_repository.dart';

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

class NotesCubit extends Cubit<NotesState> {
  NotesCubit(this._repository) : super(const NotesState()) {
    _subscription = _repository.watchAll().listen(
          (notes) => emit(state.copyWith(notes: notes, loading: false)),
        );
  }

  final NoteRepository _repository;
  late final StreamSubscription<List<Note>> _subscription;

  void search(String query) => emit(state.copyWith(query: query));

  Future<void> togglePin(Note note) =>
      _repository.setPinned(note.id, !note.pinned);

  Future<void> delete(Note note) => _repository.delete(note.id);

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
