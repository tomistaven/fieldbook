import 'package:flutter/material.dart';

import '../screens/settings_screen.dart';

/// Opens [SettingsScreen]. Placed in every tab's AppBar; a sixth bottom-nav
/// destination would exceed Material's five-item guideline.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Settings',
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
      ),
    );
  }
}
