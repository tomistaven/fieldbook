import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            children: [
              const _SectionHeader('Appearance'),
              for (final option in _themeOptions)
                _ThemeOption(
                  label: option.label,
                  icon: option.icon,
                  selected: state.themeMode == option.mode,
                  onTap: () =>
                      context.read<SettingsCubit>().setTheme(option.mode),
                ),
              const _SectionHeader('Layout'),
              SwitchListTile(
                secondary: const Icon(Icons.swap_horiz),
                title: const Text('Add buttons on the left'),
                subtitle: const Text(
                  'Moves the add button on Todos, Shopping, Notes and Cards '
                  'to the left side',
                ),
                value: state.addButtonsOnLeft,
                onChanged: context.read<SettingsCubit>().setAddButtonsOnLeft,
              ),
            ],
          );
        },
      ),
    );
  }

  static const _themeOptions = [
    (label: 'System default', icon: Icons.brightness_auto, mode: ThemeMode.system),
    (label: 'Light', icon: Icons.light_mode, mode: ThemeMode.light),
    (label: 'Dark', icon: Icons.dark_mode, mode: ThemeMode.dark),
  ];
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Icon(icon, color: selected ? accent : null),
      title: Text(label),
      trailing: selected ? Icon(Icons.check_rounded, color: accent) : null,
      onTap: onTap,
    );
  }
}