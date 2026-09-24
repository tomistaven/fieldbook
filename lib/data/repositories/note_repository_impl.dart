import 'package:drift/drift.dart';

import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/app_database.dart';
import '../datasources/encryption_service.dart';

/// Encrypts title and body before they reach SQLite and decrypts them on the
/// way out. Search therefore runs in memory on decrypted notes.
class NoteRepositoryImpl implements NoteRepository {
  const NoteRepositoryImpl(this._db, this._crypto);

  final AppDatabase _db;
  final EncryptionService _crypto;

  @override
  Stream<List<Note>> watchAll() {
    return (_db.select(_db.notes)..orderBy([
          (n) => OrderingTerm.desc(n.pinned),
          (n) => OrderingTerm.desc(n.updatedAt),
        ]))
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<Note?> getById(int id) async {
    final row = await (_db.select(
      _db.notes,
    )..where((n) => n.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<int> create({required String title, required String body}) {
    return _db
        .into(_db.notes)
        .insert(
          NotesCompanion.insert(
            title: _crypto.encryptText(title),
            body: _crypto.encryptText(body),
          ),
        );
  }

  @override
  Future<void> update(int id, {required String title, required String body}) {
    return (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(
        title: Value(_crypto.encryptText(title)),
        body: Value(_crypto.encryptText(body)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> setPinned(int id, {required bool pinned}) {
    return (_db.update(_db.notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(pinned: Value(pinned)),
    );
  }

  @override
  Future<void> delete(int id) =>
      (_db.delete(_db.notes)..where((n) => n.id.equals(id))).go();

  Note _toEntity(NoteRow row) => Note(
    id: row.id,
    title: _crypto.decryptText(row.title),
    body: _crypto.decryptText(row.body),
    pinned: row.pinned,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
