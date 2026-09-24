import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../core/security/encryption_service.dart';
import 'note.dart';

/// Title and body are encrypted before they reach SQLite and decrypted on
/// the way out. Search therefore runs in memory on decrypted notes.
class NoteRepository {
  NoteRepository(this._db, this._crypto);

  final AppDatabase _db;
  final EncryptionService _crypto;

  Stream<List<Note>> watchAll() {
    return (_db.select(_db.notes)
          ..orderBy([
            (n) => OrderingTerm.desc(n.pinned),
            (n) => OrderingTerm.desc(n.updatedAt),
          ]))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  Future<Note?> getById(int id) async {
    final row = await (_db.select(_db.notes)..where((n) => n.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  /// Returns the new note's id.
  Future<int> create({required String title, required String body}) {
    return _db.into(_db.notes).insert(
          NotesCompanion.insert(
            title: _crypto.encryptText(title),
            body: _crypto.encryptText(body),
          ),
        );
  }

  Future<void> update(int id, {required String title, required String body}) {
    return (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(
        title: Value(_crypto.encryptText(title)),
        body: Value(_crypto.encryptText(body)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setPinned(int id, bool pinned) {
    return (_db.update(_db.notes)..where((n) => n.id.equals(id)))
        .write(NotesCompanion(pinned: Value(pinned)));
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.notes)..where((n) => n.id.equals(id))).go();

  Note _toDomain(NoteRow row) => Note(
        id: row.id,
        title: _crypto.decryptText(row.title),
        body: _crypto.decryptText(row.body),
        pinned: row.pinned,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
}
