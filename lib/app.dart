import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/database/app_database.dart';
import 'core/security/encryption_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/flashcards/decks_cubit.dart';
import 'features/flashcards/decks_screen.dart';
import 'features/flashcards/flashcard_repository.dart';
import 'features/notes/note_repository.dart';
import 'features/notes/notes_cubit.dart';
import 'features/notes/notes_screen.dart';
import 'features/pomodoro/pomodoro_cubit.dart';
import 'features/pomodoro/pomodoro_screen.dart';
import 'features/pomodoro/pomodoro_settings.dart';
import 'features/shopping/shopping_cubit.dart';
import 'features/shopping/shopping_repository.dart';
import 'features/shopping/shopping_screen.dart';
import 'features/todos/todo_cubit.dart';
import 'features/todos/todo_repository.dart';
import 'features/todos/todo_screen.dart';

/// Repositories and app-wide cubits live above MaterialApp so pushed
/// routes (note editor, deck, study) can read them.
class FieldbookApp extends StatelessWidget {
  const FieldbookApp({
    super.key,
    required this.database,
    required this.encryption,
    required this.prefs,
  });

  final AppDatabase database;
  final EncryptionService encryption;
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => TodoRepository(database)),
        RepositoryProvider(create: (_) => ShoppingRepository(database)),
        RepositoryProvider(
            create: (_) => NoteRepository(database, encryption)),
        RepositoryProvider(create: (_) => FlashcardRepository(database)),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(
              create: (c) => TodoCubit(c.read<TodoRepository>())),
          BlocProvider(
              create: (c) => ShoppingCubit(c.read<ShoppingRepository>())),
          BlocProvider(
            // Not lazy: restores a running timer on launch.
            lazy: false,
            create: (_) => PomodoroCubit(prefs),
          ),
          BlocProvider(
              create: (c) => NotesCubit(c.read<NoteRepository>())),
          BlocProvider(
              create: (c) => DecksCubit(c.read<FlashcardRepository>())),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, mode) => MaterialApp(
            title: 'Fieldbook',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: mode,
            debugShowCheckedModeBanner: false,
            home: const HomeShell(),
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _focusTab = 2;

  int _index = 0;

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
    PomodoroScreen(),
    NotesScreen(),
    DecksScreen(),
  ];

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