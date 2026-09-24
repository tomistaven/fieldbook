import 'package:equatable/equatable.dart';

class Todo extends Equatable {
  const Todo({
    required this.id,
    required this.title,
    required this.done,
    required this.createdAt,
    this.note,
    this.dueDate,
    this.completedAt,
  });

  final int id;
  final String title;
  final String? note;
  final DateTime? dueDate;
  final bool done;
  final DateTime createdAt;
  final DateTime? completedAt;

  @override
  List<Object?> get props =>
      [id, title, note, dueDate, done, createdAt, completedAt];
}
