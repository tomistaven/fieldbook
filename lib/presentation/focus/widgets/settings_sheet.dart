import 'package:flutter/material.dart';

import '../../../core/widgets/dialogs.dart';
import '../../../domain/entities/pomodoro.dart';

/// Returns the edited settings on Save, or null if dismissed.
///
/// [onResetToday] runs immediately after confirmation, independent of Save,
/// because the daily count is data rather than a setting.
Future<PomodoroSettings?> showPomodoroSettings(
  BuildContext context,
  PomodoroSettings current, {
  required int completedToday,
  required Future<void> Function() onResetToday,
}) {
  return showModalBottomSheet<PomodoroSettings>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SettingsSheet(
      initial: current,
      completedToday: completedToday,
      onResetToday: onResetToday,
    ),
  );
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet({
    required this.initial,
    required this.completedToday,
    required this.onResetToday,
  });

  final PomodoroSettings initial;
  final int completedToday;
  final Future<void> Function() onResetToday;

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late PomodoroSettings _s = widget.initial;
  late int _today = widget.completedToday;

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Focus sessions today: $_today',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: _today == 0 ? null : _confirmResetToday,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
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