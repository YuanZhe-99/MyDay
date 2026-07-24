# lib/features/settings/views/settings_page.dart

The main Settings screen: General (language/week-start/theme), Privacy (Intimacy module hide/show),
Desktop (tray, launch-at-startup, local API server, custom storage location), Data (WebDAV sync,
ZIP import/export, backup), About (version, license, privacy policy), and a debug-only subscription
date-override section. `SettingsPage`/`_SettingsPageState` own the read/write plumbing for most of
these settings directly (via `TodoStorage.readConfig`/`writeConfig`, `TrayService`, `launchAtStartup`,
and `LocalApiServer`), while WebDAV sync and backup are delegated to
[`webdav_config_page.dart`](../../../shared/views/webdav_config_page.md) and
[`backup_page.dart`](../../../shared/views/backup_page.md), and the About section links out to
[`license_page.dart`](license_page.md) and [`privacy_policy_page.dart`](privacy_policy_page.md). See
[Settings](../../../../features/settings.md) for the full section-by-section feature description,
[Platform Notes](../../../../platform-notes.md) for the desktop-only tray/startup/local-API mechanics
this page exposes toggles for, and [WebDAV Sync](../../../../sync.md) for the auto-sync trigger this
page's WebDAV status tile reacts to.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `SettingsPage({super.key})` | constructor (`SettingsPage`) | B | Create a settings page instance. |
| `createState` | method (`SettingsPage`) | B | Create the mutable state object for this widget. |
| `_isDesktop` | getter (`_SettingsPageState`) | B | Whether the current platform is Windows/macOS/Linux. |
| `initState` | method (`_SettingsPageState`) | B | Kick off all the settings-loading calls and register the sync-status listener. |
| `dispose` | method (`_SettingsPageState`) | B | Unregister the sync-status listener. |
| `_refreshSyncStatus` | method (`_SettingsPageState`) | B | Trigger a rebuild when background sync status changes. |
| `_loadTraySettings` | method (`_SettingsPageState`) | B | Load minimize/close-to-tray flags from `TrayService`. |
| `_loadStoragePath` | method (`_SettingsPageState`) | B | Load the current data storage path. |
| [`_openDataFolder`](#opendatafolder) | method (`_SettingsPageState`) | A | Open the app data folder in the OS file manager. |
| `_loadVersion` | method (`_SettingsPageState`) | B | Load and format the app version string. |
| `_loadWebDAVStatus` | method (`_SettingsPageState`) | B | Load whether WebDAV sync is configured. |
| `_loadAutoStartStatus` | method (`_SettingsPageState`) | B | Load whether launch-at-startup is enabled. |
| `_loadApiSettings` | method (`_SettingsPageState`) | B | Load local API server settings from config. |
| `_exportData` | method (`_SettingsPageState`) | B | Export all app data to a user-picked directory as a ZIP. |
| `_importData` | method (`_SettingsPageState`) | B | Import app data from a user-picked ZIP after confirmation. |
| [`_showApiSettingsDialog`](#showapisettingsdialog) | method (`_SettingsPageState`) | A | Edit and save local API server settings, then restart the server. |
| `signature` (local function) | function (local, inside `_showApiSettingsDialog`) | B | Compute a change-detection signature for the API settings form. |
| `build` | method (`_SettingsPageState`) | B | Build the Settings page's section list for the current state. |
| `_buildSection` | method (widget helper) | B | Render one titled settings section. |
| [`_showStoragePathDialog`](#showstoragepathdialog) | method (`_SettingsPageState`) | A | Edit the custom storage path, including resetting to the default. |
| `_showThemePicker` | method (`_SettingsPageState`) | B | Show the theme-mode picker bottom sheet. |
| `_showWeekStartPicker` | method (`_SettingsPageState`) | B | Show the global week-start-day picker bottom sheet. |
| [`_showLanguagePicker`](#showlanguagepicker) | method (`_SettingsPageState`) | A | Show the app-language picker, parsing the selection into a `Locale`. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/settings/views/settings_page.dart` returns 23.
All 23 blocks document real declarations (22 methods/constructors/a getter, plus the nested local
function `signature()` declared inside `_showApiSettingsDialog`, which itself has its own `Purpose:`
block) — no misattached blocks and no undocumented real declarations were found. The instance fields
at the top of `_SettingsPageState` (`_storagePath`, `_apiPort`, etc.) have no `Purpose:` block,
consistent with them being state, not functions.

## Documentation

### `Future<void> _openDataFolder()` <a id="opendatafolder"></a>
- **Kind:** method of `_SettingsPageState`
- **Source:** `lib/features/settings/views/settings_page.dart` (line 137)
- **Purpose:** Open the app data directory in the host OS's file manager, using the correct native
  command per desktop platform.
- **Inputs:** None (reads `TodoStorage.getAppDir()`).
- **Returns:** `Future<void>`.
- **Side effects:** Launches an external OS process (`explorer`, `open`, or `xdg-open`).
- **Algorithm:**
  1. Resolve the app data directory via `TodoStorage.getAppDir()`.
  2. On Windows, run `explorer <path>`.
  3. On macOS, run `open <path>`.
  4. On Linux, convert the directory to a `file://`-style path via `Uri.directory(...).toFilePath()`
     and run `xdg-open <path>`.
  5. No branch runs on other platforms (mobile), so the tile that calls this is only shown when
     `_isDesktop` is true.
- **Usage:**
  ```dart
  ListTile(
    leading: const Icon(Icons.folder_open_outlined),
    title: Text(l10n.settingsOpenDataFolder),
    subtitle: Text(l10n.settingsOpenDataFolderDesc),
    onTap: _openDataFolder,
  ),
  ```
- **Notes:** Each platform needs a different native command and, on Linux, a different path
  encoding (`Uri.directory` rather than the raw path string) — there is no cross-platform "reveal in
  file manager" API in the packages this app uses.

### `Future<void> _showApiSettingsDialog()` <a id="showapisettingsdialog"></a>
- **Kind:** method of `_SettingsPageState`
- **Source:** `lib/features/settings/views/settings_page.dart` (line 272)
- **Purpose:** Let the user edit the local API server's listen address, port, username, and
  password, then persist the change and restart the server so it picks up the new settings.
- **Inputs:** None (reads current `_apiPort`/`_apiListenAddress`/`_apiUsername`/`_apiPassword` to
  seed the dialog's text controllers).
- **Returns:** `Future<void>`.
- **Side effects:** Writes `apiPort`/`apiListenAddress`/`apiUsername`/`apiPassword` to
  `storage_config.json` via `TodoStorage.writeConfig`; calls `LocalApiServer.restart()`; shows a
  confirmation snackbar; updates `_apiPort`/`_apiListenAddress`/`_apiUsername`/`_apiPassword` state.
- **Algorithm:**
  1. Seed four `TextEditingController`s from the current settings and capture an initial
     `signature()` (a joined-string fingerprint of all four fields, via the shared `formSignature`
     helper) for unsaved-changes detection.
  2. Show an `AlertDialog` wrapped in `UnsavedChangesGuard`, comparing the live `signature()` against
     `initialSignature` to decide whether Cancel should warn before discarding.
  3. If the user saves (`saved == true`) and the widget is still mounted: parse the port field with
     `int.tryParse(...) ?? 7790` (falls back to the default on invalid input); normalize an empty
     address to `'localhost'`; normalize empty username/password to `null` (rather than an empty
     string) so clearing a credential actually removes it from config, not just blanks it.
  4. Write all four values via `TodoStorage.writeConfig`, update local state, then call
     `LocalApiServer.restart()` so the running server picks up the new bind address/port/credentials.
  5. If still mounted, `setState` again and show a snackbar reporting the server's (possibly new)
     port via `LocalApiServer.port`.
- **Usage:**
  ```dart
  ListTile(
    leading: const Icon(Icons.settings_outlined),
    title: Text(l10n.settingsApiServer),
    trailing: const Icon(Icons.chevron_right),
    enabled: _apiEnabled,
    onTap: _apiEnabled ? _showApiSettingsDialog : null,
  ),
  ```
- **Notes:** The empty-string-to-`null` normalization for username/password is what lets a user
  clear stored API credentials back to "no auth" — writing `''` instead would leave a
  falsy-but-non-null credential in config. See [Platform Notes](../../../../platform-notes.md) for
  the local API's credential-required-for-non-loopback-binding rule this dialog's fields feed into.

### `Future<void> _showStoragePathDialog(BuildContext context)` <a id="showstoragepathdialog"></a>
- **Kind:** method of `_SettingsPageState`
- **Source:** `lib/features/settings/views/settings_page.dart` (line 721)
- **Purpose:** Let the user view and change the custom data storage path, or reset it back to the
  app's default location.
- **Inputs:** `context` — used for the dialog and post-save snackbar.
- **Returns:** `Future<void>`.
- **Side effects:** May call `TodoStorage.setStoragePath(...)`, which moves the app's data files;
  reloads `_storagePath`; shows a result snackbar.
- **Algorithm:**
  1. Seed a `TextEditingController` with the current `_storagePath` and show an `AlertDialog`
     wrapped in `UnsavedChangesGuard` with three actions: Cancel (discard, guarded), "reset default"
     (pops with an empty string), and Save (pops with the trimmed field text).
  2. If the dialog was dismissed with `null` (cancelled), return without doing anything.
  3. Otherwise treat an empty string as "reset to default" by converting it to `null` before calling
     `TodoStorage.setStoragePath(pathToSet)`; a non-empty string is passed through as the new path.
  4. If `setStoragePath` reports success, reload `_storagePath` via `_loadStoragePath()` and, if still
     mounted, show a snackbar whose text depends on whether the path was reset (`pathToSet == null`)
     or set to a new custom location.
- **Usage:**
  ```dart
  ListTile(
    leading: const Icon(Icons.folder_outlined),
    title: Text(l10n.settingsStorageLocation),
    subtitle: Text(_storagePath, maxLines: 2, overflow: TextOverflow.ellipsis),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => _showStoragePathDialog(context),
  ),
  ```
- **Notes:** The empty-string-means-reset convention mirrors `_showApiSettingsDialog`'s
  empty-means-clear convention for credentials — both use a blank field, not a separate control, to
  signal "go back to the default/unset state."

### `void _showLanguagePicker(BuildContext context, AppSettings settings)` <a id="showlanguagepicker"></a>
- **Kind:** method of `_SettingsPageState`
- **Source:** `lib/features/settings/views/settings_page.dart` (line 875)
- **Purpose:** Show a bottom sheet letting the user pick "follow system" or one of the four
  supported app languages, converting the selection into the `Locale` the app settings provider
  expects.
- **Inputs:** `context`; `settings` — the current `AppSettings`, used to compute the pre-selected
  radio value.
- **Returns:** `None`.
- **Side effects:** Calls `ref.read(appSettingsProvider.notifier).setLocale(locale)`; pops the sheet.
- **Algorithm:**
  1. Compute `currentTag` from `settings.locale` (`languageCode` plus `_countryCode` suffix if
     present), or `'system'` if `settings.locale` is null.
  2. Show a modal sheet with a `RadioGroup<String>` over five fixed options: system, `en`, `zh`,
     `zh_TW`, `ja`.
  3. On selection: if the code is exactly `'zh_TW'`, construct `Locale('zh', 'TW')` explicitly
     (Dart's `Locale(code)` constructor cannot parse an underscore-joined region tag); else if the
     code is non-null and not `'system'`, construct `Locale(code)`; else leave `locale` as `null`
     (follow system).
  4. Call `setLocale(locale)` and pop the sheet.
- **Usage:**
  ```dart
  ListTile(
    leading: const Icon(Icons.language),
    title: Text(l10n.settingsLanguage),
    subtitle: Text(localeLabel),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => _showLanguagePicker(context, settings),
  ),
  ```
- **Notes:** The `zh_TW` special case is the one branch here that isn't a generic single-argument
  `Locale(code)` call — omitting it would either throw or silently produce the wrong locale for
  Traditional Chinese, since `Locale('zh_TW')` is not the same as `Locale('zh', 'TW')`.

## Related pages

- [Settings](../../../../features/settings.md) — the section-by-section feature description this
  page implements.
- [Platform Notes](../../../../platform-notes.md) — the local API server config keys edited by
  `_showApiSettingsDialog`, and the tray/startup mechanics behind the Desktop section's other toggles.
- [WebDAV Sync](../../../../sync.md) and [Backup & Restore](../../../../backup-restore.md) — the
  Data section's underlying behavior, implemented in
  [`webdav_config_page.dart`](../../../shared/views/webdav_config_page.md) and
  [`backup_page.dart`](../../../shared/views/backup_page.md).
