# Fieldbook

A pocket organiser for everyday life: todos, a shopping list, a Pomodoro timer, notes, and flashcards in one offline app.

---

## Screenshots

| Todos | Shopping | Focus | Notes |
| --- | --- | --- | --- |
| ![Todo list with filter chips and an overdue item](screenshots/01_todos.png) | ![Shopping list with items to buy and an In cart section](screenshots/02_shopping.png) | ![Pomodoro timer ring with cycle dots](screenshots/03_focus.png) | ![Notes list with search and a pinned note](screenshots/04_notes.png) |

| Note Editor | Decks | Study | Settings |
| --- | --- | --- | --- |
| ![Note editor with title and body](screenshots/05_note_editor.png) | ![Flashcard decks with learned progress](screenshots/06_decks.png) | ![Study session showing a revealed card](screenshots/07_study.png) | ![Settings screen with theme options](screenshots/08_settings.png) |

---

## Table of Contents

- [Project Overview](#project-overview)
- [Feature Summary](#feature-summary)
- [Future Development](#future-development)
- [Dependencies](#dependencies)
- [Setup and Installation](#setup-and-installation)
- [Usage Guide](#usage-guide)
- [Design Decisions and Challenges](#design-decisions-and-challenges)
- [License](#license)

---

## Project Overview

Fieldbook is a Flutter app for Android and iOS that gathers five everyday tools behind a bottom navigation bar: **Todos**, **Shopping**, **Focus** (a Pomodoro timer), **Notes**, and **Cards** (flashcards). Everything is stored locally in an SQLite database. Notes are encrypted at rest. The app needs no account and no network connection.

Fieldbook started as a job-tracker coursework project (kood/Jõhvi mobile Task 1) and was rebuilt from scratch after graduation as a personal productivity app.

For the architecture, database, timer, encryption, and study-session internals in depth, see [TECHNICAL_OVERVIEW.md](TECHNICAL_OVERVIEW.md).

---

## Feature Summary

### Todos

| Feature | Description |
| --- | --- |
| Create and edit | Title, optional note, optional due date |
| Filters | Active / Done / All chips, each showing its count |
| Overdue highlight | Open todos with a past due date show the date in red |
| Smart ordering | Open todos by due date (undated last), then newest; done todos by most recently completed |
| Swipe to delete | With an Undo snackbar that restores the todo exactly |
| Clear completed | Deletes every done todo after confirmation |

### Shopping

| Feature | Description |
| --- | --- |
| Quick add | Always-visible input; the keyboard stays open between items |
| Check off | Tap an item to move it to an **In cart** section |
| Quantity | Free text ("2", "500 g", "1 pack"), set by long-pressing an item |
| Swipe to delete | With Undo |
| Clear checked / Delete all | Clear checked removes the In cart section; Delete all asks first |

### Focus (Pomodoro)

| Feature | Description |
| --- | --- |
| Timer | Focus, short break, and long break phases with a progress ring |
| Cycle tracking | Dots show focus sessions completed toward the next long break |
| Controls | Start / pause, reset the current phase, skip to the next phase |
| Settings | Focus 1–120 min, short break 1–60, long break 1–90, sessions per cycle 1–12, optional auto-start |
| Survives restarts | A running timer keeps counting while the app is backgrounded or closed |
| Phase alert | A banner at the top of whichever tab is open, with **Open** and **Dismiss** |
| Daily count | Focus sessions completed today |

### Notes

| Feature | Description |
| --- | --- |
| Autosave | Saves as you type; no save button |
| Search | Matches title and body |
| Pin to top | Long-press a note to pin or unpin it |
| Copy | Copies title and body to the clipboard from the editor |
| Encryption | Title and body are AES-encrypted in the database |

### Flashcards

| Feature | Description |
| --- | --- |
| Decks | Create, rename, delete; card count and learned progress per deck |
| Cards | Front and back text; the add sheet stays open for entering several cards in a row |
| Study mode | Flip-card animation, **Again** / **Got it** answers |
| Leitner boxes | Each card sits in box 1–5; weakest cards are studied first |
| Missed cards return | Cards answered **Again** come back at the end of the session |
| Session summary | How many cards were right on the first try |
| Reset progress | Sends every card in a deck back to box 1 |

### App Experience

| Feature | Description |
| --- | --- |
| Themes | System, light, or dark, chosen in Settings |
| Typography | Inter, bundled with the app |
| Offline | No network access needed after installation |

---

## Future Development

| Feature | Notes |
| --- | --- |
| Pomodoro system notification | Alert when a phase ends while the app is in the background; needs `flutter_local_notifications` and native setup |
| Multiple shopping lists | New `lists` table plus a list picker |
| Backup and export | Export the database or a JSON dump; notes would need decrypting or the key exporting |
| Sync | A small backend (Go) or a hosted service |
| Spaced repetition by date | Schedule reviews by Leitner box instead of studying the whole deck each session |
| Authenticated encryption | Move notes to AES-GCM; the `encrypt` package is archived, see the Technical Overview |
| New launcher icon | The current icon is still the job-tracker one |

---

## Dependencies

| Package | Purpose |
| --- | --- |
| `flutter_bloc` | Cubit state management across all screens |
| `equatable` | Value equality for entities and Cubit states, which prevents unnecessary rebuilds |
| `get_it` | Dependency injection via service locator |
| `drift` | Type-safe SQLite access with reactive `watch()` streams |
| `path` / `path_provider` | Resolve the documents directory for the database file |
| `encrypt` | AES encryption of note titles and bodies |
| `flutter_secure_storage` | Stores the encryption key in the Android Keystore / iOS Keychain |
| `shared_preferences` | Persists the theme mode, Pomodoro settings, and running-timer state |
| `intl` | Locale-aware date labels |
| `drift_dev` / `build_runner` *(dev)* | Generate the Drift database code (`app_database.g.dart`) |
| `flutter_launcher_icons` *(dev)* | Generates launcher icons from a single source asset |

SQLite itself is bundled by the `sqlite3` package (a transitive dependency of `drift`) through Dart build hooks, so no separate `sqlite3_flutter_libs` dependency is needed.

---

## Setup and Installation

### Prerequisites

- Flutter (stable channel) with Dart 3.11.4 or later, per the project's SDK constraint
- Android SDK with a connected device or emulator
- Network access for the first build, when the `sqlite3` build hook downloads the pre-compiled SQLite binaries

### Steps

```bash
git clone https://github.com/tomistaven/fieldbook.git
cd fieldbook
flutter pub get
dart run build_runner build
flutter run
```

`build_runner` generates `lib/data/datasources/app_database.g.dart`. The generated file is committed, so the step is only required after changing a table.

### Building a release APK

```bash
flutter build apk --release
```

The output APK is at `build/app/outputs/flutter-apk/app-release.apk`.

---

## Usage Guide

### Navigation

The bottom bar switches between **Todos**, **Shopping**, **Focus**, **Notes**, and **Cards**. Each tab keeps its state when you switch away. The gear icon in every tab's top bar opens Settings.

### Todos

Tap **+** to add a todo: a title is required, while the note and due date are optional. Tap a todo to edit it, tap its circle to mark it done, and swipe it left to delete it. After a delete, **Undo** in the snackbar brings it back. The chips at the top filter between Active, Done, and All. **Clear completed** in the ⋮ menu deletes all done todos after asking.

### Shopping

Type in the **Add item** field at the bottom and press enter. The keyboard stays open so you can add the next item straight away. Tap an item to check it off and move it into **In cart**, or tap it again to move it back. Long-press an item to change its name or add a quantity. Swipe left to delete, with Undo. The ⋮ menu has **Clear checked** and **Delete all**.

### Focus

Tap the large button to start or pause. **Reset** returns the current phase to its full length, and **Skip** moves to the next phase without counting the current one. The dots above the ring show how many focus sessions remain before a long break.

The tune icon opens timer settings: phase lengths, sessions per cycle, and whether the next phase starts automatically. When a phase ends, a banner appears at the top of whichever tab you're on. **Open** jumps to Focus.

The timer keeps running if you leave the app. When you come back, it shows the correct remaining time, or the next phase if the current one finished while you were away.

### Notes

Tap the pen button to write a note. It saves automatically while you type and when you leave the editor. A new note that you leave empty is not saved, and a note you empty out is deleted when you leave. Search matches titles and bodies. Long-press a note in the list to pin it to the top or delete it. In the editor, the copy icon puts the note on the clipboard.

### Flashcards

Tap **+** to create a deck; it opens straight away. Tap **+** inside the deck to add cards. The sheet stays open after each card, so you can enter a whole set in one go. Tap a card to edit it, or swipe it left to delete it, with Undo. The bars on each card show its Leitner box.

Tap **Study** to start a session. Tap the card or **Show answer** to flip it, then answer **Again** or **Got it**. Missed cards come back at the end of the session. The deck's ⋮ menu has **Rename deck**, **Reset progress**, and **Delete deck**.

### Settings

Open Settings from the gear icon to choose between system, light, and dark theme.

---

## Design Decisions and Challenges

### Rebuilt rather than repurposed

Fieldbook began as a job-tracker coursework app. Rather than bending that code into a different product, it was started as a new Flutter project and a new repository, with the app source written fresh. The native Android and iOS folders came clean from `flutter create` with the right package ID, and the history starts at the new app instead of carrying the coursework review phases.

### Bottom navigation, not a floating hub

Doodlingz uses a radial tool hub to keep its drawing canvas unobstructed. Fieldbook has no canvas to protect and depends on fast switching between distinct tools, so a standard five-item bottom navigation bar is the better fit. Settings sits behind a gear icon in the top bar, because a sixth destination would exceed Material's five-item guideline.

### Reactive database streams instead of manual refreshes

Every repository exposes Drift `watch()` streams, and each Cubit subscribes to one. Any write, from any screen, updates every list that shows that data without refresh events. Deleting a deck, for example, updates both the deck list and the card counts without either screen being told.

### Optimistic removal for swipe-to-delete

Flutter's `Dismissible` asserts if a swiped widget is still in the tree on the next frame. Drift's stream update arrives asynchronously, so a swipe that only deleted from the database would trip that assertion. The Cubits therefore remove the item from their state immediately and let the stream confirm it afterwards. Undo re-inserts the original row with its original id.

### A timer that survives the app being closed

A countdown that decrements a counter every tick drifts, and it stops entirely when Android suspends or kills the app. The Pomodoro timer instead stores an absolute end time and derives the remaining time from the clock. Timer state is persisted to shared preferences, so after a restart the timer resumes, or completes the phase that ended while the app was closed.

### A phase alert that reaches whichever tab is open

The first version showed a snackbar at the bottom of the screen, which was easy to miss. The alert is now a `MaterialBanner` at the top of the open tab. Each tab has its own `ScaffoldMessenger` with a stored key, so the shell can target the tab the user is actually looking at. Tab-local snackbars such as Undo still lift that tab's FAB rather than overlapping it.

### Dialogs own their text controllers

The first text-prompt dialog disposed its `TextEditingController` as soon as `showDialog` returned. At that moment the dialog is still playing its closing animation and rebuilds its `TextField`, so creating or renaming a deck crashed with a use-after-dispose error. Every dialog with a text field is now a `StatefulWidget` that creates its controllers and disposes them in its own `dispose()`, after the route is fully gone.

### Row classes separate from entities

Drift generates a data class per table. Those classes are named with a `Row` suffix (`TodoRow`, `NoteRow`, …), and the data layer maps them to plain domain entities. Nothing outside `data/` depends on Drift. Notes especially need that separation, because a row holds ciphertext while a `Note` entity holds the decrypted text.

### Encrypting notes only

Notes are the only free-form personal writing in the app, so their title and body are encrypted with a key kept in platform secure storage. Todos, shopping items, and flashcards are left in plain text. Encrypting them would add a decryption cost to every list render and make search harder, for data that is rarely sensitive.

### Bundled font instead of `google_fonts`

Doodlingz bundles its fonts through `google_fonts` with runtime fetching disabled. Fieldbook declares Inter's static weights (Regular, Medium, SemiBold, Bold) directly in `pubspec.yaml` instead. The result is the same offline guarantee with one fewer dependency. Using static files avoids variable-font weight handling, and the 18pt optical size suits body text.

---

## License

All rights reserved. See [LICENSE](LICENSE).