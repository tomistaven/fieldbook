import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/pomodoro.dart';
import '../../domain/services/phase_notifier.dart';

/// [PhaseNotifier] backed by flutter_local_notifications.
///
/// The alert is a one-shot alarm at an absolute instant, so it is scheduled
/// in UTC. The device time zone would only matter for recurring
/// (wall-clock) schedules, which is why flutter_timezone is not needed.
class NotificationService implements PhaseNotifier {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// A single id: only one phase can be pending at a time, and reusing the id
  /// makes a new schedule replace the previous one.
  static const int _phaseEndId = 1;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'pomodoro_phase_end',
    'Pomodoro',
    channelDescription: 'Alerts when a focus session or break ends.',
    importance: Importance.high,
    priority: Priority.high,
  );

  Future<void> init() async {
    // Darwin permission flags are off so iOS does not prompt at launch; the
    // prompt is shown on the first timer start instead.
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  @override
  Future<void> schedulePhaseEnd({
    required DateTime at,
    required PomodoroPhase finished,
    required PomodoroPhase next,
  }) async {
    // zonedSchedule throws for a date in the past.
    if (!at.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: _phaseEndId,
      title: '${finished.label} finished',
      body: 'Up next: ${next.label}',
      scheduledDate: tz.TZDateTime.from(at, tz.UTC),
      notificationDetails: const NotificationDetails(
        android: _androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancelPhaseEnd() => _plugin.cancel(id: _phaseEndId);
}