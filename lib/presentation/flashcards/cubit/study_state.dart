import 'package:equatable/equatable.dart';

import '../../../domain/entities/flashcard.dart';

class StudyState extends Equatable {
  const StudyState({
    this.queue = const [],
    this.position = 0,
    this.revealed = false,
    this.total = 0,
    this.correctFirstTry = 0,
    this.loading = true,
  });

  /// Cards still to show; missed cards are appended to the end.
  final List<Flashcard> queue;
  final int position;
  final bool revealed;

  /// Number of distinct cards in the session.
  final int total;
  final int correctFirstTry;
  final bool loading;

  bool get finished => !loading && position >= queue.length;
  Flashcard? get current => finished || loading ? null : queue[position];

  StudyState copyWith({
    List<Flashcard>? queue,
    int? position,
    bool? revealed,
    int? total,
    int? correctFirstTry,
    bool? loading,
  }) {
    return StudyState(
      queue: queue ?? this.queue,
      position: position ?? this.position,
      revealed: revealed ?? this.revealed,
      total: total ?? this.total,
      correctFirstTry: correctFirstTry ?? this.correctFirstTry,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props =>
      [queue, position, revealed, total, correctFirstTry, loading];
}
