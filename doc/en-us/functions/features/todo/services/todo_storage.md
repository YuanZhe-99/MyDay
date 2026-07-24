# lib/features/todo/services/todo_storage.dart

`TodoStorage` is **the central storage/config hub for the whole app**, not just Todo — nearly every
other feature's storage service resolves its app directory through
[`TodoStorage.getAppDir()`](#getappdir), and every module's config-style settings (not just Todo's)
read/write through [`readConfig()`](#readconfig)/[`writeConfig()`](#writeconfig). This file defines
two persisted surfaces: `storage_config.json`, which **always** stays in the default app directory
regardless of any custom storage path (custom path itself, intimacy visibility, theme, locale, week
start day, tray settings, backup settings, local API settings), and `todo_data.json` (wrapped by
`TodoData`: daily templates, one-time tasks, the completion log, the score log, morning/completion
reminder settings, task sort modes/custom orders, `settingsModifiedAt`). See
[Todo](../../../../features/todo.md#storage) and
[Data Formats](../../../../data-formats.md#todo--todo_datajson) for the field-level concept
description, and [Architecture](../../../../architecture.md) for the app-wide write-queue/
atomic-write conventions this file implements. `Task`/`DailyCompletionLog`/`DailyScoreLog` come from
[`../models/task.dart`](../models/task.md); saves are preserved/validated via
[`JsonPreservation.encodeForFile`](../../../shared/utils/json_preservation.md#encodeforfile) and
[`DataFileSafety.writeValidatedDataJson`](../../../shared/services/data_file_safety.md#writevalidateddatajson).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`TodoData` (constructor)](#tododata-new) | constructor (`TodoData`) | A | Create a todo data instance, defaulting `dailyScores`/`settingsModifiedAt`. |
| [`TodoData.toJson`](#tojson) | method (`TodoData`) | A | Serialize the whole todo document to a JSON-compatible map. |
| [`TodoData.fromJson`](#fromjson) | factory constructor (`TodoData`) | A | Parse the whole todo document, migrating the old single-reminder format. |
| [`TodoStorageException` (constructor)](#todostorageexception-new) | const constructor (`TodoStorageException`) | A | Create a todo storage exception with a user-visible message. |
| `TodoStorageException.toString` | method (`TodoStorageException`) | B | Return the exception's message as its string representation. |
| [`_getDefaultAppDir`](#_getdefaultappdir) | static method (`TodoStorage`) | A | Resolve (and create if needed) the default `Documents/MyDay` app directory. |
| [`_getConfigFile`](#_getconfigfile) | static method (`TodoStorage`) | A | Resolve the `File` handle for `storage_config.json`. |
| [`getConfigFile`](#getconfigfile) | static method (`TodoStorage`) | A | Public access to the config file for other services. |
| [`readConfig`](#readconfig) | static method (`TodoStorage`) | A | Read the raw config JSON from disk. |
| [`writeConfig`](#writeconfig) | static method (`TodoStorage`) | A | Merge-write keys into the config JSON. |
| [`_loadConfig`](#_loadconfig) | static method (`TodoStorage`) | A | Lazily load and cache config fields from disk. |
| [`_saveConfig`](#_saveconfig) | static method (`TodoStorage`) | A | Merge-write the cached config fields back to disk. |
| [`getIntimacyVisible`](#getintimacyvisible) | static method (`TodoStorage`) | A | Get persisted intimacy-visible state. |
| [`setIntimacyVisible`](#setintimacyvisible) | static method (`TodoStorage`) | A | Set and persist intimacy-visible state. |
| [`getThemeMode`](#getthememode) | static method (`TodoStorage`) | A | Get persisted theme mode. |
| [`setThemeMode`](#setthememode) | static method (`TodoStorage`) | A | Set and persist theme mode. |
| [`getLocaleTag`](#getlocaletag) | static method (`TodoStorage`) | A | Get persisted locale tag. |
| [`setLocaleTag`](#setlocaletag) | static method (`TodoStorage`) | A | Set and persist locale tag. |
| [`getWeekStartDay`](#getweekstartday) | static method (`TodoStorage`) | A | Get the global calendar week start day. |
| [`setWeekStartDay`](#setweekstartday) | static method (`TodoStorage`) | A | Update the global calendar week start day. |
| [`getAppDir`](#getappdir) | static method (`TodoStorage`) | A | Resolve the active app data directory (default or custom). |
| [`_getFile`](#_getfile) | static method (`TodoStorage`) | A | Resolve the `File` handle for `todo_data.json`. |
| [`fileExists`](#fileexists) | static method (`TodoStorage`) | A | Check whether `todo_data.json` exists. |
| [`load`](#load) | static method (`TodoStorage`) | A | Load and parse `todo_data.json`. |
| [`save`](#save) | static method (`TodoStorage`) | A | Queue a write of `TodoData`, serialized against concurrent saves. |
| [`_saveNow`](#_savenow) | static method (`TodoStorage`) | A | Perform one preserved, validated, atomic write of `TodoData`. |
| [`getStoragePath`](#getstoragepath) | static method (`TodoStorage`) | A | Get the active storage directory path for display. |
| [`setStoragePath`](#setstoragepath) | static method (`TodoStorage`) | A | Change the custom storage directory, moving data files if needed. |
| [`getMinimizeToTray`](#getminimizetotray) | static method (`TodoStorage`) | A | Get persisted minimize-to-tray setting. |
| [`setMinimizeToTray`](#setminimizetotray) | static method (`TodoStorage`) | A | Set and persist minimize-to-tray setting. |
| [`getCloseToTray`](#getclosetotray) | static method (`TodoStorage`) | A | Get persisted close-to-tray setting. |
| [`setCloseToTray`](#setclosetotray) | static method (`TodoStorage`) | A | Set and persist close-to-tray setting. |
| [`_normalizeWeekStartDay`](#_normalizeweekstartday) | static method (`TodoStorage`) | A | Return a valid persisted week start day, defaulting invalid values to Monday. |

`grep -c 'Purpose:' lib/features/todo/services/todo_storage.dart` reports 33, matching all
thirty-three real declarations listed above exactly. No misattached doc comments were found — every
`/// Purpose:` block sits directly above the real constructor/method it documents — and no
undocumented real declaration exists either; the only non-`Purpose:`-documented members are plain
fields (`_fileName`, `_customPath`, `_configLoaded`, `_intimacyVisible`, `_themeMode`, `_localeTag`,
`_weekStartDay`, `_minimizeToTray`, `_closeToTray`, `_writeQueue`, `_dataFileNames`), which are data,
not declarations of behavior, and are correctly excluded from the table. Tier split: 32 Tier A / 1
Tier B. The single Tier B row is `TodoStorageException.toString`, a trivial accessor returning the
stored `message` field with no logic (the same pattern as `WeightStorageException.toString` in
[`weight_storage.dart`](../../weight/services/weight_storage.md#weightstorageexception-new)). Every
other declaration is Tier A: `TodoData`'s constructor/`toJson`/`fromJson` and
`TodoStorageException`'s constructor fall under the explicit models Tier A rule, and every
`TodoStorage` static method performs real config-caching, file-path-resolution, or file IO — the
explicit services/IO Tier A rule — even where an individual method's body is only one or two lines
(e.g. `_getConfigFile`, `getConfigFile`), consistent with how this repo's other storage services
(e.g. `WeightStorage._getFile`) classify their short IO-adjacent helpers as Tier A rather than as
trivial forwarding.

## Documentation

### `TodoData({required this.dailyTemplates, required this.oneTimeTasks, required this.dailyLog, DailyScoreLog? dailyScores, this.morningReminderHour, this.morningReminderMinute, this.completionReminderHour, this.completionReminderMinute, this.taskSortModes = const {}, this.taskCustomOrders = const {}, DateTime? settingsModifiedAt})` <a id="tododata-new"></a>
- **Kind:** constructor of `TodoData`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 33)
- **Purpose:** Create the whole todo document — task lists, logs, reminder settings, sort state —
  defaulting `dailyScores` to an empty `DailyScoreLog` and `settingsModifiedAt` to the Unix epoch.
- **Inputs:** `dailyTemplates`, `oneTimeTasks`, `dailyLog` (required); optional `dailyScores`,
  reminder hour/minute pairs, `taskSortModes`, `taskCustomOrders`, `settingsModifiedAt`.
- **Returns:** A new `TodoData`.
- **Side effects:** None.
- **Algorithm:** `dailyScores ??= DailyScoreLog()`; `settingsModifiedAt ??=
  DateTime.fromMillisecondsSinceEpoch(0)`; every other field is a direct assignment or literal
  default.
- **Usage:**
  ```dart
  await TodoStorage.save(
    TodoData(
      dailyTemplates: _dailyTemplates,
      oneTimeTasks: _oneTimeTasks,
      dailyLog: _dailyLog,
      dailyScores: _dailyScores,
      morningReminderHour: _morningReminderTime?.hour,
      /* ... */
    ),
  );
  ```
  (`lib/features/todo/views/todo_page.dart`, `_saveData`, lines 163-169).
- **Notes:** Defaulting `settingsModifiedAt` to the epoch (not "now") means a freshly created
  `TodoData` always loses a last-writer-wins settings merge against any peer that has ever saved
  settings before — the same deliberate "never overwrite a real prior value" convention as
  `WeightData`'s equivalent field.

### `Map<String, dynamic> toJson()` <a id="tojson"></a>
- **Kind:** method of `TodoData`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 54)
- **Purpose:** Serialize the whole todo document into the `todo_data.json` shape.
- **Inputs:** None.
- **Returns:** `Map<String, dynamic>` with `dailyTemplates`/`oneTimeTasks`/`dailyLog`/
  `settingsModifiedAt` always present, and `dailyScores`/reminder hour+minute/`taskSortModes`/
  `taskCustomOrders` only when non-empty/non-null.
- **Side effects:** None.
- **Algorithm:** Map literal with `t.toJson()` mapped over both task lists, `dailyLog.toJson()`, and
  conditional `if (...)` entries (`!dailyScores.isEmpty`, `!= null`, `.isNotEmpty`) for every
  optional field so absent settings are omitted rather than written as `null`.
- **Usage:** `data.toJson()` passed as `next` to `JsonPreservation.encodeForFile` in
  [`_saveNow`](#_savenow).
- **Notes:** Unlike `Task.toJson` (which always writes every key), this omits optional fields
  entirely when they're empty/absent — so an app that has never set a morning reminder never writes
  `morningReminderHour`/`morningReminderMinute` keys at all.

### `factory TodoData.fromJson(Map<String, dynamic> json)` <a id="fromjson"></a>
- **Kind:** factory constructor of `TodoData`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 76)
- **Purpose:** Reconstruct the whole todo document from its persisted/synced JSON shape, migrating
  the old single-reminder format to the current morning/completion split.
- **Inputs:** `json`.
- **Returns:** A new `TodoData`.
- **Side effects:** None.
- **Algorithm:**
  1. Read `json['dailyReminderHour']`/`['dailyReminderMinute']` as `oldH`/`oldM` (the pre-migration
     single-reminder keys).
  2. Parse `dailyTemplates`/`oneTimeTasks` via `Task.fromJson`; `dailyLog` via
     `DailyCompletionLog.fromJson` if present else a fresh `DailyCompletionLog()`; `dailyScores` via
     `DailyScoreLog.fromJson` if present else a fresh `DailyScoreLog()`.
  3. `morningReminderHour`/`Minute` read from their current keys, falling back to `oldH`/`oldM` if
     absent — so a file saved before the reminder split still surfaces as a morning reminder.
  4. `completionReminderHour`/`Minute` have no legacy fallback (the feature postdates the migration
     need).
  5. `taskSortModes`/`taskCustomOrders` parsed from their maps if present, else `const {}`.
  6. `settingsModifiedAt` parsed if present else the Unix epoch.
- **Usage:**
  ```dart
  data = await TodoStorage.load();
  ```
  which internally does `TodoData.fromJson(json)` inside [`load`](#load) after `jsonDecode`.
- **Notes:** The single-reminder-to-morning-reminder migration is read-only/implicit — it happens
  every time an old file is parsed, but nothing rewrites `dailyReminderHour`/`Minute` out of the
  file; the next `save()` simply stops writing those legacy keys (since `toJson` doesn't emit them).

### `const TodoStorageException(this.message)` <a id="todostorageexception-new"></a>
- **Kind:** const constructor of `TodoStorageException`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 127)
- **Purpose:** Create a todo storage exception carrying a user-visible message, thrown when
  `todo_data.json` exists but cannot be safely read or written.
- **Inputs:** `message`.
- **Returns:** A new `TodoStorageException`.
- **Side effects:** None.
- **Algorithm:** Plain field-initializing const constructor.
- **Usage:**
  ```dart
  throw TodoStorageException('$_fileName is not valid JSON: $e');
  ```
  (`load`, line 470; the analogous `'Failed to load $_fileName: $e'` case at line 472 covers any
  other read failure).
- **Notes:** Implements `Exception` (not `Error`), so it's meant to be caught and shown to the user —
  `todo_page.dart`'s `_loadData()` catches it and stores `e.toString()` as `_loadError`, which then
  blocks `_saveData()` from running until the next successful reload (see [`load`](#load)'s notes).

### `String toString()` (Tier B — table row only, no full entry)

### `static Future<Directory> _getDefaultAppDir()` <a id="_getdefaultappdir"></a>
- **Kind:** private static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 170)
- **Purpose:** Resolve (creating if needed) the default `<platform app documents dir>/MyDay`
  directory.
- **Inputs:** None.
- **Returns:** `Future<Directory>`.
- **Side effects:** Creates the `MyDay` directory on disk if it doesn't already exist.
- **Algorithm:** `dir = await getApplicationDocumentsDirectory()` (from `path_provider`); build
  `Directory('${dir.path}/MyDay')`; `create(recursive: true)` if it doesn't exist.
- **Usage:** Called from [`_getConfigFile`](#_getconfigfile) (always) and from [`getAppDir`](#getappdir)
  (only when no custom path is set).
- **Notes:** This is the one path `storage_config.json` always resolves through — it never depends
  on `_customPath`, which is exactly what keeps the config file pinned to the default location even
  when the user picks a custom storage path for the data files.

### `static Future<File> _getConfigFile()` <a id="_getconfigfile"></a>
- **Kind:** private static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 185)
- **Purpose:** Resolve the `File` handle for `storage_config.json`, always inside the default app
  directory.
- **Inputs:** None.
- **Returns:** `Future<File>`.
- **Side effects:** None directly (delegates directory creation to `_getDefaultAppDir`).
- **Algorithm:** `dir = await _getDefaultAppDir()`; `File('${dir.path}/$_configFileName')`.
- **Usage:** Called at the top of every config accessor in this file:
  [`getConfigFile`](#getconfigfile), [`readConfig`](#readconfig), [`writeConfig`](#writeconfig),
  [`_loadConfig`](#_loadconfig), [`_saveConfig`](#_saveconfig).
- **Notes:** None.

### `static Future<File> getConfigFile()` <a id="getconfigfile"></a>
- **Kind:** static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 196)
- **Purpose:** Expose `_getConfigFile()` publicly, per its doc comment, "for other services (e.g.
  `LocalApiServer`)".
- **Inputs:** None.
- **Returns:** `Future<File>` — the same file `getConfigFile() => _getConfigFile();` forwards to.
- **Side effects:** None.
- **Algorithm:** One-line forward to `_getConfigFile()`.
- **Usage:** No call sites found anywhere in `lib/` or `test/` — including `local_api_server.dart`,
  the module named in its own doc comment as the intended consumer. `LocalApiServer` in fact reads
  config through `TodoStorage.readConfig()` instead (e.g. `local_api_server.dart` line 69).
- **Notes:** Currently unused/dead code relative to its stated purpose; a future direct-file-access
  consumer would use this rather than duplicating `_getConfigFile`'s path logic.

### `static Future<Map<String, dynamic>> readConfig()` <a id="readconfig"></a>
- **Kind:** static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 204)
- **Purpose:** Read the raw config JSON, for modules that store their own keys directly rather than
  through this file's cached fields.
- **Inputs:** None.
- **Returns:** `Future<Map<String, dynamic>>` — the parsed config, or `{}` if the file is missing or
  unreadable.
- **Side effects:** Reads `storage_config.json` from disk.
- **Algorithm:** Resolve the file; if it exists, `jsonDecode` its contents and return as a map; any
  exception (missing file, bad JSON) is swallowed and `{}` is returned instead.
- **Usage:**
  ```dart
  final config = await TodoStorage.readConfig();
  _apiEnabled = config['apiEnabled'] as bool? ?? false;
  ```
  (`lib/features/settings/views/settings_page.dart`, `_loadApiSettings`, lines 190-197); also used
  by `BackupService.loadSettings()`, `TrayService`, `ReminderService`, and
  `local_api_server.dart` for their own module-specific keys.
- **Notes:** Unlike [`_loadConfig`](#_loadconfig), this never caches its result — every call re-reads
  and re-parses the file from disk.

### `static Future<void> writeConfig(Map<String, dynamic> config)` <a id="writeconfig"></a>
- **Kind:** static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 220)
- **Purpose:** Merge-write `config`'s keys into `storage_config.json` without clobbering keys other
  modules have written.
- **Inputs:** `config` — a partial map of keys to add/update; a `null` value under a key removes
  that key.
- **Returns:** `Future<void>`.
- **Side effects:** Reads then rewrites `storage_config.json`; invalidates the `_loadConfig` cache
  (`_configLoaded = false`) so the next cached-field read re-reads the file.
- **Algorithm:**
  1. Read the existing file into `existing` (or `{}` if missing/corrupt).
  2. `existing.addAll(config)` — overlays the new keys onto the existing map.
  3. `existing.removeWhere((_, v) => v == null)` — any key whose new value is `null` is dropped
     entirely, not written as JSON `null`.
  4. Write the merged map back, then set `_configLoaded = false`.
- **Usage:**
  ```dart
  await TodoStorage.writeConfig({
    'apiPort': newPort,
    'apiListenAddress': newAddr,
    'apiUsername': newUser.isEmpty ? null : newUser,
    'apiPassword': newPass.isEmpty ? null : newPass,
  });
  ```
  (`settings_page.dart`, lines 351-356, saving local API settings — note the inline `x.isEmpty ?
  null : x` pattern relying on `writeConfig`'s null-removes-the-key behavior).
- **Notes:** Because this is read-merge-write (not a blind overwrite), it's how `BackupService`'s
  `autoBackupEnabled`/`backupRetentionDays` keys and Todo's own cached fields (theme, locale, etc.,
  written via `_saveConfig`) coexist in the same file without either side needing to know the
  other's key set in advance.

### `static Future<void> _loadConfig()` <a id="_loadconfig"></a>
- **Kind:** private static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 243)
- **Purpose:** Lazily populate this class's static cached fields (`_customPath`,
  `_intimacyVisible`, `_themeMode`, `_localeTag`, `_weekStartDay`, `_minimizeToTray`,
  `_closeToTray`) from `storage_config.json`, at most once until invalidated.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Reads `storage_config.json` on the first call (or after `_configLoaded` is
  invalidated by `writeConfig`); mutates the static cache fields.
- **Algorithm:** If `_configLoaded` is already `true`, return immediately. Otherwise read and
  `jsonDecode` the config file (any exception is swallowed and ignored, leaving defaults in place),
  populate every cached field — `_intimacyVisible` is `true` if either `intimacyVisible` or the
  legacy `intimacyEverUnlocked` key is `true` — normalize `_weekStartDay` via
  [`_normalizeWeekStartDay`](#_normalizeweekstartday), then set `_configLoaded = true`
  unconditionally (even after a swallowed read error).
- **Usage:** Called at the top of every cached-field getter/setter in this file (`getIntimacyVisible`,
  `setIntimacyVisible`, `getThemeMode`, ..., `getAppDir`, `getMinimizeToTray`, `getCloseToTray`,
  etc.) to guarantee the cache is populated before it's read or mutated.
- **Notes:** A caught read error (corrupt/missing file) still sets `_configLoaded = true`, so a
  broken config file is treated as "load once, keep whatever in-memory defaults were already there"
  rather than retried on every call.

### `static Future<void> _saveConfig()` <a id="_saveconfig"></a>
- **Kind:** private static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 274)
- **Purpose:** Write this class's cached fields back into `storage_config.json`, preserving keys
  written by other modules (e.g. `BackupService`'s `autoBackupEnabled`/`backupRetentionDays`).
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Reads then rewrites `storage_config.json`.
- **Algorithm:** Read the existing file into `json` (or `{}`); for each cached field, either set its
  key (`_customPath`/`_themeMode`/`_localeTag`) or remove the key entirely when the field is at its
  "default"/`null` value (e.g. `_weekStartDay == DateTime.monday` removes the `weekStartDay` key
  rather than writing `1`); always removes the legacy `intimacyEverUnlocked` key unconditionally
  (fully migrated into `intimacyVisible`); writes the merged map.
- **Usage:** Called by every cached-field setter in this file (`setIntimacyVisible`, `setThemeMode`,
  `setLocaleTag`, `setWeekStartDay`, `setMinimizeToTray`, `setCloseToTray`) and by
  [`setStoragePath`](#setstoragepath).
- **Notes:** Unlike `writeConfig` (public, arbitrary-key merge-write), `_saveConfig` only ever writes
  this class's own known set of keys — it round-trips through the file (read then write) purely to
  avoid clobbering other modules' keys, not to merge in caller-supplied data.

### `static Future<bool> getIntimacyVisible()` <a id="getintimacyvisible"></a>
- **Kind:** static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 327)
- **Purpose:** Get persisted intimacy-feature visibility.
- **Inputs:** None.
- **Returns:** `Future<bool>`.
- **Side effects:** May trigger the first `_loadConfig()` read.
- **Algorithm:** `await _loadConfig(); return _intimacyVisible;`.
- **Usage:**
  ```dart
  final visible = await TodoStorage.getIntimacyVisible();
  state = IntimacyVisibility(visible: visible);
  ```
  (`lib/shared/providers/intimacy_visibility.dart`, `_loadPersistedState`, lines 45-47).
- **Notes:** None.

### `static Future<void> setIntimacyVisible(bool value)` <a id="setintimacyvisible"></a>
- **Kind:** static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 338)
- **Purpose:** Set and persist intimacy-feature visibility.
- **Inputs:** `value`.
- **Returns:** `Future<void>`.
- **Side effects:** Writes `storage_config.json` when the value actually changes.
- **Algorithm:** `await _loadConfig()`; if `value == _intimacyVisible`, return early (no write);
  otherwise update the cache and call `_saveConfig()`.
- **Usage:**
  ```dart
  void setVisible(bool visible) {
    state = state.copyWith(visible: visible);
    TodoStorage.setIntimacyVisible(visible);
  }
  ```
  (`intimacy_visibility.dart`, lines 56-59).
- **Notes:** The early-return-on-no-change avoids an unnecessary disk write on every toggle
  no-op, but note the call above isn't `await`ed by its caller — the write happens fire-and-forget
  from the provider's perspective.

### `static Future<String?> getThemeMode()` <a id="getthememode"></a>
- **Kind:** static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 351)
- **Purpose:** Get the persisted theme mode string.
- **Inputs:** None.
- **Returns:** `Future<String?>` — `null` means "follow system".
- **Side effects:** May trigger the first `_loadConfig()` read.
- **Algorithm:** `await _loadConfig(); return _themeMode;`.
- **Usage:** `final modeStr = await TodoStorage.getThemeMode();` (`lib/shared/providers/
  app_settings.dart`, `_loadPersisted`, line 27).
- **Notes:** None.

### `static Future<void> setThemeMode(String? mode)` <a id="setthememode"></a>
- **Kind:** static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 362)
- **Purpose:** Set and persist the theme mode string.
- **Inputs:** `mode` — `'light'`/`'dark'`/`null` (system).
- **Returns:** `Future<void>`.
- **Side effects:** Writes `storage_config.json` unconditionally (no early-return-if-unchanged,
  unlike `setIntimacyVisible`).
- **Algorithm:** `await _loadConfig(); _themeMode = mode; await _saveConfig();`.
- **Usage:**
  ```dart
  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    final str = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => null,
    };
    TodoStorage.setThemeMode(str);
  }
  ```
  (`app_settings.dart`, lines 58-66).
- **Notes:** Always writes, even if `mode` is unchanged from the cached value — unlike
  `setIntimacyVisible`'s guarded write.

### `static Future<String?> getLocaleTag()` <a id="getlocaletag"></a>
- **Kind:** static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 374)
- **Purpose:** Get the persisted locale tag.
- **Inputs:** None.
- **Returns:** `Future<String?>` — e.g. `'en'`, `'zh'`, `'zh_TW'`, `'ja'`, or `null` for system.
- **Side effects:** May trigger the first `_loadConfig()` read.
- **Algorithm:** `await _loadConfig(); return _localeTag;`.
- **Usage:** `final localeTag = await TodoStorage.getLocaleTag();` (`app_settings.dart`, line 28).
- **Notes:** None.

### `static Future<void> setLocaleTag(String? tag)` <a id="setlocaletag"></a>
- **Kind:** static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 385)
- **Purpose:** Set and persist the locale tag.
- **Inputs:** `tag`.
- **Returns:** `Future<void>`.
- **Side effects:** Writes `storage_config.json` unconditionally.
- **Algorithm:** `await _loadConfig(); _localeTag = tag; await _saveConfig();`.
- **Usage:**
  ```dart
  if (locale == null) {
    TodoStorage.setLocaleTag(null);
  } else {
    final tag = locale.countryCode != null
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    TodoStorage.setLocaleTag(tag);
  }
  ```
  (`app_settings.dart`, `setLocale`, lines 78-85).
- **Notes:** None.

### `static Future<int> getWeekStartDay()` <a id="getweekstartday"></a>
- **Kind:** static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 397)
- **Purpose:** Get the global calendar week start day shared by every calendar in the app.
- **Inputs:** None.
- **Returns:** `Future<int>` — Dart's Monday=1 through Sunday=7 numbering.
- **Side effects:** May trigger the first `_loadConfig()` read.
- **Algorithm:** `await _loadConfig(); return _weekStartDay;`.
- **Usage:** `final weekStartDay = await TodoStorage.getWeekStartDay();`
  (`lib/shared/widgets/app_date_picker.dart`, lines 20 and 46; also `app_settings.dart` line 29).
- **Notes:** `_loadConfig` already normalizes this value via `_normalizeWeekStartDay` when reading
  from disk, so this getter never needs to re-validate it.

### `static Future<void> setWeekStartDay(int weekday)` <a id="setweekstartday"></a>
- **Kind:** static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 408)
- **Purpose:** Update the global calendar week start day.
- **Inputs:** `weekday`.
- **Returns:** `Future<void>`.
- **Side effects:** Writes `storage_config.json` only when the normalized value actually changes.
- **Algorithm:** `await _loadConfig()`; normalize `weekday` via `_normalizeWeekStartDay`; if it
  equals the current cached value, return early (no write); otherwise update the cache and call
  `_saveConfig()`.
- **Usage:**
  ```dart
  void setWeekStartDay(int weekday) {
    final normalized = normalizeWeekStartDay(weekday);
    state = state.copyWith(weekStartDay: normalized);
    TodoStorage.setWeekStartDay(normalized);
  }
  ```
  (`app_settings.dart`, lines 93-97).
- **Notes:** Invalid values (outside Monday..Sunday) are silently normalized to Monday rather than
  rejected — see [`_normalizeWeekStartDay`](#_normalizeweekstartday).

### `static Future<Directory> getAppDir()` <a id="getappdir"></a>
- **Kind:** static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 421)
- **Purpose:** Resolve the directory data files are actually stored in — the custom path if one is
  set, otherwise the default `Documents/MyDay` directory.
- **Inputs:** None.
- **Returns:** `Future<Directory>`.
- **Side effects:** Creates the custom directory on disk if it doesn't exist yet (falls through to
  `_getDefaultAppDir`'s own creation otherwise).
- **Algorithm:** `await _loadConfig()`; if `_customPath` is set and non-empty, build/create that
  `Directory` and return it; otherwise return `_getDefaultAppDir()`.
- **Usage:** This is the single most widely used entry point in this file — nearly every other
  storage service resolves its directory through it, e.g.
  `final appDir = await TodoStorage.getAppDir();` in
  `lib/features/weight/services/weight_storage.dart` (line 39),
  `lib/features/intimacy/services/intimacy_storage.dart` (lines 40, 110),
  `lib/features/finance/services/finance_storage.dart` (line 157),
  `lib/features/finance/services/exchange_rate_storage.dart` (line 128),
  `lib/shared/services/image_service.dart`, `import_export_service.dart`, and `webdav_service.dart`
  (multiple call sites each), plus its own [`_getFile`](#_getfile).
- **Notes:** This is exactly the architectural reason `TodoStorage` is "the central storage/config
  hub for the whole app" rather than just the Todo feature's own storage class — every other
  feature's data file lives under whatever directory this method resolves to.

### `static Future<File> _getFile()` <a id="_getfile"></a>
- **Kind:** private static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 438)
- **Purpose:** Resolve the `File` handle for `todo_data.json` inside the active app directory.
- **Inputs:** None.
- **Returns:** `Future<File>`.
- **Side effects:** None directly (delegates directory resolution/creation to `getAppDir`).
- **Algorithm:** `appDir = await getAppDir()`; `File('${appDir.path}/$_fileName')`.
- **Usage:** Called from [`fileExists`](#fileexists), [`load`](#load), and [`_saveNow`](#_savenow).
- **Notes:** None.

### `static Future<bool> fileExists()` <a id="fileexists"></a>
- **Kind:** static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 449)
- **Purpose:** Check whether `todo_data.json` exists at all, without attempting to parse it.
- **Inputs:** None.
- **Returns:** `Future<bool>`.
- **Side effects:** None (a filesystem existence check).
- **Algorithm:** `file = await _getFile(); return file.exists();`.
- **Usage:** No call sites found anywhere in `lib/` or `test/` — callers that need to distinguish
  "no file" from "corrupt file" instead call [`load`](#load) directly and rely on its `null`
  return/thrown-exception distinction.
- **Notes:** Currently unused; kept as a lightweight existence check that doesn't require parsing.

### `static Future<TodoData?> load()` <a id="load"></a>
- **Kind:** static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 461)
- **Purpose:** Load and parse `todo_data.json`, returning `null` only when the file doesn't exist.
- **Inputs:** None.
- **Returns:** `Future<TodoData?>` — `null` if missing; otherwise a parsed `TodoData` or a thrown
  `TodoStorageException`.
- **Side effects:** Reads `todo_data.json` from disk.
- **Algorithm:**
  1. Resolve the file via `_getFile()`; if it doesn't exist, return `null` immediately.
  2. Otherwise read it as a string, `jsonDecode` it, and `TodoData.fromJson(json)`.
  3. A `FormatException` (invalid JSON) is caught and rethrown as
     `TodoStorageException('$_fileName is not valid JSON: $e')`.
  4. Any other exception (e.g. a `fromJson` cast failure) is caught and rethrown as
     `TodoStorageException('Failed to load $_fileName: $e')`.
- **Usage:**
  ```dart
  try {
    data = await TodoStorage.load();
  } catch (e) {
    ReminderService.instance.updateData(
      dailyTemplates: const [],
      oneTimeTasks: const [],
      dailyLog: DailyCompletionLog(),
    );
    if (!mounted) return;
    setState(() {
      _loadError = e.toString();
      _loaded = true;
    });
    return;
  }
  ```
  (`todo_page.dart`, `_loadData`, lines 92-109); also called from `local_api_server.dart` (many
  read/modify/save handlers) and `reminder_service.dart`.
- **Notes:** Missing vs. corrupt is deliberately distinguished — missing returns `null` ("no data
  yet"), corrupt/unreadable throws (an error state the UI must surface) — so a corrupted file is
  never silently treated as an empty dataset. `todo_page.dart` additionally uses the thrown
  `_loadError` to block [`save`](#save) calls until the next successful reload, via its own
  `_saveData()` guard.

### `static Future<void> save(TodoData data)` <a id="save"></a>
- **Kind:** static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 482)
- **Purpose:** Queue a write of `data`, ensuring overlapping `save` calls never interleave their
  writes to `todo_data.json`.
- **Inputs:** `data`.
- **Returns:** `Future<void>` that completes when this specific write (including its position in the
  queue) finishes.
- **Side effects:** Eventually writes `todo_data.json` (via `_saveNow`); mutates the static
  `_writeQueue` field.
- **Algorithm:**
  1. Chain onto the current `_writeQueue`: `next = _writeQueue.then((_) => _saveNow(data), onError:
     (_) => _saveNow(data))` — so `_saveNow(data)` runs whether the previous queued write succeeded
     or failed.
  2. Replace `_writeQueue` with `next.catchError((_) {})` (an error-swallowing view of `next`) so one
     failed save never permanently poisons the queue for later callers.
  3. Return `next` (the un-swallowed future) so *this* caller still observes any error from its own
     `_saveNow` call.
- **Usage:**
  ```dart
  await TodoStorage.save(
    TodoData(dailyTemplates: _dailyTemplates, oneTimeTasks: _oneTimeTasks, /* ... */),
  );
  ```
  (`todo_page.dart`, `_saveData`, lines 163-172); also called throughout `local_api_server.dart`
  after any REST-driven mutation.
- **Notes:** Because `_writeQueue` is a single static field, concurrent `save()` calls anywhere in
  the app (UI and the local REST API alike) are strictly serialized in call order — the same
  overlapping-writer protection AGENTS.md documents for every module's data-file storage.

### `static Future<void> _saveNow(TodoData data)` <a id="_savenow"></a>
- **Kind:** private static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 496)
- **Purpose:** Perform one actual write of `data` to `todo_data.json`, after the caller has already
  taken its turn in the write queue.
- **Inputs:** `data`.
- **Returns:** `Future<void>`.
- **Side effects:** Writes `todo_data.json` through a validated temporary file.
- **Algorithm:**
  1. Resolve the file via `_getFile()`.
  2. `JsonPreservation.encodeForFile(file: file, next: data.toJson(), schema:
     dataFilePreservationSchemas[_fileName]!)` — reads whatever is currently on disk and preserves
     any unknown fields into `data`'s serialized JSON (see
     [`json_preservation.dart`](../../../shared/utils/json_preservation.md#encodeforfile)).
  3. `DataFileSafety.writeValidatedDataJson(file, jsonStr)` — validates the encoded JSON, then
     atomically replaces the file via a same-directory temp file (see
     [`data_file_safety.dart`](../../../shared/services/data_file_safety.md#writevalidateddatajson)).
- **Usage:** Only called from `save()`, via the write-queue chain described above.
- **Notes:** `dataFilePreservationSchemas[_fileName]!` asserts a schema exists for `'todo_data.json'`
  — it does, defined as `_todoDataSchema` in `json_preservation.dart` — so this would only throw if
  that shared map were ever edited to drop the entry.

### `static Future<String> getStoragePath()` <a id="getstoragepath"></a>
- **Kind:** static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 512)
- **Purpose:** Get the active storage directory path, for display in Settings.
- **Inputs:** None.
- **Returns:** `Future<String>`.
- **Side effects:** None directly (delegates to `getAppDir`, which may create a directory).
- **Algorithm:** `appDir = await getAppDir(); return appDir.path;`.
- **Usage:** `final path = await TodoStorage.getStoragePath();`
  (`lib/features/settings/views/settings_page.dart`, `_loadStoragePath`, line 128).
- **Notes:** None.

### `static Future<bool> setStoragePath(String? newPath)` <a id="setstoragepath"></a>
- **Kind:** static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 536)
- **Purpose:** Change the custom storage directory, moving the app's known data files into it (or
  adopting whatever is already there) so no existing data is lost or duplicated.
- **Inputs:** `newPath` — `null` resets to the default location.
- **Returns:** `Future<bool>` — `true` on success, `false` if anything throws.
- **Side effects:** Persists `_customPath` via `_saveConfig()`; may create the new directory; may
  copy-then-delete each of `_dataFileNames` (`todo_data.json`, `finance_data.json`,
  `exchange_rates.json`, `intimacy_data.json`, `weight_data.json`, `webdav_config.json`) from the
  old directory to the new one.
- **Algorithm:**
  1. Resolve `oldDir` via `getAppDir()` (before changing anything).
  2. Set `_customPath = newPath` and persist it via `_saveConfig()`.
  3. Resolve `newDir` via `getAppDir()` again; if it's the same path as `oldDir`, return `true`
     immediately (no file movement needed).
  4. For each name in `_dataFileNames`: if the file already exists at the new location, leave it
     alone (adopt what's there); else if it exists at the old location, `copy` then `delete` it
     (move semantics).
  5. Any exception anywhere in this process is caught and turned into a `false` return.
- **Usage:**
  ```dart
  final ok = await TodoStorage.setStoragePath(pathToSet);
  if (ok) {
    await _loadStoragePath();
    /* show settingsResetDefaultLocation or settingsStoragePathUpdated snackbar */
  }
  ```
  (`settings_page.dart`, lines 766-779).
- **Notes:** `storage_config.json` itself is never in `_dataFileNames` and is never moved — it
  always stays in the default app directory (per `_getConfigFile`/`_getDefaultAppDir`), even after a
  custom storage path is set for everything else. Directories such as `images/`, `backups/`, and
  `.sync_base/` are also not moved by this file list (per AGENTS.md).

### `static Future<bool> getMinimizeToTray()` <a id="getminimizetotray"></a>
- **Kind:** static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 571)
- **Purpose:** Get the persisted "minimize to tray" setting.
- **Inputs:** None.
- **Returns:** `Future<bool>`.
- **Side effects:** May trigger the first `_loadConfig()` read.
- **Algorithm:** `await _loadConfig(); return _minimizeToTray;`.
- **Usage:**
  ```dart
  _minimizeToTray = await TodoStorage.getMinimizeToTray();
  _closeToTray = await TodoStorage.getCloseToTray();
  ```
  (`lib/shared/services/tray_service.dart`, `init`, lines 51-52).
- **Notes:** None.

### `static Future<void> setMinimizeToTray(bool value)` <a id="setminimizetotray"></a>
- **Kind:** static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 581)
- **Purpose:** Set and persist the "minimize to tray" setting.
- **Inputs:** `value`.
- **Returns:** `Future<void>`.
- **Side effects:** Writes `storage_config.json` unconditionally.
- **Algorithm:** `await _loadConfig(); _minimizeToTray = value; await _saveConfig();`.
- **Usage:**
  ```dart
  Future<void> setMinimizeToTray(bool value) async {
    _minimizeToTray = value;
    await TodoStorage.setMinimizeToTray(value);
  }
  ```
  (`tray_service.dart`, lines 99-102).
- **Notes:** None.

### `static Future<bool> getCloseToTray()` <a id="getclosetotray"></a>
- **Kind:** static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 592)
- **Purpose:** Get the persisted "close to tray" setting.
- **Inputs:** None.
- **Returns:** `Future<bool>`.
- **Side effects:** May trigger the first `_loadConfig()` read.
- **Algorithm:** `await _loadConfig(); return _closeToTray;`.
- **Usage:** `tray_service.dart`, `init`, line 52 (quoted above under `getMinimizeToTray`).
- **Notes:** None.

### `static Future<void> setCloseToTray(bool value)` <a id="setclosetotray"></a>
- **Kind:** static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 602)
- **Purpose:** Set and persist the "close to tray" setting.
- **Inputs:** `value`.
- **Returns:** `Future<void>`.
- **Side effects:** Writes `storage_config.json` unconditionally.
- **Algorithm:** `await _loadConfig(); _closeToTray = value; await _saveConfig();`.
- **Usage:**
  ```dart
  Future<void> setCloseToTray(bool value) async {
    _closeToTray = value;
    await TodoStorage.setCloseToTray(value);
    await windowManager.setPreventClose(value);
  }
  ```
  (`tray_service.dart`, lines 109-113).
- **Notes:** `TodoStorage.setCloseToTray` itself has no knowledge of `windowManager` —
  `TrayService` is responsible for applying the OS-level effect after persisting the setting.

### `static int _normalizeWeekStartDay(int? weekday)` <a id="_normalizeweekstartday"></a>
- **Kind:** private static method of `TodoStorage`
- **Source:** `lib/features/todo/services/todo_storage.dart` (line 613)
- **Purpose:** Return a valid persisted week start day, defaulting invalid or missing values to
  Monday.
- **Inputs:** `weekday` — nullable, expected to be `DateTime.monday`..`DateTime.sunday` (1-7).
- **Returns:** `int` — always in `[DateTime.monday, DateTime.sunday]`.
- **Side effects:** None.
- **Algorithm:** If `weekday` is `null` or outside `[DateTime.monday, DateTime.sunday]`, return
  `DateTime.monday`; otherwise return it unchanged.
- **Usage:** Called from [`_loadConfig`](#_loadconfig) (normalizing whatever was read from disk) and
  [`setWeekStartDay`](#setweekstartday) (normalizing the caller-supplied value before comparing/
  storing it).
- **Notes:** This is the only validation `setWeekStartDay` performs — an invalid input silently
  becomes Monday rather than throwing or being rejected.
