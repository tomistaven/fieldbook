import 'package:equatable/equatable.dart';

import '../../../domain/entities/pomodoro.dart';

enum TimerStatus { idle, running, paused }

class PomodoroState extends Equatable {
  const PomodoroState({
    required this.settings,
    required this.phase,
    required this.status,
    required this.remaining,
    required this.focusInCycle,
    required this.completedToday,
    this.completedSignal = 0,
    this.lastCompleted,
  });

  final PomodoroSettings settings;
  final PomodoroPhase phase;
  final TimerStatus status;
  final Duration remaining;
  final int focusInCycle;
  final int completedToday;

  /// Increments each time a phase finishes on its own; UI listens for it.
  final int completedSignal;
  final PomodoroPhase? lastCompleted;

  Duration get total => settings.durationOf(phase);

  double get progress {
    final totalMs = total.inMilliseconds;
    if (totalMs == 0) return 0;
    return (1 - remaining.inMilliseconds / totalMs).clamp(0.0, 1.0);
  }

  PomodoroState copyWith({
    PomodoroSettings? settings,
    PomodoroPhase? phase,
    TimerStatus? status,
    Duration? remaining,
    int? focusInCycle,
    int? completedToday,
    int? completedSignal,
    PomodoroPhase? lastCompleted,
  }) {
    return PomodoroState(
      settings: settings ?? this.settings,
      phase: phase ?? this.phase,
      status: status ?? this.status,
      remaining: remaining ?? this.remaining,
      focusInCycle: focusInCycle ?? this.focusInCycle,
      completedToday: completedToday ?? this.completedToday,
      completedSignal: completedSignal ?? this.completedSignal,
      lastCompleted: lastCompleted ?? this.lastCompleted,
    );
  }

  @override
  List<Object?> get props => [
        settings,
        phase,
        status,
        remaining.inSeconds,
        focusInCycle,
        completedToday,
        completedSignal,
        lastCompleted,
      ];
}
