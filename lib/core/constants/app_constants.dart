/// App-wide limits and durations, kept in one place instead of scattered
/// through widgets.
abstract final class AppConstants {
  static const String appName = 'Fieldbook';
  static const String databaseFile = 'fieldbook.db';

  static const int maxTodoTitleLength = 200;
  static const int maxShoppingNameLength = 120;
  static const int maxDeckNameLength = 80;

  /// Delay after the last keystroke before a note is saved.
  static const Duration noteAutosaveDelay = Duration(milliseconds: 600);

  /// Pomodoro ticker interval; sub-second so the display never lags a
  /// whole second behind the real remaining time.
  static const Duration timerTick = Duration(milliseconds: 250);
}
