import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/theme_cubit.dart';

/// Cycles System → Light → Dark. Placed in every tab's AppBar.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) => IconButton(
        icon: Icon(switch (mode) {
          ThemeMode.system => Icons.brightness_auto,
          ThemeMode.light => Icons.light_mode,
          ThemeMode.dark => Icons.dark_mode,
        }),
        tooltip: switch (mode) {
          ThemeMode.system => 'Theme: System',
          ThemeMode.light => 'Theme: Light',
          ThemeMode.dark => 'Theme: Dark',
        },
        onPressed: () => context.read<ThemeCubit>().cycle(),
      ),
    );
  }
}
