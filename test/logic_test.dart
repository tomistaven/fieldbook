import 'package:fieldbook/domain/entities/flashcard.dart';
import 'package:fieldbook/domain/entities/pomodoro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pomodoro nextPhase', () {
    const settings = PomodoroSettings(sessionsBeforeLongBreak: 4);

    PhaseTransition finish(PomodoroPhase p, int n, {bool completed = true}) =>
        nextPhase(
          current: p,
          focusInCycle: n,
          settings: settings,
          completed: completed,
        );

    test('completed focus leads to short break and counts', () {
      final t = finish(PomodoroPhase.focus, 0);
      expect(t.next, PomodoroPhase.shortBreak);
      expect(t.focusInCycle, 1);
    });

    test('fourth completed focus leads to long break', () {
      final t = finish(PomodoroPhase.focus, 3);
      expect(t.next, PomodoroPhase.longBreak);
      expect(t.focusInCycle, 4);
    });

    test('skipped focus does not count', () {
      final t = finish(PomodoroPhase.focus, 3, completed: false);
      expect(t.next, PomodoroPhase.shortBreak);
      expect(t.focusInCycle, 3);
    });

    test('long break resets the cycle', () {
      final t = finish(PomodoroPhase.longBreak, 4);
      expect(t.next, PomodoroPhase.focus);
      expect(t.focusInCycle, 0);
    });

    test('short break keeps the cycle count', () {
      final t = finish(PomodoroPhase.shortBreak, 2);
      expect(t.next, PomodoroPhase.focus);
      expect(t.focusInCycle, 2);
    });
  });

  group('Leitner', () {
    test('correct answer moves up one box, capped at max', () {
      expect(Leitner.next(1, knew: true), 2);
      expect(Leitner.next(Leitner.maxBox, knew: true), Leitner.maxBox);
    });

    test('miss resets to box 1', () {
      expect(Leitner.next(4, knew: false), Leitner.minBox);
    });
  });
}
