# Fieldbook — Technical Overview

This document covers the architecture, the database and its reactive streams, note encryption, each feature's internals (todos, shopping, the Pomodoro timer and its phase-end notification, notes, flashcards), the app shell, dependency injection, and the key constants. The README covers features and setup; this covers the code.

---

## Table of Contents

- [Architecture](#architecture)
- [Database and Reactive Streams](#database-and-reactive-streams)
- [Note Encryption](#note-encryption)
- [Todos](#todos)
- [Shopping](#shopping)
- [The Pomodoro Timer](#the-pomodoro-timer)
- [Phase-End Notification](#phase-end-notification)
- [Notes and Autosave](#notes-and-autosave)
- [Flashcards and the Leitner System](#flashcards-and-the-leitner-system)
- [App Shell, Messengers, and the Phase Alert](#app-shell-messengers-and-the-phase-alert)
- [Dialogs and Controller Lifetime](#dialogs-and-controller-lifetime)
- [Settings](#settings)
- [Dependency Injection](#dependency-injection)
- [Key Constants](#key-constants)
- [Back to README.md](README.md)

---

## Architecture

The project uses Flutter Clean Architecture with three layers plus a shared core.

**Domain layer** (`lib/domain/`) defines the entities (`Todo`, `ShoppingItem`, `Note`, `Deck`, `Flashcard`, `PomodoroSettings`), the abstract repository interfaces, and the `PhaseNotifier` service interface. It also holds the pure logic: `nextPhase()` and `phaseEnds()` for Pomodoro phase transitions and `Leitner.next()` for flashcard boxes. There are no Flutter imports and no external packages beyond `equatable`, which keeps both pieces of logic unit-testable without a widget tree or a database.

**Data layer** (`lib/data/`) implements the repositories over Drift. `datasources/` holds the database definition, `EncryptionService`, and `NotificationService`. `models/` maps Drift row classes to domain entities, and `repositories/` holds the `*RepositoryImpl` classes. The data layer knows about Drift, SQLite, secure storage, and the notification plugin, but not about widgets.

**Presentation layer** (`lib/presentation/`) is split per feature: `todos/`, `shopping/`, `focus/`, `notes/`, `flashcards/`, `settings/`, plus `shell/` for the bottom navigation. Each feature has `cubit/` (a Cubit with its state in a separate `*_state.dart`), `screens/`, and `widgets/`. Dialog, sheet, and snackbar flows are extracted into `*_actions.dart` mixins (`mixin TodoActions on State<TodoScreen>`), so the screen's `build()` holds layout only. Screens talk to Cubits, never directly to a repository. The two exceptions are the note editor and the screen-scoped flashcard Cubits, both covered below.

**Core** (`lib/core/`) holds the theme, `AppConstants`, `DateLabels`, and widgets shared across features (`EmptyState`, `DeleteSwipeBackground`, the dialog helpers).

A note on layer placement: Pomodoro phase colours live in a presentation-side extension (`focus/widgets/phase_color.dart`) rather than on the domain `PomodoroPhase` enum. Putting a `Color` on the enum would give the domain layer a Flutter dependency.

### Typography and theme

`AppTheme` sets `fontFamily: 'Inter'` on `ThemeData`, which Flutter applies to every slot in the text theme. The one place that needs the family set explicitly is `AppBarTheme.titleTextStyle`. `AppBar` does not merge that style with the text theme, so without an explicit family the titles would fall back to the platform font. The same applies to `NavigationBarThemeData.labelTextStyle`.

Light and dark themes are built by one `_build()` method that takes the palette as parameters, so the two themes cannot drift apart structurally. Neutrals follow Tailwind's gray scale. The dark background is `#121212` rather than pure black, and surfaces step up to `#1E1E1E` so cards separate from the background.

The `ColorScheme` sets `inverseSurface`, `onInverseSurface`, and `inversePrimary` explicitly. Snackbars draw on the inverse surface and colour their action with `inversePrimary`, which otherwise falls back to `onPrimary` (white). In dark mode the inverse surface is light gray-100, so the Undo action was nearly invisible. Light mode uses `accent` (7.0:1 on gray-900) and dark mode uses `accentOnLight`, emerald-700 (5.0:1 on gray-100); both meet WCAG AA for normal text.

---

## Database and Reactive Streams

### Schema

`AppDatabase` (`data/datasources/app_database.dart`) defines five tables:

| Table | Columns of note |
| --- | --- |
| `todos` | `title` (1–200 chars), `note`, `due_date`, `done`, `created_at`, `completed_at` |
| `shopping_items` | `name` (1–120 chars), `quantity` (free text), `checked`, `created_at` |
| `notes` | `title`, `body` (both ciphertext), `pinned`, `created_at`, `updated_at` |
| `decks` | `name` (1–80 chars), `created_at` |
| `flashcards` | `deck_id` (FK → `decks.id`, `ON DELETE CASCADE`), `front`, `back`, `box`, `last_reviewed_at`, `created_at` |

Every table's row class is renamed with `@DataClassName` (`TodoRow`, `ShoppingItemRow`, `NoteRow`, `DeckRow`, `FlashcardRow`), so the domain entities can use the plain names without clashing with Drift's generated classes.

SQLite ships with foreign-key enforcement off. `MigrationStrategy.beforeOpen` runs `PRAGMA foreign_keys = ON` on every connection. Without it, deleting a deck would leave its cards behind in the table.

The file lives at `<documents>/fieldbook.db` (`AppConstants.databaseFile`) and is opened with `NativeDatabase.createInBackground`, so queries run off the UI isolate.

### Streams instead of refresh events

Every repository read that a screen displays is a Drift `watch()` stream. Each app-scoped Cubit subscribes once in its constructor and re-emits on every change:

```dart
_subscription = _repository.watchAll().listen(
  (todos) => emit(state.copyWith(todos: todos, loading: false)),
);
```

Writes never emit state themselves; they write to the database, and the stream delivers the result. This removes the refresh-event plumbing a load-on-demand design needs. It also means a write from one screen updates every other screen showing the same table: study answers update the deck list's learned counts, and deleting a deck updates any open list.

### Optimistic removal for `Dismissible`

The one place the Cubits do emit before the database confirms is deletion by swipe. `Dismissible` asserts if the dismissed widget is still in the tree on the next frame, and the Drift stream update arrives asynchronously, a frame or more later. `TodoCubit.delete`, `ShoppingCubit.delete`, and `DeckCardsCubit.delete` therefore remove the item from state first, then delete from the database. The stream emission that follows agrees with the optimistic state, so there is no flicker.

Undo re-inserts the deleted entity through `restore()`. The model maps it back to a row with its original id, `created_at`, and state, so the item reappears in its original position rather than as a new entry.

### The deck summary query

The deck list needs each deck's card count and learned count. Rather than watching both tables and joining in Dart, `FlashcardRepositoryImpl.watchDecks()` uses one custom select:

```sql
SELECT d.id, d.name, COUNT(f.id) AS card_count,
       COALESCE(SUM(CASE WHEN f.box >= 3 THEN 1 ELSE 0 END), 0) AS learned_count
FROM decks d LEFT JOIN flashcards f ON f.deck_id = d.id
GROUP BY d.id ORDER BY d.created_at DESC
```

`readsFrom: {decks, flashcards}` tells Drift to re-run the query when either table changes, so the counts update live during a study session. The `LEFT JOIN` keeps empty decks in the result, and `COALESCE` turns the `NULL` sum of an empty deck into 0.

### Migrations

`schemaVersion` is 1. Any table change needs a version bump and an `onUpgrade` step, followed by `dart run build_runner build` to regenerate `app_database.g.dart`.

---

## Note Encryption

`EncryptionService` (`data/datasources/encryption_service.dart`) encrypts note titles and bodies with AES-256 using the `encrypt` package. The package's default mode is SIC (counter mode), and the service does not override it.

- **Key:** 32 random bytes generated on first launch and stored in `flutter_secure_storage`, which uses the Android Keystore.
- **IV:** a fresh random 16-byte IV for every value, stored alongside the ciphertext as `<base64 IV>:<base64 ciphertext>`. The same note text therefore never produces the same ciphertext twice.
- **Empty values** are stored as an empty string rather than encrypted, so an untitled note has no ciphertext to decrypt.
- **Corrupted Keystore entries:** a Keystore entry can survive an uninstall and become unreadable on reinstall. `init()` catches the read failure, deletes the entry, and generates a new key. Notes encrypted under the old key can no longer be decrypted. `decryptText()` catches the failure and returns an empty string, so they show as empty rather than crashing the app.

`NoteRepositoryImpl` encrypts on every write and decrypts in `_toEntity()` on every read, so nothing above the data layer ever handles ciphertext. Search runs in memory on decrypted `Note` entities (`Note.matches()`), because ciphertext cannot be searched with SQL `LIKE`.

### Known limitation

Counter mode provides confidentiality but not integrity: there is no MAC, so modified ciphertext is not detected. The `encrypt` package is also archived. Moving to AES-GCM, which is authenticated, would mean re-encrypting existing notes under the new scheme, and is listed under Future Development in the README.

---

## Todos

`TodoState.visible` filters by the active `TodoFilter` and then sorts with a comparator, rather than asking SQL for an order:

1. Open todos before done todos.
2. Open todos by due date ascending, with undated todos after dated ones.
3. Ties, and undated todos, newest first by `created_at`.
4. Done todos by most recently completed (`completed_at`, falling back to `created_at`).

The sort happens in Dart because the order depends on the filter, and because "nulls last" in SQL `ORDER BY` needs the `NULLS LAST` clause. Keeping it in Dart avoids depending on how Drift exposes that clause.

`setDone()` writes `completed_at` alongside `done`, and clears it when a todo is reopened. The overdue check (`DateLabels.isOverdue`) compares calendar days, not timestamps, so a todo due today is never shown as overdue.

---

## Shopping

Items are watched oldest-first, and `ShoppingState` splits them into `toBuy` and `inCart`. Checking an item moves it between sections without changing its position within either.

`QuickAddBar` uses `onEditingComplete` rather than `onSubmitted`. When `onEditingComplete` is supplied, `TextField` skips its default behaviour of unfocusing on the done action, so the keyboard stays open for the next item. Handling it in `onSubmitted` would close and reopen the keyboard between items.

`Clear checked` deletes without confirmation because the items are easy to re-add. `Delete all` confirms because it empties the whole list.

---

## The Pomodoro Timer

### Deriving time from an end timestamp

`PomodoroCubit` (`presentation/focus/cubit/pomodoro_cubit.dart`) never counts ticks down. Starting the timer records an absolute end time:

```dart
_endsAt = DateTime.now().add(state.remaining);
```

A `Timer.periodic` every 250 ms (`AppConstants.timerTick`) recomputes `remaining = _endsAt - now`. It emits only when the displayed whole second changes, and `PomodoroState` includes `remaining.inSeconds` in its Equatable props so that sub-second changes don't trigger rebuilds. When `remaining` reaches zero, `_advance()` settles the phase (see Chaining with auto-start).

Counting ticks would drift, because timer callbacks are not guaranteed to fire on schedule. It would also freeze while the OS suspends the app. Deriving from the clock makes both problems disappear: after a resume, the first tick shows the correct value.

The 250 ms interval is deliberate. A 1 s timer can fire just after a second boundary and leave the display nearly a full second stale. `TimerRing.format()` rounds up (`ceil`), so the display reads `25:00` at the start and `00:01` during the final second, never `00:00` while time remains.

### Persisting across process death

Timer state is written to shared preferences on every start, pause, reset, skip, and completion:

| Key | Holds |
| --- | --- |
| `pomo.phase` / `pomo.status` | Current phase and idle / running / paused |
| `pomo.endsAtMs` | End time while running (removed when not running) |
| `pomo.remainingMs` | Remaining time, used when paused |
| `pomo.focusInCycle` | Completed focus sessions since the last long break |
| `pomo.todayDate` / `pomo.todayCount` | Today's completed focus sessions, keyed by date |
| `pomo.focusMinutes` … `pomo.autoStartNext` | User settings |
| `pomo.notificationPermissionAsked` | Whether the notification permission prompt has been shown |

The constructor restores this state synchronously; `SharedPreferences` is already loaded by `initDependencies()`. If the restored status is running and the end time has passed, the phase ended while the app was closed. `_advance(unattended: true, silent: true)` then catches up without haptics and without the alert banner. With auto-start on, it chains from the stored end time rather than from launch, so the timer lands in whichever phase is running now, capped at the end of the next long break.

`main()` resolves the Cubit (`sl<PomodoroCubit>()`) before `runApp()`. The restore therefore happens at launch rather than when the Focus tab is first built.

### Phase logic as a pure function

`nextPhase()` (`domain/entities/pomodoro.dart`) takes the current phase, the cycle count, the settings, and whether the phase was completed or skipped. It returns the next phase and the new cycle count:

- **Completed focus** increments the cycle count. If the count reaches `sessionsBeforeLongBreak`, a long break is next; otherwise a short break.
- **Skipped focus** leads to a short or long break without incrementing the count.
- **Short break** leads to focus, and the count is kept.
- **Long break** leads to focus, and the count resets to 0.

The comparison is `>=` rather than `==`, so lowering `sessionsBeforeLongBreak` below the current count mid-cycle triggers a long break instead of never matching. This function and `phaseEnds()` are what `test/logic_test.dart` covers.

### Chaining with auto-start

`phaseEnds()` (`domain/entities/pomodoro.dart`) is a `sync*` generator that yields a `PhaseEnd` for each phase finishing from a given end time: when it ends, what finished, what comes next, the cycle count after it, and whether the next phase starts automatically. Each next phase is timed from the previous end, not from when the app processes it, so a chain keeps its schedule however late the app catches up.

`stopAfterLongBreak` bounds a chain nobody is watching: it ends after the next long break. Without it the generator is unbounded under auto-start, and callers stop at the first end still in the future.

`_advance()` walks `phaseEnds()`, completes every end that has passed, and leaves the timer running on the next end if one is still ahead, or idle at the next phase otherwise.

| Caller | `unattended` | Notes |
| --- | --- | --- |
| `_tick()` | `_hidden` | Live completion; haptics only within `_liveWindow` (1 s) of the end |
| `_onShow()` | true | Settles phases that ended while hidden before clearing `_hidden`, so they get the same cap as the notifications that announced them; one banner, no haptic |
| Constructor | true, `silent` | Process was dead; no banner, since the shell is not listening yet |

A focus session counts toward `completedToday` only if it ended today, so a catch-up across midnight does not credit yesterday's sessions to today.

### Daily count

`completedToday` is stored with the date it belongs to (`pomo.todayDate`). On launch, a stored date that isn't today resets the count to 0. On completion, the Cubit also checks whether the date changed since the last write, so a session that finishes after midnight starts the new day's count. `_rollOverDay()` runs the same check at local midnight, from a one-shot `Timer` that `_scheduleMidnight()` re-arms after each run, so a count left on screen clears on time. A backgrounded process can be frozen past midnight and miss that timer, so `_onShow()` also runs the check and re-arms the timer.

### Manual resets

The timer settings sheet has two reset rows below **Save**. Both go through `showConfirmDialog()` and call the Cubit immediately rather than being returned with the edited settings, because they change timer data, not settings.

| Action | Cubit method | Effect |
| --- | --- | --- |
| Reset today's count | `resetToday()` | `completedToday` to 0, written with today's date; the cycle is untouched |
| Reset cycle | `resetCycle()` | Cancels the ticker, clears `_endsAt`, and returns to an idle, full-length focus phase with `focusInCycle` 0; the daily count is untouched |

The cycle row is disabled when `PomodoroState.atCycleStart` is true (idle, focus phase, no completed sessions), since a reset would change nothing. The sheet takes the whole `PomodoroState` so it can show both counts and that flag.

---

## Phase-End Notification

The in-app banner covers a phase that ends while the app is visible. `NotificationService` (`data/datasources/notification_service.dart`) covers the rest, through the `PhaseNotifier` interface (`domain/services/phase_notifier.dart`), so `PomodoroCubit` has no dependency on the plugin.

### Scheduling on the app lifecycle

`PomodoroCubit` owns an `AppLifecycleListener`:

| Event | Action |
| --- | --- |
| `onHide` | If the timer is running, schedule one notification per entry of `phaseEnds(stopAfterLongBreak: true)` |
| `onShow` | Settle passed phases, then cancel all; this also removes delivered notifications from the tray |
| Constructor | Cancel any leftover from a previous session; the app is visible at launch |

Scheduling only while hidden means the notifications and the banner never fire for the same phase, and nothing has to race a foreground completion to cancel a notification. Because the timer already derives from absolute end times, each notification is an alarm registered with Android. No background isolate or foreground service runs, and the alarms fire even after the process has been killed. The notifications and `_advance()` use the same `phaseEnds()` chain with the same cap, so what the user was notified about is what the timer shows on return.

Each notification's title names the finished phase. The body reads "… has started" when the next phase auto-starts and "Up next: …" when it does not. Ids are the entry's position plus one. The app posts no other notifications, so `schedulePhaseEnds()` clears everything with `cancelAll()` before scheduling, and `cancelPhaseEnds()` is `cancelAll()` too.

### UTC instead of the device time zone

`zonedSchedule()` takes a `TZDateTime`. The device time zone only matters for recurring, wall-clock schedules such as "every day at 9:00". A one-shot alarm at an absolute instant fires at the same moment in any zone, so the end time is converted with `TZDateTime.from(endsAt, tz.UTC)`. That avoids adding `flutter_timezone` and loading the time zone database. A date that is not in the future is skipped, because `zonedSchedule()` throws for it.

### Exact alarms and the manifest

The schedule mode is `AndroidScheduleMode.exactAllowWhileIdle`, so Doze cannot defer the alert by minutes. `AndroidManifest.xml` declares:

| Entry | Purpose |
| --- | --- |
| `USE_EXACT_ALARM` | Exact alarms on API 33+, granted at install |
| `SCHEDULE_EXACT_ALARM` (`maxSdkVersion="32"`) | Exact alarms on API 31–32, where it is also granted at install |
| `RECEIVE_BOOT_COMPLETED` | Lets the plugin restore a pending alarm after a reboot |
| `ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver` | The plugin's receivers that post the notification and reschedule after boot |

`USE_EXACT_ALARM` is restricted by Google Play policy to alarm and calendar apps. Fieldbook is distributed as an APK, so the policy does not apply; a Play release would need to revisit this.

The plugin also requires core library desugaring (`isCoreLibraryDesugaringEnabled` and `desugar_jdk_libs` in `android/app/build.gradle.kts`). The status bar icon is a monochrome vector (`res/drawable/ic_notification.xml`), because Android renders only the icon's alpha channel. It is referenced from Dart by name only, so `res/raw/keep.xml` stops R8 resource shrinking from removing it in release builds.

### Permission

On Android 13+ posting notifications needs a runtime permission. The prompt is shown on the first timer start rather than at launch, so it appears when the reason for it is visible. `pomo.notificationPermissionAsked` makes sure it is requested only once; after that the choice is left to system settings. If permission is denied, scheduling still runs and Android silently drops the notification, so the timer behaves the same.

### Opening Focus from a tap

A tap reaches the app in one of two ways, and the plugin reports them differently:

| Case | Source | Handling |
| --- | --- | --- |
| The tap starts the process | `getNotificationAppLaunchDetails().didNotificationLaunchApp`, read in `NotificationService.init()` | `AppShell.initState()` starts on the Focus tab when `launchedFromAlert` is true |
| The process is still alive | `onDidReceiveNotificationResponse` | Forwarded to the `alertOpened` stream; the shell listens and calls `_select(_focusTab)` |

A plugin issue (MaikuB/flutter_local_notifications#1926) reported that `didNotificationLaunchApp` could stay true when the app is later reopened from recents. This was checked with the current plugin version: after a notification launch, swiping the app away and reopening it starts on Todos as expected.

---

## Notes and Autosave

`NoteEditorScreen` saves without a save button. Three triggers call `_save()`:

- 600 ms after the last keystroke (`AppConstants.noteAutosaveDelay`), through a debounce timer.
- Leaving the screen, through `PopScope.onPopInvokedWithResult`.
- The app being backgrounded (`AppLifecycleState.paused` or `inactive`), through `WidgetsBindingObserver`. This protects text typed just before the OS kills a backgrounded app.

Deleting from the editor sets a `_deleted` flag, cancels the debounce, and waits for any in-flight write before deleting, so a pending save cannot re-create the note afterwards.

### Serialised writes

A brand-new note has no id until its first insert completes. If a second save started before that insert returned, it would insert a second copy. `_save()` therefore chains writes onto a single future:

```dart
_chain = _chain.then((_) => _persist(title, body));
```

The first persist inserts and records the new id; every later persist sees that id and updates. `_save()` also returns early when the text matches the last saved value, so focus changes and cursor moves (which fire the controller listeners) don't cause writes.

### Empty notes

A new note is not inserted until it has content. When the editor closes on an existing note whose title and body are both empty, the note is deleted. Clearing a note's text is therefore equivalent to deleting it, and the list never fills up with blank entries.

### Why the editor reads the repository directly

`_repo` is resolved from `sl<NoteRepository>()` when the state is created, not through `context.read`. Saves can run after the route has been popped: the pop triggers `_onExit()`, whose writes complete asynchronously. A `context` lookup at that point could hit a deactivated element. Holding the repository reference avoids that. Using a Cubit here would add nothing, since the editor's state is exactly its two text controllers.

---

## Flashcards and the Leitner System

### Boxes

Each card carries a Leitner box from 1 to 5 (`Leitner` in `domain/entities/flashcard.dart`):

```dart
static int next(int box, {required bool knew}) =>
    knew ? (box + 1).clamp(minBox, maxBox) : minBox;
```

A correct answer moves the card up one box, capped at 5. A miss sends it back to box 1. A card counts as **learned** from box 3, which means it was answered correctly at least twice in a row since it was last missed. `resetProgress()` returns every card in a deck to box 1 and clears `last_reviewed_at`.

### Session ordering

`StudyCubit.start()` loads the deck's cards and groups them by box. It shuffles each group and concatenates the groups in ascending box order. The weakest cards come first, and order within a box varies between sessions.

The grouping is done with buckets rather than `shuffle()` followed by `sort()`. Dart's `List.sort` is not guaranteed to be stable, so sorting a shuffled list by box could still reorder cards within a box in a non-random way.

### Missed cards and the first-try count

Answering **Again** records the miss in the database and appends the card to the end of the session queue, with its box already set to 1. The session therefore continues until every card has been answered correctly once. The summary's "right on the first try" count uses a `Set<int>` of card ids already answered: only the first answer to each card can count.

### The flip animation

`FlipCard` rotates around the Y axis with a `TweenAnimationBuilder` and a perspective entry in the transform matrix (`setEntry(3, 2, 0.001)`). Past 90° it swaps to the back face and counter-rotates that face by 180°, so the answer text isn't mirrored.

Each card in the session is keyed by `'${card.id}-${state.position}'`. Without a new key, advancing to the next card would reuse the same `TweenAnimationBuilder`, which would animate back from 180° and briefly show the next card's answer. The position is part of the key because the same card can appear twice in one session after a miss.

### Screen-scoped Cubits

`DeckCardsCubit` and `StudyCubit` are not registered in `get_it`. `DeckScreen` creates its `DeckCardsCubit` in a `late final` field and closes it in `dispose()`. `StudyScreen` uses `BlocProvider(create:)`, which closes the Cubit when the route is popped. Both watch or load a single deck, so their lifetime should end with the screen that shows that deck.

---

## App Shell, Messengers, and the Phase Alert

`AppShell` holds the five tabs in an `IndexedStack`. All tabs stay mounted and keep their state across switches, and each tab screen has its own `Scaffold`.

### One ScaffoldMessenger per tab

Each tab is wrapped in its own `ScaffoldMessenger`. Without that, every nested `Scaffold` would register with the root messenger, which shows snackbars only on the outermost (shell) `Scaffold`. An Undo snackbar would then sit above the navigation bar and cover the tab's FAB instead of lifting it. With a messenger per tab, the tab's own `Scaffold` shows the snackbar and moves the FAB up.

### The phase alert banner

The shell listens to `PomodoroCubit` with `listenWhen: (a, b) => a.completedSignal != b.completedSignal`. `completedSignal` is a counter that increments each time a phase ends on its own. Listening on a counter rather than on the phase avoids false alerts from a skip, a reset, or a silent restore, all of which also change the phase.

The alert is a `MaterialBanner` shown on the **open** tab's messenger, which the shell reaches through a `GlobalKey<ScaffoldMessengerState>` per tab. Because every tab has its own `AppBar`, the banner appears directly below it. Banners do not time out, so the alert stays until it is dismissed or the user switches tabs; `_select()` clears banners on every tab switch. A new alert clears any previous one first, so banners never stack.

---

## Dialogs and Controller Lifetime

`showTextPrompt()` (`core/widgets/dialogs.dart`) and `showItemEditDialog()` once created their `TextEditingController`s inside the function and disposed them right after `await showDialog(...)` returned. That future completes when the route is popped, but the dialog is still on screen, playing its exit animation, and rebuilds its `TextField` during it. The rebuild re-attached listeners to a disposed controller. Creating or renaming a deck then produced `A TextEditingController was used after being disposed`, followed by cascading `_dependents.isEmpty` and duplicate-GlobalKey assertions.

Each of these dialogs is now a private `StatefulWidget` (`_TextPromptDialog`, `_ItemEditDialog`) that creates its controllers as `late final` fields and disposes them in `State.dispose()`. That method runs only after the route has been fully removed, so the controller's lifetime matches the widget that uses it. The bottom sheets (`showTodoEditor`, `showCardEditor`, the Pomodoro settings sheet) were already structured this way.

---

## Settings

`SettingsCubit` (`presentation/settings/cubit/`) holds app-wide preferences in `SharedPreferences`:

| Key | Setting |
| --- | --- |
| `theme_mode` | System, light, or dark |
| `add_buttons_on_left` | Add buttons on the left instead of the right |

### Add-button side

The `AddButtonSide` extension on `BuildContext` (`presentation/settings/widgets/add_button_side.dart`) exposes `addButtonsOnLeft`, read with `context.select`, so a screen rebuilds only when this one setting changes, and `addButtonLocation`, which maps it to `FloatingActionButtonLocation.startFloat` or `endFloat`. Todos, Notes, the deck list, and the deck screen set their `floatingActionButtonLocation` from it. `QuickAddBar` takes the side as a `buttonOnLeft` parameter from the Shopping screen rather than reading Settings itself, so it stays a plain widget; it mirrors the button order and padding.

`context.select` may only be called while that context's widget is building. `DeckScreen` builds its `Scaffold` inside a `BlocBuilder<DecksCubit>`, whose rebuilds (for example when a new card changes the deck's count) do not rebuild the screen's own element. The location is therefore read in `build()` and passed into `_buildDeck()`.

---

## Dependency Injection

All registrations are in `lib/injection_container.dart`, run in `main()` before `runApp()`.

| Registration | Type | Reason |
| --- | --- | --- |
| `SharedPreferences` | Eager singleton | Must be awaited before any Cubit reads it |
| `EncryptionService` | Eager singleton | Key must be loaded from secure storage before any note is read |
| `NotificationService` (as `PhaseNotifier`) | Eager singleton | Plugin must be initialised and the launch details read before the shell builds |
| `AppDatabase` | Lazy singleton | One connection for the whole app |
| `TodoRepository`, `ShoppingRepository`, `NoteRepository`, `FlashcardRepository` | Lazy singleton | One implementation each, registered against the abstract interface |
| `SettingsCubit` | Lazy singleton | Drives `MaterialApp.themeMode` and the add-button side; shared with the Settings screen |
| `TodoCubit`, `ShoppingCubit`, `NotesCubit`, `DecksCubit` | Lazy singleton | One per tab, alive for the session so tabs keep their state |
| `PomodoroCubit` | Lazy singleton, resolved in `main()` | Restores a running timer at launch |

`main.dart` provides the app-scoped Cubits with `BlocProvider.value` **above** `MaterialApp`, so pushed routes (settings, note editor, deck, study) can read them. `BlocProvider.value` does not close the Cubits it provides, which is correct for singletons owned by `get_it`.

`DeckCardsCubit` and `StudyCubit` are intentionally **not** registered here — see Flashcards → Screen-scoped Cubits.

---

## Key Constants

### AppConstants

`lib/core/constants/app_constants.dart`

| Constant | Value | What it controls |
| --- | --- | --- |
| `appName` | `Fieldbook` | `MaterialApp.title` |
| `databaseFile` | `fieldbook.db` | SQLite file name in the documents directory |
| `maxTodoTitleLength` | 200 | Todo title input limit (matches the column constraint) |
| `maxShoppingNameLength` | 120 | Shopping item name input limit (matches the column constraint) |
| `maxDeckNameLength` | 80 | Deck name column limit |
| `noteAutosaveDelay` | 600 ms | Debounce between the last keystroke and a note save |
| `timerTick` | 250 ms | Pomodoro recompute interval |

### Leitner

`lib/domain/entities/flashcard.dart`

| Constant | Value | What it controls |
| --- | --- | --- |
| `minBox` | 1 | New and missed cards |
| `maxBox` | 5 | Upper cap for correct answers |
| `learnedFrom` | 3 | Box from which a card counts as learned (also used in the deck summary SQL) |

### PomodoroSettings defaults and ranges

`lib/domain/entities/pomodoro.dart` (defaults) and `presentation/focus/widgets/settings_sheet.dart` (ranges)

| Setting | Default | Range |
| --- | --- | --- |
| `focusMinutes` | 25 | 1–120 |
| `shortBreakMinutes` | 5 | 1–60 |
| `longBreakMinutes` | 15 | 1–90 |
| `sessionsBeforeLongBreak` | 4 | 1–12 |
| `autoStartNext` | false | on / off |

### AppColors

`lib/core/theme/app_colors.dart`

| Constant | Value | Use |
| --- | --- | --- |
| `background` / `darkBackground` | `#F9FAFB` / `#121212` | Scaffold background |
| `surface` / `darkSurface` | `#FFFFFF` / `#1E1E1E` | Cards, sheets, dialogs, navigation bar |
| `border` / `darkBorder` | `#E5E7EB` / `#2C2C2C` | Card outlines, input borders, dividers |
| `accent` | `#10B981` | Primary colour, FABs, checked items, snackbar action in light mode |
| `accentOnLight` | `#047857` | Snackbar action in dark mode, on the light inverse surface |
| `focus` / `shortBreak` / `longBreak` | `#E11D48` / `#10B981` / `#3B82F6` | Pomodoro phase colours |
| `danger` | `#E11D48` | Overdue dates, swipe-to-delete background, destructive buttons |
