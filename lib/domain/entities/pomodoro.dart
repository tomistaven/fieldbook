import 'package:equatable/equatable.dart';

enum PomodoroPhase {
  focus('Focus'),
  shortBreak('Short break'),
  longBreak('Long break');

  const PomodoroPhase(this.label);
  final String label;
}

class PomodoroSettings extends Equatable {
  const PomodoroSettings({
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsBeforeLongBreak = 4,
    this.autoStartNext = false,
  });

  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int sessionsBeforeLongBreak;
  final bool autoStartNext;

  Duration durationOf(PomodoroPhase phase) => Duration(
        minutes: switch (phase) {
          PomodoroPhase.focus => focusMinutes,
          PomodoroPhase.shortBreak => shortBreakMinutes,
          PomodoroPhase.longBreak => longBreakMinutes,
        },
      );

  PomodoroSettings copyWith({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsBeforeLongBreak,
    bool? autoStartNext,
  }) {
    return PomodoroSettings(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      sessionsBeforeLongBreak:
          sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
      autoStartNext: autoStartNext ?? this.autoStartNext,
    );
  }

  @override
  List<Object?> get props => [
        focusMinutes,
        shortBreakMinutes,
        longBreakMinutes,
        sessionsBeforeLongBreak,
        autoStartNext,
      ];
}

/// Result of finishing (or skipping) a phase.
class PhaseTransition {
  const PhaseTransition(this.next, this.focusInCycle);

  final PomodoroPhase next;

  /// Completed focus sessions since the last long break.
  final int focusInCycle;
}

/// Pure phase logic, kept separate from the cubit so it is unit-testable.
///
/// A completed focus session counts toward the cycle; a skipped one does not.
/// After [PomodoroSettings.sessionsBeforeLongBreak] counted sessions the next
/// break is long, and the cycle resets once that long break ends.
PhaseTransition nextPhase({
  required PomodoroPhase current,
  required int focusInCycle,
  required PomodoroSettings settings,
  required bool completed,
}) {
  switch (current) {
    case PomodoroPhase.focus:
      final count = completed ? focusInCycle + 1 : focusInCycle;
      final isLong = count >= settings.sessionsBeforeLongBreak;
      return PhaseTransition(
        isLong ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak,
        count,
      );
    case PomodoroPhase.shortBreak:
      return PhaseTransition(PomodoroPhase.focus, focusInCycle);
    case PomodoroPhase.longBreak:
      return const PhaseTransition(PomodoroPhase.focus, 0);
  }
}
