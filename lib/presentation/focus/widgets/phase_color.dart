import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/pomodoro.dart';

/// Display color per phase; kept out of the domain enum so the domain layer
/// has no Flutter dependency.
extension PomodoroPhaseColor on PomodoroPhase {
  Color get color => switch (this) {
    PomodoroPhase.focus => AppColors.focus,
    PomodoroPhase.shortBreak => AppColors.shortBreak,
    PomodoroPhase.longBreak => AppColors.longBreak,
  };
}
