import 'package:flutter/material.dart';

import '../../../domain/entities/pomodoro.dart';

Future<PomodoroSettings?> showPomodoroSettings(
  BuildContext context,
  PomodoroSettings current,
) {
  return showModalBottomSheet<PomodoroSettings>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SettingsSheet(initial: current),
  );
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet({required this.initial});

  final PomodoroSettings initial;

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late PomodoroSettings _s = widget.initial;

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
