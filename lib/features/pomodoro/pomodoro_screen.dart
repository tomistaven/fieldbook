import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/theme_toggle_button.dart';
import 'pomodoro_cubit.dart';
import 'pomodoro_settings.dart';
import 'widgets/settings_sheet.dart';
import 'widgets/timer_ring.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus'),
        actions: [
          const ThemeToggleButton(),
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
                  _CycleDots(
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

/// One dot per focus session in the current cycle toward a long break.
class _CycleDots extends StatelessWidget {
  const _CycleDots({
    required this.done,
    required this.total,
    required this.color,
  });

  final int done;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < done ? color : Colors.transparent,
              border: Border.all(color: i < done ? color : outline, width: 1.5),
            ),
          ),
      ],
    );
  }
}
