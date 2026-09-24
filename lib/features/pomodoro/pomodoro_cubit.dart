import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pomodoro_settings.dart';

enum TimerStatus { idle, running, paused }

class PomodoroState extends Equatable {
  const PomodoroState({
    required this.settings,
    required this.phase,
    required this.status,
    required this.remaining,
    required this.focusInCycle,
    required this.completedToday,
    this.completedSignal = 0,
    this.lastCompleted,
  });

  final PomodoroSettings settings;
  final PomodoroPhase phase;
  final TimerStatus status;
  final Duration remaining;
  final int focusInCycle;
  final int completedToday;

  /// Increments each time a phase finishes on its own; UI listens for it.
  final int completedSignal;
  final PomodoroPhase? lastCompleted;

  Duration get total => settings.durationOf(phase);

  double get progress {
    final totalMs = total.inMilliseconds;
    if (totalMs == 0) return 0;
    return (1 - remaining.inMilliseconds / totalMs).clamp(0.0, 1.0);
  }

  PomodoroState copyWith({
    PomodoroSettings? settings,
    PomodoroPhase? phase,
    TimerStatus? status,
    Duration? remaining,
    int? focusInCycle,
    int? completedToday,
    int? completedSignal,
    PomodoroPhase? lastCompleted,
  }) {
    return PomodoroState(
      settings: settings ?? this.settings,
      phase: phase ?? this.phase,
      status: status ?? this.status,
      remaining: remaining ?? this.remaining,
      focusInCycle: focusInCycle ?? this.focusInCycle,
      completedToday: completedToday ?? this.completedToday,
      completedSignal: completedSignal ?? this.completedSignal,
      lastCompleted: lastCompleted ?? this.lastCompleted,
    );
  }

  @override
  List<Object?> get props => [
        settings,
        phase,
        status,
        remaining.inSeconds,
        focusInCycle,
        completedToday,
        completedSignal,
        lastCompleted,
      ];
}

/// Countdown is derived from an absolute end time, so it stays correct
/// while the app is backgrounded. Timer state is persisted so a killed
/// process resumes where it was.
class PomodoroCubit extends Cubit<PomodoroState> {
  PomodoroCubit(this._prefs) : super(_restore(_prefs)) {
    _endsAt = _readEndsAt(_prefs);
    if (state.status == TimerStatus.running) {
      if (_endsAt == null || !_endsAt!.isAfter(DateTime.now())) {
        // Phase ended while the app was not running.
        _complete(silent: true);
      } else {
        _startTicker();
      }
    }
  }

  final SharedPreferences _prefs;
  Timer? _ticker;
  DateTime? _endsAt;

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

  void _startTicker() {
    _ticker?.cancel();
    // Sub-second interval so the display never lags a whole second behind.
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void _tick() {
    final endsAt = _endsAt;
    if (endsAt == null) return;
    final left = endsAt.difference(DateTime.now());
    if (left <= Duration.zero) {
      _complete();
    } else if (left.inSeconds != state.remaining.inSeconds) {
      emit(state.copyWith(remaining: left));
    }
  }

  /// [silent] skips haptics and auto-start (used when restoring a phase that
  /// ended while the app was closed).
  void _complete({bool silent = false}) {
    _ticker?.cancel();
    _endsAt = null;

    final finished = state.phase;
    final t = nextPhase(
      current: finished,
      focusInCycle: state.focusInCycle,
      settings: state.settings,
      completed: true,
    );

    final sameDay = _prefs.getString(_kTodayDate) == _todayKey();
    final todayBase = sameDay ? state.completedToday : 0;
    final today =
        finished == PomodoroPhase.focus ? todayBase + 1 : todayBase;

    emit(state.copyWith(
      phase: t.next,
      focusInCycle: t.focusInCycle,
      status: TimerStatus.idle,
      remaining: state.settings.durationOf(t.next),
      completedToday: today,
      completedSignal: silent ? null : state.completedSignal + 1,
      lastCompleted: finished,
    ));

    _prefs.setString(_kTodayDate, _todayKey());
    _prefs.setInt(_kTodayCount, today);

    if (!silent) {
      HapticFeedback.heavyImpact();
      if (state.settings.autoStartNext) {
        start();
        return;
      }
    }
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
    return super.close();
  }
}
