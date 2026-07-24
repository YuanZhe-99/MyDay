# lib/shared/services/tray_service.dart

Desktop-only (Windows/macOS/Linux) singleton managing the system tray icon/menu and window
hide/show behavior, mixing in `TrayListener` and `WindowListener` from `tray_manager` /
`window_manager`. Initialized from `main()` (see
[../../../architecture.md#startup-sequence](../../../architecture.md#startup-sequence)) and
configured from the Settings page's desktop section (minimize-to-tray, close-to-tray).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `TrayService._()` | constructor (`TrayService`) | B | Prevent direct instantiation of the tray singleton. |
| `minimizeToTray` | getter (`TrayService`) | B | Return the current minimize-to-tray setting. |
| `closeToTray` | getter (`TrayService`) | B | Return the current close-to-tray setting. |
| [`init`](#init) | method (`TrayService`) | A | Initialize tray icon and window-manager hooks (desktop only). |
| [`_setupTray`](#_setuptray) | method (`TrayService`) | A | Set the tray icon/tooltip and build the initial menu. |
| [`_rebuildMenu`](#_rebuildmenu) | method (`TrayService`) | A | Rebuild the tray context menu using the current locale. |
| [`setMinimizeToTray`](#setminimizetotray) | method (`TrayService`) | A | Persist the minimize-to-tray setting. |
| [`setCloseToTray`](#setclosetotray) | method (`TrayService`) | A | Persist the close-to-tray setting and update window-manager's prevent-close flag. |
| [`updateLocale`](#updatelocale) | method (`TrayService`) | A | Update the tray's locale and rebuild menu labels. |
| [`onTrayIconMouseDown`](#ontrayiconmousedown) | method (`TrayService`, `TrayListener`) | A | Show the window when the tray icon is left-clicked. |
| [`onTrayIconRightMouseDown`](#ontrayiconrightmousedown) | method (`TrayService`, `TrayListener`) | A | Pop up the tray context menu on right-click. |
| [`onTrayMenuItemClick`](#ontraymenuitemclick) | method (`TrayService`, `TrayListener`) | A | Handle Show/Quit tray menu selections. |
| [`onWindowClose`](#onwindowclose) | method (`TrayService`, `WindowListener`) | A | Hide to tray or destroy the window on close, per setting. |
| [`onWindowMinimize`](#onwindowminimize) | method (`TrayService`, `WindowListener`) | A | Hide to tray on minimize, per setting. |
| [`_showWindow`](#_showwindow) | method (`TrayService`) | A | Restore the dock icon and bring the window to front. |
| [`_setDockIconVisible`](#_setdockiconvisible) | static method (`TrayService`) | A | Toggle macOS Dock icon visibility via platform channel. |

`grep -c 'Purpose:' lib/shared/services/tray_service.dart` reports 16, matching all sixteen real
declarations in this file. No misattachment or undocumented declarations found. All non-trivial
methods are classified Tier A per the blanket "services" rule (this whole class is
`shared/services/tray_service.dart`), including the short one-line `TrayListener`/`WindowListener`
event handlers, since each one performs real IO (window/tray manager calls or a platform channel
invocation) rather than pure widget composition.

## Documentation

### `Future<void> init()` <a id="init"></a>
- **Kind:** method of `TrayService`
- **Source:** `lib/shared/services/tray_service.dart` (line 47)
- **Purpose:** Initialize the tray icon and window-manager hooks; a no-op off desktop or after the
  first successful call.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Reads persisted `minimizeToTray`/`closeToTray` from `TodoStorage`; initializes
  `window_manager`, registers `this` as a `WindowListener`, sets `preventClose`; builds the tray
  icon/menu (`_setupTray`); registers `this` as a `TrayListener`; sets `_initialized = true`.
- **Algorithm:**
  1. Return immediately if `_initialized` or if not on Windows/macOS/Linux.
  2. Load `minimizeToTray`/`closeToTray` from `TodoStorage`.
  3. `windowManager.ensureInitialized()`, add `this` as a listener, `setPreventClose(_closeToTray)`.
  4. `_setupTray()`, then add `this` as a `trayManager` listener.
  5. Mark `_initialized = true`.
- **Usage:**
  ```dart
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await TrayService.instance.init();
  }
  ```
  (`lib/main.dart`, startup sequence.)
- **Notes:** Idempotent via the `_initialized` guard — safe to call more than once.

### `Future<void> _setupTray()` <a id="_setuptray"></a>
- **Kind:** private method of `TrayService`
- **Source:** `lib/shared/services/tray_service.dart` (line 69)
- **Purpose:** Set the platform-appropriate tray icon and tooltip, then build the initial menu.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Calls `trayManager.setIcon`, `setToolTip('MyDay!!!!!')`; calls
  `_rebuildMenu()`.
- **Algorithm:** Pick `assets/app_icon.ico` on Windows or `assets/icon/app_icon.png` elsewhere; set
  icon and tooltip; build the menu.
- **Usage:** Called once from `init()`.
- **Notes:** None.

### `Future<void> _rebuildMenu()` <a id="_rebuildmenu"></a>
- **Kind:** private method of `TrayService`
- **Source:** `lib/shared/services/tray_service.dart` (line 82)
- **Purpose:** Rebuild the tray's context menu (Show / separator / Quit) using localized labels for
  the current locale.
- **Inputs:** None (reads `_locale`).
- **Returns:** `Future<void>`.
- **Side effects:** Calls `trayManager.setContextMenu(menu)`.
- **Algorithm:** `lookupAppLocalizations(_locale)`; build a `Menu` with a `'show'` item
  (`trayShow`), a separator, and a `'quit'` item (`trayQuit`); apply it.
- **Usage:** Called from `_setupTray()` and from `updateLocale()`.
- **Notes:** None.

### `Future<void> setMinimizeToTray(bool value)` <a id="setminimizetotray"></a>
- **Kind:** method of `TrayService`
- **Source:** `lib/shared/services/tray_service.dart` (line 99)
- **Purpose:** Update and persist whether minimizing the window hides it to the tray.
- **Inputs:** `value`.
- **Returns:** `Future<void>`.
- **Side effects:** Updates `_minimizeToTray`; calls `TodoStorage.setMinimizeToTray(value)`.
- **Algorithm:** `_minimizeToTray = value; await TodoStorage.setMinimizeToTray(value);`
- **Usage:**
  ```dart
  await TrayService.instance.setMinimizeToTray(value);
  ```
  (`lib/features/settings/views/settings_page.dart`, desktop settings toggle.)
- **Notes:** None.

### `Future<void> setCloseToTray(bool value)` <a id="setclosetotray"></a>
- **Kind:** method of `TrayService`
- **Source:** `lib/shared/services/tray_service.dart` (line 109)
- **Purpose:** Update and persist whether closing the window hides it to the tray instead of
  quitting, and keep `window_manager`'s prevent-close flag in sync.
- **Inputs:** `value`.
- **Returns:** `Future<void>`.
- **Side effects:** Updates `_closeToTray`; calls `TodoStorage.setCloseToTray(value)`; calls
  `windowManager.setPreventClose(value)`.
- **Algorithm:** `_closeToTray = value; await TodoStorage.setCloseToTray(value); await
  windowManager.setPreventClose(value);`
- **Usage:**
  ```dart
  await TrayService.instance.setCloseToTray(value);
  ```
  (`lib/features/settings/views/settings_page.dart`, desktop settings toggle.)
- **Notes:** `setPreventClose` is what makes `onWindowClose` fire instead of the OS closing the
  window immediately, so this call must stay in sync with `_closeToTray` for `onWindowClose`'s
  branch to behave correctly.

### `Future<void> updateLocale(Locale locale)` <a id="updatelocale"></a>
- **Kind:** method of `TrayService`
- **Source:** `lib/shared/services/tray_service.dart` (line 121)
- **Purpose:** Update the locale used for tray menu labels and rebuild the menu if the tray is
  already initialized.
- **Inputs:** `locale`.
- **Returns:** `Future<void>`.
- **Side effects:** Updates `_locale`; conditionally calls `_rebuildMenu()`.
- **Algorithm:** `_locale = locale; if (_initialized) await _rebuildMenu();`
- **Usage:**
  ```dart
  TrayService.instance.updateLocale(resolvedLocale);
  ```
  (`lib/shared/providers/app_settings.dart`, `_loadPersisted`/`setLocale`, keeping tray labels in
  sync with the app's locale — see [../providers/app_settings.md](../providers/app_settings.md).)
- **Notes:** Skips rebuilding when not yet initialized (e.g. on mobile, or before `init()` runs) so
  the locale is simply cached for later.

### `void onTrayIconMouseDown()` <a id="ontrayiconmousedown"></a>
- **Kind:** method of `TrayService` (`TrayListener` override)
- **Source:** `lib/shared/services/tray_service.dart` (line 134)
- **Purpose:** Restore the window when the user left-clicks the tray icon.
- **Inputs:** None (callback from `tray_manager`).
- **Returns:** None.
- **Side effects:** Calls `_showWindow()`.
- **Algorithm:** Direct forward to `_showWindow()`.
- **Usage:** Invoked by `tray_manager` itself, not application code.
- **Notes:** None.

### `void onTrayIconRightMouseDown()` <a id="ontrayiconrightmousedown"></a>
- **Kind:** method of `TrayService` (`TrayListener` override)
- **Source:** `lib/shared/services/tray_service.dart` (line 143)
- **Purpose:** Open the tray context menu on right-click.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Calls `trayManager.popUpContextMenu()`.
- **Algorithm:** Direct forward to `trayManager.popUpContextMenu()`.
- **Usage:** Invoked by `tray_manager` itself.
- **Notes:** None.

### `void onTrayMenuItemClick(MenuItem menuItem)` <a id="ontraymenuitemclick"></a>
- **Kind:** method of `TrayService` (`TrayListener` override)
- **Source:** `lib/shared/services/tray_service.dart` (line 153)
- **Purpose:** Handle the Show/Quit tray menu items.
- **Inputs:** `menuItem` (its `key` distinguishes the selection).
- **Returns:** None.
- **Side effects:** `'show'` calls `_showWindow()`; `'quit'` calls
  `windowManager.setPreventClose(false)` then `windowManager.close()`.
- **Algorithm:** `switch (menuItem.key)` over `'show'`/`'quit'`.
- **Usage:** Invoked by `tray_manager` when a menu item is selected.
- **Notes:** Quit explicitly disables prevent-close first so the app actually exits instead of
  being intercepted by `onWindowClose`'s close-to-tray branch.

### `void onWindowClose()` <a id="onwindowclose"></a>
- **Kind:** method of `TrayService` (`WindowListener` override)
- **Source:** `lib/shared/services/tray_service.dart` (line 175)
- **Purpose:** Hide to tray instead of quitting when `closeToTray` is enabled; otherwise actually
  destroy the window.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** `windowManager.hide()` + `_setDockIconVisible(false)`, or
  `windowManager.destroy()`.
- **Algorithm:** `if (_closeToTray) { hide + hide dock icon } else { destroy }`.
- **Usage:** Invoked by `window_manager` when the close button is pressed (only fires because
  `setPreventClose(_closeToTray)` was set in `init()`/`setCloseToTray`).
- **Notes:** Relies on `windowManager.setPreventClose` having been kept in sync by
  `setCloseToTray`/`init()` — otherwise this listener would never fire on close.

### `void onWindowMinimize()` <a id="onwindowminimize"></a>
- **Kind:** method of `TrayService` (`WindowListener` override)
- **Source:** `lib/shared/services/tray_service.dart` (line 189)
- **Purpose:** Hide to tray on minimize when `minimizeToTray` is enabled.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** `windowManager.hide()` + `_setDockIconVisible(false)` when enabled.
- **Algorithm:** `if (_minimizeToTray) { hide + hide dock icon }`.
- **Usage:** Invoked by `window_manager` on minimize.
- **Notes:** None.

### `void _showWindow()` <a id="_showwindow"></a>
- **Kind:** private method of `TrayService`
- **Source:** `lib/shared/services/tray_service.dart` (line 204)
- **Purpose:** Bring the app window back to front and restore the macOS Dock icon.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** `_setDockIconVisible(true)`; `windowManager.show()`; `windowManager.focus()`.
- **Algorithm:** Sequential calls, no branching.
- **Usage:** Called from `onTrayIconMouseDown` and the tray menu's `'show'` case.
- **Notes:** None.

### `static void _setDockIconVisible(bool visible)` <a id="_setdockiconvisible"></a>
- **Kind:** private static method of `TrayService`
- **Source:** `lib/shared/services/tray_service.dart` (line 215)
- **Purpose:** Show or hide the macOS Dock icon via a native platform channel.
- **Inputs:** `visible`.
- **Returns:** None.
- **Side effects:** Invokes `MethodChannel('com.yuanzhe.my_day/dock').invokeMethod(
  'setDockIconVisible', {'visible': visible})` — only on macOS.
- **Algorithm:** Return immediately if not `Platform.isMacOS`; otherwise invoke the platform
  channel method.
- **Usage:** Called from `_showWindow()` (`true`) and from `onWindowClose`/`onWindowMinimize`
  (`false`).
- **Notes:** No-op on Windows/Linux — the platform channel is macOS-specific (native Dock icon
  toggling has no equivalent on the other desktop platforms).
