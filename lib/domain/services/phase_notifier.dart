import '../entities/pomodoro.dart';

/// Alerts the user when a Pomodoro phase ends while the app is not visible.
///
/// Kept abstract so [PomodoroCubit] does not depend on a notification plugin
/// and can be tested with a fake.
abstract interface class PhaseNotifier {
  /// Asks the OS for permission to post notifications. Returns whether it
  /// was granted.
  Future<bool> requestPermission();

  /// Schedules one alert per entry, replacing any already scheduled.
  /// Entries that are not in the future are skipped.
  Future<void> schedulePhaseEnds(List<PhaseEnd> ends);

  /// Cancels all scheduled alerts and removes delivered ones from the tray.
  Future<void> cancelPhaseEnds();

  /// Whether the app process was started by tapping an alert.
  bool get launchedFromAlert;

  /// Emits when an alert is tapped while the app process is still alive.
  Stream<void> get alertOpened;
}