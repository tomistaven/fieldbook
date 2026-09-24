import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/pomodoro.dart';
import '../../../domain/services/phase_notifier.dart';
import 'pomodoro_state.dart';

/// Countdown is derived from an absolute end time, so it stays correct
/// while the app is backgrounded. Timer state is persisted so a killed
/// process resumes where it was.
///
/// System notifications are scheduled only while the app is hidden; in the
/// foreground the shell's phase banner covers the alert.
///
/// With auto-start, phases chain from the previous end time (see
/// [phaseEnds]). While nobody is watching (app hidden or closed) the chain
/// stops at the end of the next long break.
class PomodoroCubit extends Cubit<PomodoroState> {
  PomodoroCubit(this._prefs, this._notifier) : super(_restore(_prefs)) {
    _lifecycle = AppLifecycleListener(onHide: _onHide, onShow: _onShow);
    _scheduleMidnight();
    // Created at launch, so the app is visible: any alert still pending or
    // shown from a previous session is stale.
    unawaited(_notifier.cancelPhaseEnds());
    _endsAt = _readEndsAt(_prefs);
    if (state.status == TimerStatus.running) {
      // A missing end time means inconsistent stored state; treat the phase
      // as ended.
      final endsAt = _endsAt ??= DateTime.now();
      if (endsAt.isAfter(DateTime.now())) {
        _startTicker();
      } else {
        // Ended while the process was dead. Silent: the shell is not
        // listening yet, and a banner at launch would be stale anyway.
        _advance(unattended: true, silent: true);
      }
    }
  }

  /// A completion processed within this window of its end time is live and
  /// gets haptics; anything later is a catch-up.
  static const _liveWindow = Duration(seconds: 1);

  final SharedPreferences _prefs;
  final PhaseNotifier _notifier;
  late final AppLifecycleListener _lifecycle;
  Timer? _ticker;
  Timer? _midnight;
  DateTime? _endsAt;
  bool _hidden = false;

  // Preference keys
  static const _kFocus = 'pomo.focusMinutes';
  static const _kShort = 'pomo.shortBreakMinutes';
  static const _kLong = 'pomo.longBreakMinutes';
  static const _kSessions = 'pomo.sessionsBeforeLongBreak';
  static const _kAuto = 'pomo.autoStartNext';
  static const _kPhase = 'pomo.phase';
  static const _kStatus = 'pomo.status';
  static const _kEndsAt = 'pomo.endsAtMs';
  static const _kRemaining = 'pomo.remainingMs';
  static const _kCycle = 'pomo.focusInCycle';
  static const _kTodayDate = 'pomo.todayDate';
  static const _kTodayCount = 'pomo.todayCount';
  static const _kNotifyAsked = 'pomo.notificationPermissionAsked';

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  static PomodoroState _restore(SharedPreferences p) {
    const defaults = PomodoroSettings();
    final settings = PomodoroSettings(
      focusMinutes: p.getInt(_kFocus) ?? defaults.focusMinutes,
      shortBreakMinutes: p.getInt(_kShort) ?? defaults.shortBreakMinutes,
      longBreakMinutes: p.getInt(_kLong) ?? defaults.longBreakMinutes,
      sessionsBeforeLongBreak:
          p.getInt(_kSessions) ?? defaults.sessionsBeforeLongBreak,
      autoStartNext: p.getBool(_kAuto) ?? defaults.autoStartNext,
    );
    final phase = PomodoroPhase.values.firstWhere(
      (v) => v.name == p.getString(_kPhase),
      orElse: () => PomodoroPhase.focus,
    );
    final status = TimerStatus.values.firstWhere(
      (v) => v.name == p.getString(_kStatus),
      orElse: () => TimerStatus.idle,
    );
    final remainingMs = p.getInt(_kRemaining);
    final today =
        p.getString(_kTodayDate) == _todayKey() ? p.getInt(_kTodayCount) : 0;

    Duration remaining = settings.durationOf(phase);
    if (status == TimerStatus.paused && remainingMs != null) {
      remaining = Duration(milliseconds: remainingMs);
    } else if (status == TimerStatus.running) {
      final endsAt = _readEndsAt(p);
      if (endsAt != null) {
        final left = endsAt.difference(DateTime.now());
        remaining = left.isNegative ? Duration.zero : left;
      }
    }

    return PomodoroState(
      settings: settings,
      phase: phase,
      status: status,
      remaining: remaining,
      focusInCycle: p.getInt(_kCycle) ?? 0,
      completedToday: today ?? 0,
    );
  }

