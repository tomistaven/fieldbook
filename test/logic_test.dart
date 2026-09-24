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

  group('Pomodoro phaseEnds', () {
    final start = DateTime(2026, 9, 25, 9);
    const auto = PomodoroSettings(
      focusMinutes: 25,
      shortBreakMinutes: 5,
      longBreakMinutes: 15,
      sessionsBeforeLongBreak: 2,
      autoStartNext: true,
    );

    List<PhaseEnd> ends(
      PomodoroSettings settings, {
      PomodoroPhase current = PomodoroPhase.focus,
      int focusInCycle = 0,
      bool unattended = true,
      int take = 20,
    }) =>
        phaseEnds(
          current: current,
          focusInCycle: focusInCycle,
          settings: settings,
          endsAt: start,
          stopAfterLongBreak: unattended,
        ).take(take).toList();

    test('without auto-start only the current phase ends', () {
      final e = ends(const PomodoroSettings(sessionsBeforeLongBreak: 2));
      expect(e, hasLength(1));
      expect(e.single.next, PomodoroPhase.shortBreak);
      expect(e.single.continues, isFalse);
    });

    test('unattended chain runs to the end of the next long break', () {
      final e = ends(auto);
      expect(e.map((x) => x.finished), [
        PomodoroPhase.focus,
        PomodoroPhase.shortBreak,
        PomodoroPhase.focus,
        PomodoroPhase.longBreak,
      ]);
      expect(e.last.next, PomodoroPhase.focus);
      expect(e.last.focusInCycle, 0);
      expect(e.last.continues, isFalse);
    });

    test('each end is timed from the previous end', () {
      final e = ends(auto);
      expect(e[0].at, start);
      expect(e[1].at, start.add(const Duration(minutes: 5)));
      expect(e[2].at, start.add(const Duration(minutes: 30)));
      expect(e[3].at, start.add(const Duration(minutes: 45)));
    });

    test('starting in a long break stops after it', () {
      final e = ends(auto, current: PomodoroPhase.longBreak, focusInCycle: 2);
      expect(e, hasLength(1));
      expect(e.single.continues, isFalse);
    });

    test('attended chain does not stop at the long break', () {
      final e = ends(auto, unattended: false);
      expect(e, hasLength(20));
      expect(e.every((x) => x.continues), isTrue);
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