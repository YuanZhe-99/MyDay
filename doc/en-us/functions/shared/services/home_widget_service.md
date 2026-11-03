# lib/shared/services/home_widget_service.dart

The app side of the Android and iOS home-screen widgets (1.8.3). `HomeWidgetService` is a static
facade over the shared MyApps-Widget bridge (`packages/myapps_widget`): it publishes one envelope
per widget kind (`myday.todo`, `myday.weight`, `myday.finance`, `myday.intimacy`, `myday.timer`)
with a payload built by [`HomeWidgetPayloads`](home_widget_payloads.md), and applies the taps the
widget controls queue through [`HomeWidgetActions`](home_widget_actions.md). The same file holds
the per-kind settings model (`HomeWidgetKindSettings`, stored under `homeWidgets` in
`storage_config.json`) and `HomeWidgetLaunch`, which turns widget deep links into tab locations for
the router. Every entry point is a no-op off Android and iOS. See
[Home-Screen Widgets](../../../features/home-screen-widgets.md) for the feature, its data flow and
the snapshot formats, and [Data Formats](../../../data-formats.md#storage_configjson) for the
`homeWidgets` key.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `HomeWidgetPrivacyChoice` | enum | B | How one widget kind shows its values: `show`, `maskValues`, `iconOnly`. |
| `HomeWidgetPrivacyChoice.fromName` | static method (`HomeWidgetPrivacyChoice`) | B | Read a stored choice; null when unknown. |
| `HomeWidgetKindSettings` (constructor) | const constructor (`HomeWidgetKindSettings`) | B | Hold one kind's text scale and privacy choice. |
| `HomeWidgetKindSettings.copyWith` | method (`HomeWidgetKindSettings`) | B | Return a copy with selected fields replaced, clamping the text scale. |
| `HomeWidgetKindSettings.toJson` | method (`HomeWidgetKindSettings`) | B | Serialize for `storage_config.json`. |
| `HomeWidgetLaunchRequest` (constructor) | const constructor (`HomeWidgetLaunchRequest`) | B | Hold one widget tap waiting for its destination page. |
| [`isWidgetLink`](#iswidgetlink) | static method (`HomeWidgetLaunch`) | A | Tell whether a location is a home-screen widget link. |
| [`redirect`](#redirect) | static method (`HomeWidgetLaunch`) | A | Turn a widget deep link into a tab location and record its action. |
| [`take`](#take) | static method (`HomeWidgetLaunch`) | A | Consume the pending request if it belongs to one of the given kinds. |
| `HomeWidgetService._()` | constructor (`HomeWidgetService`) | B | Prevent direct instantiation; expose only static members. |
| Kind and platform constants | static constants (`HomeWidgetService`) | B | `todoKind` … `timerKind`, `kinds`, `appGroupId`, `formatVersion`, `configKey`, `androidProviders`, `iosKinds`. |
| `bridge` | static field (`HomeWidgetService`) | B | The shared `MyAppsWidgetBridge` describing every MyDay kind. |
| `isSupported` | static getter (`HomeWidgetService`) | B | Whether this platform has home-screen widgets (Android and iOS). |
| [`tabFor`](#tabfor) | static method (`HomeWidgetService`) | A | Return the tab path a kind opens. |
| [`defaultSettings`](#defaultsettings) | static method (`HomeWidgetService`) | A | Return the default settings of a kind. |
| [`loadSettings`](#loadsettings) | static method (`HomeWidgetService`) | A | Read every kind's settings, defaults filled in. |
| [`_parseSettings`](#_parsesettings) | static method (`HomeWidgetService`) | A | Parse one kind's stored settings tolerantly. |
| [`saveSettings`](#savesettings) | static method (`HomeWidgetService`) | A | Store one kind's settings and refresh the widgets. |
| [`init`](#init) | static method (`HomeWidgetService`) | A | Start feeding the widgets. |
| [`notifyDataChanged`](#notifydatachanged) | static method (`HomeWidgetService`) | A | Schedule a debounced refresh after data or settings change. |
| [`drainActions`](#drainactions) | static method (`HomeWidgetService`) | A | Apply the actions queued by widget controls, one pass at a time. |
| [`_drain`](#_drain) | static method (`HomeWidgetService`) | A | Run one drain pass. |
| [`refresh`](#refresh) | static method (`HomeWidgetService`) | A | Rebuild every kind's envelope and redraw the widgets. |
| [`payloadBuilders`](#payloadbuilders) | static method (`HomeWidgetService`) | A | Prepare one payload builder per kind. |
| [`envelopePrivacy`](#envelopeprivacy) | static method (`HomeWidgetService`) | A | Map a privacy choice to the envelope's privacy level. |
| [`_l10n`](#_l10n) | static method (`HomeWidgetService`) | A | Resolve localizations and the intl locale tag. |
| [`didChangeAppLifecycleState`](#didchangeapplifecyclestate) | method (`_LifecycleObserver`) | A | On resume, drain widget actions and schedule a refresh. |

**Reconciliation:** `grep -c 'Purpose:' lib/shared/services/home_widget_service.dart` reports 24,
against 27 rows above. The three extra rows are real declarations with no `Purpose:` block: the
`HomeWidgetPrivacyChoice` enum, the grouped row for the `HomeWidgetService` kind and platform
constants (one row covering a family of related constants, as on `data_modules.md`), and the
`bridge` field, which is the facade's handle on the shared package. Other fields
(`HomeWidgetLaunch.pending`, `timerActionHandler`, `_scheduler`, `_applied`, `_draining`,
`_observer`) carry plain `///` comments only and are treated as data, not declarations.

## Documentation

### `static bool isWidgetLink(Uri uri)` <a id="iswidgetlink"></a>
- **Kind:** static method of `HomeWidgetLaunch`
- **Source:** `lib/shared/services/home_widget_service.dart` (line 114)
- **Purpose:** Tell whether a location is a home-screen widget link.
- **Inputs:** `uri` — the location go_router is asked to open.
- **Returns:** `true` when the path is exactly one segment and that segment is a MyDay widget kind
  (`tabFor` returns a path).
- **Side effects:** None.
- **Algorithm:** `uri.pathSegments.length == 1 && HomeWidgetService.tabFor(segment) != null`.
- **Usage:** The top-level `redirect` of [`appRouter`](../../app/router.md#approuter) calls it first,
  so only widget links pay for the asynchronous Intimacy-visibility read.
- **Notes:** Ordinary routes (`/todo`, `/settings`, …) are never widget links, because their
  segment is not a `myday.*` kind.

### `static String? redirect(Uri uri, {required bool intimacyVisible})` <a id="redirect"></a>
- **Kind:** static method of `HomeWidgetLaunch`
- **Source:** `lib/shared/services/home_widget_service.dart` (line 125)
- **Purpose:** Turn a widget deep link into a tab location.
- **Inputs:** `uri`; `intimacyVisible` — whether the Intimacy module is shown.
- **Returns:** The tab path to redirect to, or null when `uri` is no widget link.
- **Side effects:** Sets `pending` to a `HomeWidgetLaunchRequest` when the link carries a `do`
  action.
- **Algorithm:**
  1. Return null unless the path is one segment that `tabFor` maps to a tab.
  2. For `myday.intimacy` and `myday.timer` while the module is hidden, return `/todo` without
     recording an action.
  3. If the query has `do`, store `HomeWidgetLaunchRequest(kind, action: do, id: id)` in `pending`.
  4. Return the tab path.
- **Usage:** `appRouter`'s `redirect`, after reading `TodoStorage.getIntimacyVisible()`.
- **Notes:** Accepts both the Android route form `/myday.todo?do=add` and the iOS URL
  `myday://widget/myday.todo?do=add`; both have one path segment. See
  [Deep links](../../../features/home-screen-widgets.md#deep-links).

### `static HomeWidgetLaunchRequest? take(Set<String> kinds)` <a id="take"></a>
- **Kind:** static method of `HomeWidgetLaunch`
- **Source:** `lib/shared/services/home_widget_service.dart` (line 151)
- **Purpose:** Consume the pending request if it belongs to one of `kinds`.
- **Inputs:** `kinds` — the widget kinds the calling page handles.
- **Returns:** The request, or null when none is pending or it belongs to another page.
- **Side effects:** Clears `pending` when it matches.
- **Algorithm:** Read `pending.value`; return null if it is null or its kind is not in `kinds`;
  otherwise set `pending.value = null` and return it.
- **Usage:** The `_onWidgetLaunch` helpers of the Todo, Weight, Finance and Intimacy pages, both
  once their data has loaded and from a `pending` listener.
- **Notes:** A request for another tab stays pending until that tab's page takes it.

### `static String? tabFor(String kind)` <a id="tabfor"></a>
- **Kind:** static method of `HomeWidgetService`
- **Source:** `lib/shared/services/home_widget_service.dart` (line 272)
- **Purpose:** Return the tab path a kind opens.
- **Inputs:** `kind`.
- **Returns:** `/todo`, `/weight`, `/finance`, `/intimacy` (for both `myday.intimacy` and
  `myday.timer`), or null for an unknown kind.
- **Side effects:** None.
- **Algorithm:** A `switch` over the five kind constants.
- **Usage:** `HomeWidgetLaunch.isWidgetLink` and `HomeWidgetLaunch.redirect`.
- **Notes:** None.

### `static HomeWidgetKindSettings defaultSettings(String kind)` <a id="defaultsettings"></a>
- **Kind:** static method of `HomeWidgetService`
- **Source:** `lib/shared/services/home_widget_service.dart` (line 285)
- **Purpose:** Return the default settings of a kind.
- **Inputs:** `kind`.
- **Returns:** Text scale 100% with *Hide values* (`maskValues`) for `myday.intimacy` and *Show* for
  every other kind.
- **Side effects:** None.
- **Algorithm:** One conditional on `kind == intimacyKind`.
- **Usage:** `_parseSettings` fallback.
- **Notes:** The Private widget hides its values until the user chooses otherwise.

### `static Future<Map<String, HomeWidgetKindSettings>> loadSettings()` <a id="loadsettings"></a>
- **Kind:** static method of `HomeWidgetService`
- **Source:** `lib/shared/services/home_widget_service.dart` (line 297)
- **Purpose:** Read every kind's settings.
- **Inputs:** None.
- **Returns:** One `HomeWidgetKindSettings` per entry of `kinds`, defaults filled in.
- **Side effects:** Reads `storage_config.json` through `TodoStorage.readConfig()`.
- **Algorithm:** Read the `homeWidgets` value, then `_parseSettings(kind, raw)` for each kind.
- **Usage:** `refresh` and `HomeWidgetSettingsPage._load`.
- **Notes:** Malformed entries fall back to the defaults; the read itself is lenient.

### `static HomeWidgetKindSettings _parseSettings(String kind, Object? raw)` <a id="_parsesettings"></a>
- **Kind:** private static method of `HomeWidgetService`
- **Source:** `lib/shared/services/home_widget_service.dart` (line 307)
- **Purpose:** Parse one kind's stored settings.
- **Inputs:** `kind`; `raw` — the stored `homeWidgets` value, of any JSON shape.
- **Returns:** `HomeWidgetKindSettings`.
- **Side effects:** None.
- **Algorithm:** If `raw` is not a map or its `kind` entry is not a map, return the defaults.
  Otherwise take a numeric `textScale` clamped by `WidgetTextScale.clamp`, and `privacy` through
  `HomeWidgetPrivacyChoice.fromName`, each falling back to the default.
- **Usage:** `loadSettings`.
- **Notes:** Never throws on unexpected input.

### `static Future<void> saveSettings(String kind, HomeWidgetKindSettings settings)` <a id="savesettings"></a>
- **Kind:** static method of `HomeWidgetService`
- **Source:** `lib/shared/services/home_widget_service.dart` (line 328)
- **Purpose:** Store one kind's settings and refresh the widgets.
- **Inputs:** `kind`, `settings`.
- **Returns:** Completes when stored.
- **Side effects:** Merge-writes `homeWidgets` in `storage_config.json` and calls
  `notifyDataChanged`.
- **Algorithm:** Read the current `homeWidgets` map (or start empty), replace the `kind` entry with
  `settings.toJson()`, and write it back with the single-key patch
  `TodoStorage.writeConfig({configKey: all})`.
- **Usage:** `HomeWidgetSettingsPage._update`.
- **Notes:** Device-local; never synced, backed up or exported.

### `static Future<void> init()` <a id="init"></a>
- **Kind:** static method of `HomeWidgetService`
- **Source:** `lib/shared/services/home_widget_service.dart` (line 347)
- **Purpose:** Start feeding the widgets.
- **Inputs:** None.
- **Returns:** Completes after the first drain; the first refresh runs unawaited.
- **Side effects:** Subscribes `notifyDataChanged` to `AutoSyncService.addOnLocalDataChanged`,
  sets the bridge's actions-queued listener to `drainActions`, registers a `_LifecycleObserver`,
  drains the queue and refreshes every kind.
- **Algorithm:** Return immediately when `!isSupported`; otherwise wire the three subscriptions,
  `await drainActions()`, then `unawaited(refresh())`.
- **Usage:** Called once, unawaited, from [`main()`](../../main.md#main).
- **Notes:** The observer is created once (`??=`).

### `static void notifyDataChanged()` <a id="notifydatachanged"></a>
- **Kind:** static method of `HomeWidgetService`
- **Source:** `lib/shared/services/home_widget_service.dart` (line 363)
- **Purpose:** Schedule a debounced refresh after data or settings change.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Restarts the 2-second `WidgetRefreshScheduler` timer, which then calls
  `refresh`.
- **Algorithm:** No-op when unsupported; otherwise `_scheduler.schedule()`.
- **Usage:** The `_saveNow` of `TodoStorage`, `WeightStorage`, `FinanceStorage` and
  `IntimacyStorage`; sync and restore reloads (through `init`'s subscription); app resume;
  `AppSettingsNotifier.setLocale`; `IntimacyVisibilityNotifier.setVisible`; `saveSettings`.
- **Notes:** A burst of saves produces one refresh.

### `static Future<void> drainActions()` <a id="drainactions"></a>
- **Kind:** static method of `HomeWidgetService`
- **Source:** `lib/shared/services/home_widget_service.dart` (line 376)
- **Purpose:** Apply the actions queued by widget controls.
- **Inputs:** None.
- **Returns:** Completes when the actions are applied, published and acknowledged.
- **Side effects:** See `_drain`.
- **Algorithm:** No-op when unsupported; otherwise return the running pass, or start `_drain()` and
  clear `_draining` when it completes.
- **Usage:** `init`, the bridge's actions-queued listener, and `_LifecycleObserver` on resume.
- **Notes:** Concurrent calls share one pass. A failure leaves the actions queued for the next drain.

### `static Future<void> _drain()` <a id="_drain"></a>
- **Kind:** private static method of `HomeWidgetService`
- **Source:** `lib/shared/services/home_widget_service.dart` (line 386)
- **Purpose:** Run one drain pass.
- **Inputs:** None.
- **Returns:** Completes when done.
- **Side effects:** May write `todo_data.json` and `intimacy_data.json`; calls
  `AutoSyncService.notifySaved()` and `notifyLocalDataChangedNow()` after a write; publishes every
  envelope; acknowledges the consumed actions in the native queue.
- **Algorithm:**
  1. Read `bridge.pendingActions()`; stop if empty. Split them into Todo, Timer and other actions.
  2. Todo: load `TodoStorage`, apply `HomeWidgetActions.applyTodo`, save if changed; remember the
     ids in `_applied`.
  3. Timer: if the timer page registered `timerActionHandler`, hand the actions to it; otherwise
     load `IntimacyStorage`, apply `HomeWidgetActions.applyTimer` to the stored session, and save
     `data.withTimerSession(...)` with a fresh UTC `modifiedAt` if changed. Remember the ids.
  4. After a write, notify auto-sync and the open pages.
  5. `await refresh()`, then acknowledge the Todo, Timer and other action ids.
- **Usage:** Only through `drainActions`.
- **Notes:** Errors are logged and swallowed; nothing is acknowledged after a failure, so the
  actions are retried. Actions of other kinds are acknowledged without effect.

### `static Future<void> refresh()` <a id="refresh"></a>
- **Kind:** static method of `HomeWidgetService`
- **Source:** `lib/shared/services/home_widget_service.dart` (line 454)
- **Purpose:** Rebuild every kind's envelope and redraw the widgets.
- **Inputs:** None.
- **Returns:** Completes when published.
- **Side effects:** Reads the data files and `storage_config.json`; writes the native widget store;
  clears the Private and Timer envelopes while the Intimacy module is hidden.
- **Algorithm:**
  1. Load the settings and `payloadBuilders(now)`.
  2. For each kind, build the payload with `mask` set for *Hide values*; `bridge.clear(kind)` when
     the builder returns null, otherwise publish `bridge.envelope(kind, payload, generatedAt: now,
     textScale, privacy: envelopePrivacy(...))`.
  3. Trim each `_applied` list to `HomeWidgetPayloads.maxAppliedActions`.
- **Usage:** The refresh scheduler, `init` and `_drain`.
- **Notes:** Each kind fails independently and failures are logged, since a stale widget is
  harmless.

### `static Future<Map<String, Future<Map<String, dynamic>?> Function(bool mask)>> payloadBuilders(DateTime now)` <a id="payloadbuilders"></a>
- **Kind:** static method of `HomeWidgetService`
- **Source:** `lib/shared/services/home_widget_service.dart` (line 497)
- **Purpose:** Prepare one payload builder per kind.
- **Inputs:** `now` — the instant the payloads describe.
- **Returns:** Builders keyed by kind; each takes the `mask` flag and returns the payload, or null
  for the Private and Timer kinds while the Intimacy module is hidden.
- **Side effects:** Reads `storage_config.json` and initializes intl date symbols for the app
  language; each builder reads its own data file when called.
- **Algorithm:** Resolve `_l10n()`, call `initializeDateFormatting(localeTag)` (errors ignored),
  read the Intimacy visibility, and return closures over the matching `HomeWidgetPayloads`
  builder: `todo` and `timer` also receive their `_applied` ids, `finance` also loads
  `ExchangeRateStorage`.
- **Usage:** `refresh` and the settings-page previews (`HomeWidgetSettingsPage._load`).
- **Notes:** The previews call each builder with `mask: false`; the preview widget applies the mask
  itself.

### `static WidgetPrivacy envelopePrivacy(String kind, HomeWidgetPrivacyChoice choice)` <a id="envelopeprivacy"></a>
- **Kind:** static method of `HomeWidgetService`
- **Source:** `lib/shared/services/home_widget_service.dart` (line 551)
- **Purpose:** Map a privacy choice to the envelope's privacy level.
- **Inputs:** `kind`, `choice`.
- **Returns:** *Show* → the kind's default level (`normal` for Todo, `sensitive` for the others);
  *Hide values* → `sensitive`; *Icon only* → `hidden`.
- **Side effects:** None.
- **Algorithm:** A `switch` on `choice`.
- **Usage:** `refresh`.
- **Notes:** `sensitive` lets iOS redact the widget while the device is locked.

### `static Future<(AppLocalizations, String)> _l10n()` <a id="_l10n"></a>
- **Kind:** private static method of `HomeWidgetService`
- **Source:** `lib/shared/services/home_widget_service.dart` (line 565)
- **Purpose:** Resolve localizations and the intl locale tag.
- **Inputs:** None.
- **Returns:** The localizations and a tag such as `en`, `zh` or `zh_TW`.
- **Side effects:** Reads `storage_config.json` (`TodoStorage.getLocaleTag()`).
- **Algorithm:** Use the stored locale tag, else the platform locale; `lookupAppLocalizations`;
  append `_TW` for Traditional Chinese (country `TW` or script `Hant`).
- **Usage:** `payloadBuilders`.
- **Notes:** Same resolution as the settings provider; any failure falls back to English.

### `void didChangeAppLifecycleState(AppLifecycleState state)` <a id="didchangeapplifecyclestate"></a>
- **Kind:** method of `_LifecycleObserver` (a `WidgetsBindingObserver`)
- **Source:** `lib/shared/services/home_widget_service.dart` (line 594)
- **Purpose:** React to app lifecycle changes.
- **Inputs:** `state`.
- **Returns:** None.
- **Side effects:** On `resumed`, starts `drainActions()` and calls `notifyDataChanged()`.
- **Algorithm:** Ignore every state except `resumed`.
- **Usage:** Registered once by `init`.
- **Notes:** Covers taps made while the app was suspended.