  static DateTime? _readEndsAt(SharedPreferences p) {
    final ms = p.getInt(_kEndsAt);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  void start() {
    if (state.status == TimerStatus.running) return;
    _endsAt = DateTime.now().add(state.remaining);
    emit(state.copyWith(status: TimerStatus.running));
    _startTicker();
    _persistTimer();
    unawaited(_askNotificationPermissionOnce());
  }

  void pause() {
    if (state.status != TimerStatus.running) return;
    _ticker?.cancel();
    final left = _endsAt!.difference(DateTime.now());
    _endsAt = null;
    emit(state.copyWith(
      status: TimerStatus.paused,
      remaining: left.isNegative ? Duration.zero : left,
    ));
    _persistTimer();
  }

  /// Back to the start of the current phase.
  void reset() {
    _ticker?.cancel();
    _endsAt = null;
    emit(state.copyWith(status: TimerStatus.idle, remaining: state.total));
    _persistTimer();
  }

  /// Moves to the next phase without counting the current one.
  void skip() {
    _ticker?.cancel();
    _endsAt = null;
    final t = nextPhase(
      current: state.phase,
      focusInCycle: state.focusInCycle,
      settings: state.settings,
      completed: false,
    );
    emit(state.copyWith(
      phase: t.next,
      focusInCycle: t.focusInCycle,
      status: TimerStatus.idle,
      remaining: state.settings.durationOf(t.next),
    ));
    _persistTimer();
  }

  /// Zeroes today's completed-session count. The cycle count is left alone;
  /// it tracks progress toward the next long break, not the day.
  Future<void> resetToday() async {
    emit(state.copyWith(completedToday: 0));
    await _prefs.setString(_kTodayDate, _todayKey());
    await _prefs.setInt(_kTodayCount, 0);
  }

  /// Starts over at the first focus session of a cycle: clears the cycle
  /// count, stops the timer and returns to a full focus phase. The daily
  /// count is kept.
  void resetCycle() {
    _ticker?.cancel();
    _endsAt = null;
    emit(state.copyWith(
      phase: PomodoroPhase.focus,
      focusInCycle: 0,
      status: TimerStatus.idle,
      remaining: state.settings.durationOf(PomodoroPhase.focus),
    ));
    _persistTimer();
  }

  Future<void> updateSettings(PomodoroSettings s) async {
    final idle = state.status == TimerStatus.idle;
    emit(state.copyWith(
      settings: s,
      // A running or paused timer keeps its remaining time.
      remaining: idle ? s.durationOf(state.phase) : null,
    ));
    await _prefs.setInt(_kFocus, s.focusMinutes);
    await _prefs.setInt(_kShort, s.shortBreakMinutes);
    await _prefs.setInt(_kLong, s.longBreakMinutes);
    await _prefs.setInt(_kSessions, s.sessionsBeforeLongBreak);
    await _prefs.setBool(_kAuto, s.autoStartNext);
    await _persistTimer();
  }

  void _onHide() {
    _hidden = true;
    _schedulePhaseEnds();
  }

  void _onShow() {
    // Settle phases that ended while hidden before clearing _hidden, so they
    // get the same cap as the notifications that announced them.
    final endsAt = _endsAt;
    if (endsAt != null && !endsAt.isAfter(DateTime.now())) {
      _advance(unattended: true);
    }
    _hidden = false;
    // A backgrounded process may be frozen past midnight, so the timer
    // below cannot be relied on to have fired.
    _rollOverDay();
    _scheduleMidnight();
    // Also clears delivered alerts from the tray; the in-app banner has
    // taken over.
    unawaited(_notifier.cancelPhaseEnds());
  }

  /// One notification per phase end until the chain stops, which is the
  /// same point [_advance] stops at for unattended time.
  void _schedulePhaseEnds() {
    final endsAt = _endsAt;
    if (state.status != TimerStatus.running || endsAt == null) return;
    final ends = phaseEnds(
      current: state.phase,
      focusInCycle: state.focusInCycle,
      settings: state.settings,
      endsAt: endsAt,
      stopAfterLongBreak: true,
    ).toList();
    unawaited(_notifier.schedulePhaseEnds(ends));
  }

  /// Prompts on the first start rather than at launch, so the request has
  /// visible context. Asked once; after that the choice is left to system
  /// settings.
  Future<void> _askNotificationPermissionOnce() async {
    if (_prefs.getBool(_kNotifyAsked) ?? false) return;
    await _prefs.setBool(_kNotifyAsked, true);
    await _notifier.requestPermission();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(AppConstants.timerTick, (_) => _tick());
  }

  /// Clears the daily count at the next local midnight while the app is open.
  /// DateTime normalises day + 1 across month and year ends, and building it
  /// from date parts keeps it at local midnight across DST changes.
  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(next.difference(now), () {
      _rollOverDay();
      _scheduleMidnight();
    });
  }

