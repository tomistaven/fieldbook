# Fieldbook

Personal productivity app built with Flutter: todos, a shopping list, a Pomodoro timer, notes and flashcards in one place. Repurposed from the original Fieldbook job tracker (kood/Jõhvi mobile Task 1).

## Features

| Tab | What it does |
| --- | --- |
| **Todos** | Title, optional note and due date. Active / Done / All filters with counts. Overdue items highlighted. Swipe to delete with undo, "Clear completed". |
| **Shopping** | Quick-add bar that keeps the keyboard open between items. Tap to check off (checked items move to an "In cart" section), long-press to edit name and quantity, swipe to delete with undo. |
| **Focus** | Pomodoro timer with focus / short break / long break, configurable durations, sessions per cycle and auto-start. Survives backgrounding and app restarts. Counts today's completed focus sessions. |
| **Notes** | Autosaving editor, search, pin to top, copy to clipboard. Title and body are AES-256 encrypted at rest. |
| **Cards** | Flashcard decks with a flip-card study mode. Leitner boxes (1–5): weakest cards come first, missed cards come back at the end of the session. Progress per deck. |

Light / dark / system theme toggle in every tab.

## Architecture

Feature-first layout. Each feature owns its repository, cubit(s), screens and widgets.

```
lib/
├── main.dart                  # Locale, encryption and prefs init
├── app.dart                   # Providers, MaterialApp, bottom-nav shell
├── core/
│   ├── database/              # Drift schema (all tables) + generated code
│   ├── security/              # AES encryption, key in secure storage
│   ├── theme/                 # Colors, theme, ThemeCubit
│   ├── utils/                 # Date labels
│   └── widgets/               # Shared widgets and dialogs
└── features/
    ├── todos/
    ├── shopping/
    ├── pomodoro/
    ├── notes/
    └── flashcards/
```

- **State:** flutter_bloc cubits. Repositories expose Drift `watch()` streams; cubits subscribe, so every write updates the UI without manual refreshes.
- **Dependency wiring:** `RepositoryProvider` / `BlocProvider` above `MaterialApp` (no service locator).
- **Persistence:** Drift over SQLite (`fieldbook.db`). Pomodoro settings and timer state in shared_preferences.
- **Encryption:** note title and body only; search runs on decrypted notes in memory.
- **Pomodoro timing:** countdown is derived from an absolute end time, not from counting ticks, so it stays correct after the app is backgrounded or killed. Phase logic is a pure function (`nextPhase`) and unit-tested.

## Setup

Requires Flutter (developed on 3.41 stable).

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates app_database.g.dart
flutter test
flutter run
```

Re-run `build_runner` after changing any table in `lib/core/database/app_database.dart`. Bump `schemaVersion` and add a migration step once real data exists.

Release APK:

```bash
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```

## Notes

- Application ID is `com.staven.fieldbook`, which differs from the old job-tracker build (`com.example.jobs`), so the two install side by side.
- Targets Android and iOS. Web would need a different Drift backend (the current one uses `dart:io`).
- The launcher icon is still the job-tracker one (`assets/icon/app_icon.png`); replace it and run `dart run flutter_launcher_icons`.

## Known limitations

- No system notification when a Pomodoro phase ends while the app is in the background; the phase is completed correctly when the app is reopened.
- Single shopping list.
- No backup / export or sync.

## License

All rights reserved. See [LICENSE](LICENSE).
