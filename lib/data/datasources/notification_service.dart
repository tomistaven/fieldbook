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

  /// Ids are the entry's position plus one. The app posts no other
  /// notifications, so clearing everything first is safe.
  @override
  Future<void> schedulePhaseEnds(List<PhaseEnd> ends) async {
    await _plugin.cancelAll();
    final now = DateTime.now();
    for (final (i, end) in ends.indexed) {
      // zonedSchedule throws for a date in the past.
      if (!end.at.isAfter(now)) continue;
      await _schedule(id: i + 1, end: end);
    }
  }

  Future<void> _schedule({required int id, required PhaseEnd end}) {
    return _plugin.zonedSchedule(
      id: id,
      title: '${end.finished.label} finished',
      body: end.continues
          ? '${end.next.label} has started'
          : 'Up next: ${end.next.label}',
      scheduledDate: tz.TZDateTime.from(end.at, tz.UTC),
      notificationDetails: const NotificationDetails(android: _androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancelPhaseEnds() => _plugin.cancelAll();
}