  /// The count is otherwise only re-dated at launch and on completion, so
  /// an app left open past midnight would keep showing yesterday's count.
  void _rollOverDay() {
    if (state.completedToday != 0 &&
        _prefs.getString(_kTodayDate) != _todayKey()) {
      emit(state.copyWith(completedToday: 0));
    }
  }

  void _tick() {
    final endsAt = _endsAt;
    if (endsAt == null) return;
    final left = endsAt.difference(DateTime.now());
    if (left <= Duration.zero) {
      _advance(unattended: _hidden);
    } else if (left.inSeconds != state.remaining.inSeconds) {
      emit(state.copyWith(remaining: left));
    }
  }

  static bool _isToday(DateTime t) {
    final n = DateTime.now();
    return t.year == n.year && t.month == n.month && t.day == n.day;
  }

  /// Completes every phase whose end has passed. With auto-start, the next
  /// phase is timed from the previous end, so phases that ended while the
  /// app was frozen or closed keep their schedule, and the timer is left
  /// running if the latest phase is still in progress.
  ///
  /// [unattended] stops the chain after the next long break. [silent]
  /// suppresses the banner signal.
  void _advance({required bool unattended, bool silent = false}) {
    final endsAt = _endsAt;
    if (endsAt == null) return;
    final now = DateTime.now();

    PhaseEnd? last;
    DateTime? runningUntil;
    var focusToday = 0;
    for (final end in phaseEnds(
      current: state.phase,
      focusInCycle: state.focusInCycle,
      settings: state.settings,
      endsAt: endsAt,
      stopAfterLongBreak: unattended,
    )) {
      if (end.at.isAfter(now)) {
        runningUntil = end.at;
        break;
      }
      last = end;
      // Sessions that ended on an earlier day belong to that day's count.
      if (end.finished == PomodoroPhase.focus && _isToday(end.at)) {
        focusToday++;
      }
      if (!end.continues) break;
    }
    if (last == null) return;

    _ticker?.cancel();
    _endsAt = runningUntil;

    final sameDay = _prefs.getString(_kTodayDate) == _todayKey();
    final today = (sameDay ? state.completedToday : 0) + focusToday;

    emit(state.copyWith(
      phase: last.next,
      focusInCycle: last.focusInCycle,
      status: runningUntil != null ? TimerStatus.running : TimerStatus.idle,
      remaining: runningUntil != null
          ? runningUntil.difference(now)
          : state.settings.durationOf(last.next),
      completedToday: today,
      completedSignal: silent ? null : state.completedSignal + 1,
      lastCompleted: last.finished,
    ));

    _prefs.setString(_kTodayDate, _todayKey());
    _prefs.setInt(_kTodayCount, today);

    if (!silent && now.difference(last.at) < _liveWindow) {
      HapticFeedback.heavyImpact();
    }
    if (runningUntil != null) _startTicker();
    _persistTimer();
  }

  Future<void> _persistTimer() async {
    await _prefs.setString(_kPhase, state.phase.name);
    await _prefs.setString(_kStatus, state.status.name);
    await _prefs.setInt(_kCycle, state.focusInCycle);
    if (_endsAt != null) {
      await _prefs.setInt(_kEndsAt, _endsAt!.millisecondsSinceEpoch);
    } else {
      await _prefs.remove(_kEndsAt);
    }
    await _prefs.setInt(_kRemaining, state.remaining.inMilliseconds);
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    _midnight?.cancel();
    _lifecycle.dispose();
    return super.close();
  }
}