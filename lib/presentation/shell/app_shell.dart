import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pomodoro.dart';
import '../../domain/services/phase_notifier.dart';
import '../../injection_container.dart';
import '../flashcards/screens/decks_screen.dart';
import '../focus/cubit/pomodoro_cubit.dart';
import '../focus/cubit/pomodoro_state.dart';
import '../focus/screens/focus_screen.dart';
import '../focus/widgets/phase_color.dart';
import '../notes/screens/notes_screen.dart';
import '../shopping/screens/shopping_screen.dart';
import '../todos/screens/todo_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _focusTab = 2;

  int _index = 0;
  StreamSubscription<void>? _alertOpenedSub;

  // Each tab gets its own ScaffoldMessenger so snackbars and banners attach
  // to the tab's Scaffold (below its AppBar, above its FAB) instead of the
  // outer shell Scaffold. Keys let the shell show a banner on the open tab.
  final _messengers = List.generate(
    _screens.length,
    (_) => GlobalKey<ScaffoldMessengerState>(),
  );

  static const _screens = <Widget>[
    TodoScreen(),
    ShoppingScreen(),
    FocusScreen(),
    NotesScreen(),
    DecksScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Tapping the phase-end notification opens the Focus tab, whether the
    // tap started the app or brought a running one to the front.
    final notifier = sl<PhaseNotifier>();
    if (notifier.launchedFromAlert) _index = _focusTab;
    _alertOpenedSub = notifier.alertOpened.listen((_) => _select(_focusTab));
  }

  @override
  void dispose() {
    _alertOpenedSub?.cancel();
    super.dispose();
  }

  void _select(int index) {
    _clearBanners();
    setState(() => _index = index);
  }

  void _clearBanners() {
    for (final key in _messengers) {
      key.currentState?.clearMaterialBanners();
    }
  }

  /// Phase-finished alert, shown at the top of whichever tab is open.
  void _showPhaseBanner(PomodoroState state) {
    final done = state.lastCompleted;
    if (done == null) return;
    final messenger = _messengers[_index].currentState;
    if (messenger == null) return;

    final message = done == PomodoroPhase.focus
        ? 'Focus session done. Time for a ${state.phase.label.toLowerCase()}.'
        : 'Break over. Ready to focus?';

    _clearBanners();
    messenger.showMaterialBanner(
      MaterialBanner(
        content: Text(message),
        leading: Icon(Icons.timer, color: done.color),
        actions: [
          if (_index != _focusTab)
            TextButton(
              onPressed: () => _select(_focusTab),
              child: const Text('Open'),
            ),
          TextButton(
            onPressed: _clearBanners,
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PomodoroCubit, PomodoroState>(
      listenWhen: (a, b) => a.completedSignal != b.completedSignal,
      listener: (context, state) => _showPhaseBanner(state),
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            for (var i = 0; i < _screens.length; i++)
              ScaffoldMessenger(key: _messengers[i], child: _screens[i]),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.check_circle_outline),
              selectedIcon: Icon(Icons.check_circle),
              label: 'Todos',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined),
              selectedIcon: Icon(Icons.shopping_cart),
              label: 'Shopping',
            ),
            NavigationDestination(
              icon: Icon(Icons.timer_outlined),
              selectedIcon: Icon(Icons.timer),
              label: 'Focus',
            ),
            NavigationDestination(
              icon: Icon(Icons.sticky_note_2_outlined),
              selectedIcon: Icon(Icons.sticky_note_2),
              label: 'Notes',
            ),
            NavigationDestination(
              icon: Icon(Icons.style_outlined),
              selectedIcon: Icon(Icons.style),
              label: 'Cards',
            ),
          ],
        ),
      ),
    );
  }
}