import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/note.dart';
import '../../../domain/repositories/note_repository.dart';
import 'notes_state.dart';

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
      _repository.setPinned(note.id, pinned: !note.pinned);

  Future<void> delete(Note note) => _repository.delete(note.id);

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
