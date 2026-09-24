import 'package:equatable/equatable.dart';

/// Decrypted note. The database row type is `NoteRow`.
class Note extends Equatable {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.pinned,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String body;
  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Title, or the first non-empty body line when the title is blank.
  String get displayTitle {
    if (title.trim().isNotEmpty) return title.trim();
    final firstLine = body
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => '');
    return firstLine.isEmpty ? 'Untitled' : firstLine;
  }

  bool matches(String query) {
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) || body.toLowerCase().contains(q);
  }

  @override
  List<Object?> get props => [id, title, body, pinned, createdAt, updatedAt];
}
