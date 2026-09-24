import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'injection_container.dart';
import 'presentation/flashcards/cubit/decks_cubit.dart';
import 'presentation/focus/cubit/pomodoro_cubit.dart';
import 'presentation/notes/cubit/notes_cubit.dart';
import 'presentation/settings/cubit/settings_cubit.dart';
import 'presentation/settings/cubit/settings_state.dart';
import 'presentation/shell/app_shell.dart';
import 'presentation/shopping/cubit/shopping_cubit.dart';
import 'presentation/todos/cubit/todo_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initLocale();
  await initDependencies();
  // Resolved eagerly so a timer that was running when the app was closed is
  // restored (or completed) on launch rather than when the tab is opened.
  sl<PomodoroCubit>();
  runApp(const FieldbookApp());
}

/// Intl defaults to en_US unless set explicitly. DateFormat also needs its
/// locale data loaded, and falls back to en_US for unsupported locales.
Future<void> _initLocale() async {
  await initializeDateFormatting();
  final locale = PlatformDispatcher.instance.locale;
  final candidate = locale.countryCode == null
      ? locale.languageCode
      : '${locale.languageCode}_${locale.countryCode}';
  Intl.defaultLocale = Intl.verifiedLocale(
    candidate,
    DateFormat.localeExists,
    onFailure: (_) => 'en_US',
  );
}

/// Root widget. App-scoped cubits are provided above [MaterialApp] so pushed
/// routes (note editor, deck, study, settings) can read them too.
class FieldbookApp extends StatelessWidget {
  const FieldbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<SettingsCubit>()),
        BlocProvider.value(value: sl<TodoCubit>()),
        BlocProvider.value(value: sl<ShoppingCubit>()),
        BlocProvider.value(value: sl<PomodoroCubit>()),
        BlocProvider.value(value: sl<NotesCubit>()),
        BlocProvider.value(value: sl<DecksCubit>()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          return MaterialApp(
            title: AppConstants.appName,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            debugShowCheckedModeBanner: false,
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
