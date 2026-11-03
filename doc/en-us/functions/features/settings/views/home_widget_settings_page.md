# lib/features/settings/views/home_widget_settings_page.dart

Settings › Home-screen widgets (1.8.3), reached from the widgets row of
[`SettingsPage`](settings_page.md) on Android and iOS. One section per widget kind holds the
kind's text size (`WidgetTextScaleControl` from `myapps_widget_ui`), its privacy choice (*Show*,
*Hide values*, *Icon only*) and a live [`HomeWidgetPreview`](../widgets/home_widget_preview.md)
drawn from the real data. The Private and Timer sections appear only while the Intimacy module is
visible. Settings are stored through
[`HomeWidgetService.saveSettings`](../../../shared/services/home_widget_service.md#savesettings).
See [Home-Screen Widgets](../../../../features/home-screen-widgets.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `HomeWidgetSettingsPage` (constructor) | const constructor (`HomeWidgetSettingsPage`) | B | Create the widget settings page. |
| `createState` | method (`HomeWidgetSettingsPage`) | B | Create the mutable state object. |
| `initState` | method (`_HomeWidgetSettingsPageState`) | B | Start loading the settings and the preview payloads. |
| [`_load`](#_load) | method (`_HomeWidgetSettingsPageState`) | A | Read the settings and build one unmasked payload per kind. |
| [`_update`](#_update) | method (`_HomeWidgetSettingsPageState`) | A | Change one kind's settings. |
| [`build`](#build) | method (`_HomeWidgetSettingsPageState`) | A | Build the page with one section per visible kind. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/settings/views/home_widget_settings_page.dart`
reports 6, matching the 6 rows above.

## Documentation

### `Future<void> _load()` <a id="_load"></a>
- **Kind:** private method of `_HomeWidgetSettingsPageState`
- **Source:** `lib/features/settings/views/home_widget_settings_page.dart` (line 54)
- **Purpose:** Read the settings and build one unmasked payload per kind.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Reads `storage_config.json` and the data files; updates `_settings` and
  `_payloads`.
- **Algorithm:** `HomeWidgetService.loadSettings()` and `payloadBuilders(DateTime.now())`, then
  call every builder with `mask: false`, storing null for a builder that throws.
- **Usage:** `initState`.
- **Notes:** A kind whose data cannot be read previews as the placeholder.

### `void _update(String kind, HomeWidgetKindSettings next)` <a id="_update"></a>
- **Kind:** private method of `_HomeWidgetSettingsPageState`
- **Source:** `lib/features/settings/views/home_widget_settings_page.dart` (line 79)
- **Purpose:** Change one kind's settings.
- **Inputs:** `kind`, `next`.
- **Returns:** None.
- **Side effects:** Updates state; `HomeWidgetService.saveSettings` persists the value and schedules
  a widget refresh.
- **Algorithm:** `setState` first so the preview follows at once, then save (not awaited).
- **Usage:** The text-size control and the privacy segmented row in `build`.
- **Notes:** None.

### `Widget build(BuildContext context)` <a id="build"></a>
- **Kind:** method of `_HomeWidgetSettingsPageState`
- **Source:** `lib/features/settings/views/home_widget_settings_page.dart` (line 91)
- **Purpose:** Build the page.
- **Inputs:** `context`.
- **Returns:** A `Scaffold` with a hint and one `MyAppsSettingsSection` per visible kind.
- **Side effects:** None.
- **Algorithm:** Show a progress indicator until the settings load. Each section has the text-size
  control, the privacy row (with the lock-screen note on every kind but Todo) and the preview. The
  Intimacy kinds are skipped while `intimacyVisibilityProvider` reports the module hidden.
- **Usage:** Pushed full screen on a narrow window and hosted in the Settings detail pane on a wide
  one.
- **Notes:** The page watches the visibility provider, so hiding the module removes the two
  sections at once.
