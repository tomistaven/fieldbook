import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/pomodoro.dart';
import '../../settings/widgets/settings_button.dart';
import '../cubit/pomodoro_cubit.dart';
import '../cubit/pomodoro_state.dart';
import '../widgets/cycle_dots.dart';
import '../widgets/phase_color.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/timer_ring.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus'),
        actions: [
          IconButton(
            tooltip: 'Timer settings',
            icon: const Icon(Icons.tune),
            onPressed: () async {
              final cubit = context.read<PomodoroCubit>();
              final updated =
                  await showPomodoroSettings(context, cubit.state.settings);
              if (updated != null) await cubit.updateSettings(updated);
            },
          ),
          const SettingsButton(),
        ],
      ),
      body: BlocBuilder<PomodoroCubit, PomodoroState>(
        builder: (context, state) {
          final cubit = context.read<PomodoroCubit>();
          final running = state.status == TimerStatus.running;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CycleDots(
                    done: state.focusInCycle,
                    total: state.settings.sessionsBeforeLongBreak,
                    color: PomodoroPhase.focus.color,
                  ),
                  const SizedBox(height: 24),
                  TimerRing(
                    progress: state.progress,
                    remaining: state.remaining,
                    label: state.phase.label,
                    color: state.phase.color,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Reset',
                        iconSize: 28,
                        icon: const Icon(Icons.replay),
                        onPressed: state.status == TimerStatus.idle
                            ? null
                            : cubit.reset,
                      ),
                      const SizedBox(width: 24),
                      SizedBox.square(
                        dimension: 72,
                        child: FloatingActionButton(
                          heroTag: 'pomodoro-fab',
                          backgroundColor: state.phase.color,
                          tooltip: running ? 'Pause' : 'Start',
                          onPressed: running ? cubit.pause : cubit.start,
                          child: Icon(
                            running ? Icons.pause : Icons.play_arrow,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        tooltip: 'Skip to next phase',
                        iconSize: 28,
                        icon: const Icon(Icons.skip_next),
                        onPressed: cubit.skip,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Focus sessions today: ${state.completedToday}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
