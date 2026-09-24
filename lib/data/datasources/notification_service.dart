import 'dart:async';

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

  // App-lifetime singleton, so the controller is never closed.
  final StreamController<void> _alertOpened = StreamController.broadcast();
  bool _launchedFromAlert = false;

  @override
  bool get launchedFromAlert => _launchedFromAlert;

  @override
  Stream<void> get alertOpened => _alertOpened.stream;

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
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
      // Tap while the process is alive. A tap that starts the process does
      // not reach this callback; it is read from the launch details below.
      onDidReceiveNotificationResponse: (_) => _alertOpened.add(null),
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    _launchedFromAlert = launch?.didNotificationLaunchApp ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
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
      notificationDetails: const NotificationDetails(android: _androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancelPhaseEnd() => _plugin.cancel(id: _phaseEndId);
}