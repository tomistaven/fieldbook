import '../entities/note.dart';

/// Contract for persisting notes. Implementations store title and body
/// encrypted; this interface always deals in plain text.
abstract class NoteRepository {
  /// Emits all notes, pinned first, then most recently edited.
  Stream<List<Note>> watchAll();

  Future<Note?> getById(int id);

  /// Returns the new note's id.
  Future<int> create({required String title, required String body});

  Future<void> update(int id, {required String title, required String body});

  Future<void> setPinned(int id, {required bool pinned});

  Future<void> delete(int id);
}
