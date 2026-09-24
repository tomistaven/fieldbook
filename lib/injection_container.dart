import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/datasources/app_database.dart';
import 'data/datasources/encryption_service.dart';
import 'data/repositories/flashcard_repository_impl.dart';
import 'data/repositories/note_repository_impl.dart';
import 'data/repositories/shopping_repository_impl.dart';
import 'data/repositories/todo_repository_impl.dart';
import 'domain/repositories/flashcard_repository.dart';
import 'domain/repositories/note_repository.dart';
import 'domain/repositories/shopping_repository.dart';
import 'domain/repositories/todo_repository.dart';
import 'presentation/flashcards/cubit/decks_cubit.dart';
import 'presentation/focus/cubit/pomodoro_cubit.dart';
import 'presentation/notes/cubit/notes_cubit.dart';
import 'presentation/settings/cubit/settings_cubit.dart';
import 'presentation/shopping/cubit/shopping_cubit.dart';
import 'presentation/todos/cubit/todo_cubit.dart';

final sl = GetIt.instance;

/// Registers all app-scoped dependencies with the get_it service locator.
///
/// Call once in [main] before [runApp]. [SharedPreferences] and
/// [EncryptionService] need async setup, so they are initialised here and
/// registered as ready instances; everything else is a lazy singleton.
///
/// Screen-scoped cubits (DeckCardsCubit, StudyCubit) are NOT registered here;
/// they are created by their screens and closed with them.
Future<void> initDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  final encryption = EncryptionService();
  await encryption.init();
  sl.registerSingleton<EncryptionService>(encryption);

  sl.registerLazySingleton<AppDatabase>(AppDatabase.new);

  // Repositories
  sl.registerLazySingleton<TodoRepository>(
    () => TodoRepositoryImpl(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<ShoppingRepository>(
    () => ShoppingRepositoryImpl(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<NoteRepository>(
    () => NoteRepositoryImpl(sl<AppDatabase>(), sl<EncryptionService>()),
  );
  sl.registerLazySingleton<FlashcardRepository>(
    () => FlashcardRepositoryImpl(sl<AppDatabase>()),
  );

  // App-scoped cubits: one instance each, alive for the whole session so
  // the bottom-nav tabs keep their state.
  sl.registerLazySingleton<SettingsCubit>(
    () => SettingsCubit(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<TodoCubit>(() => TodoCubit(sl<TodoRepository>()));
  sl.registerLazySingleton<ShoppingCubit>(
    () => ShoppingCubit(sl<ShoppingRepository>()),
  );
  sl.registerLazySingleton<PomodoroCubit>(
    () => PomodoroCubit(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<NotesCubit>(() => NotesCubit(sl<NoteRepository>()));
  sl.registerLazySingleton<DecksCubit>(
    () => DecksCubit(sl<FlashcardRepository>()),
  );
}
