import 'package:flutter/material.dart';

import '../../../core/widgets/dialogs.dart';
import '../../../domain/entities/pomodoro.dart';
import '../cubit/pomodoro_state.dart';

/// Returns the edited settings on Save, or null if dismissed.
///
/// [onResetToday] and [onResetCycle] run immediately after confirmation,
/// independent of Save, because they act on timer data rather than settings.
Future<PomodoroSettings?> showPomodoroSettings(
  BuildContext context,
  PomodoroState state, {
  required Future<void> Function() onResetToday,
  required VoidCallback onResetCycle,
}) {
  return showModalBottomSheet<PomodoroSettings>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SettingsSheet(
      state: state,
      onResetToday: onResetToday,
      onResetCycle: onResetCycle,
    ),
  );
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet({
    required this.state,
    required this.onResetToday,
    required this.onResetCycle,
  });

  final PomodoroState state;
  final Future<void> Function() onResetToday;
  final VoidCallback onResetCycle;

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late PomodoroSettings _s = widget.state.settings;
  late int _today = widget.state.completedToday;
  late int _cycleCount = widget.state.focusInCycle;
  late bool _atCycleStart = widget.state.atCycleStart;

  Future<void> _confirmResetToday() async {
    final confirmed = await showConfirmDialog(
      context,
      title: "Reset today's count?",
      message: "Today's focus sessions go back to 0. Timer settings and the "
          'current cycle are not changed.',
      confirmLabel: 'Reset',
    );
    if (!confirmed || !mounted) return;
    await widget.onResetToday();
    if (mounted) setState(() => _today = 0);
  }

  Future<void> _confirmResetCycle() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reset cycle?',
      message: 'The cycle dots go back to 0 and the timer returns to the '
          "start of a focus session. Today's count is not changed.",
      confirmLabel: 'Reset',
    );
    if (!confirmed || !mounted) return;
    widget.onResetCycle();
    setState(() {
      _cycleCount = 0;
      _atCycleStart = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Timer settings',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            _Stepper(
              label: 'Focus',
              suffix: 'min',
              value: _s.focusMinutes,
              min: 1,
              max: 120,
              onChanged: (v) => setState(() => _s = _s.copyWith(focusMinutes: v)),
            ),
            _Stepper(
              label: 'Short break',
              suffix: 'min',
              value: _s.shortBreakMinutes,
              min: 1,
              max: 60,
              onChanged: (v) =>
                  setState(() => _s = _s.copyWith(shortBreakMinutes: v)),
            ),
            _Stepper(
              label: 'Long break',
              suffix: 'min',
              value: _s.longBreakMinutes,
              min: 1,
              max: 90,
              onChanged: (v) =>
                  setState(() => _s = _s.copyWith(longBreakMinutes: v)),
            ),
            _Stepper(
              label: 'Sessions before long break',
              value: _s.sessionsBeforeLongBreak,
              min: 1,
              max: 12,
              onChanged: (v) =>
                  setState(() => _s = _s.copyWith(sessionsBeforeLongBreak: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start next phase automatically'),
              value: _s.autoStartNext,
              onChanged: (v) => setState(() => _s = _s.copyWith(autoStartNext: v)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () =>
                      setState(() => _s = const PomodoroSettings()),
                  child: const Text('Defaults'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _s),
                  child: const Text('Save'),
                ),
              ],
            ),
            const Divider(height: 24),
            _ResetRow(
              label: 'Focus sessions today: $_today',
              onReset: _today == 0 ? null : _confirmResetToday,
            ),
            _ResetRow(
              label: 'Sessions this cycle: $_cycleCount',
              onReset: _atCycleStart ? null : _confirmResetCycle,
            ),
          ],
        ),
      ),
    );
  }
}

/// A count with a Reset button, disabled when [onReset] is null.
class _ResetRow extends StatelessWidget {
  const _ResetRow({required this.label, required this.onReset});

  final String label;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        TextButton(onPressed: onReset, child: const Text('Reset')),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.suffix,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final String? suffix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 64,
            child: Text(
              suffix == null ? '$value' : '$value $suffix',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}