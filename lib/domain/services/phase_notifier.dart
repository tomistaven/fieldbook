import '../entities/pomodoro.dart';

/// Alerts the user when a Pomodoro phase ends while the app is not visible.
///
/// Kept abstract so [PomodoroCubit] does not depend on a notification plugin
/// and can be tested with a fake.
abstract interface class PhaseNotifier {
  /// Asks the OS for permission to post notifications. Returns whether it
  /// was granted.
  Future<bool> requestPermission();

  /// Schedules a single alert at [at]. Replaces any alert already scheduled.
  /// Does nothing if [at] is not in the future.
  Future<void> schedulePhaseEnd({
    required DateTime at,
    required PomodoroPhase finished,
    required PomodoroPhase next,
  });

  /// Cancels the scheduled alert and removes it from the tray if shown.
  Future<void> cancelPhaseEnd();

  /// Whether the app process was started by tapping the alert.
  bool get launchedFromAlert;

  /// Emits when the alert is tapped while the app process is still alive.
  Stream<void> get alertOpened;
}