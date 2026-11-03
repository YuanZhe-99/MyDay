# lib/features/settings/widgets/home_widget_preview.dart

The live preview of one home-screen widget kind on
[`HomeWidgetSettingsPage`](../views/home_widget_settings_page.md) (1.8.3). It draws the 2×2 widget
from the same payload the native widget receives (built by
[`HomeWidgetService.payloadBuilders`](../../../shared/services/home_widget_service.md#payloadbuilders)),
with text sizes multiplied by the kind's text scale and its privacy choice applied, inside the
shared `WidgetPreviewSurface` from `myapps_widget_ui`. It approximates the native widgets in the
app's colors; it is not a pixel copy of either platform. See
[Home-Screen Widgets](../../../../features/home-screen-widgets.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `HomeWidgetPreview` (constructor) | const constructor (`HomeWidgetPreview`) | B | Create a preview from a kind, its unmasked payload and its settings. |
| [`build`](#build) | method (`HomeWidgetPreview`) | A | Build the preview card, centered and scaled. |
| `_todo` | method (`HomeWidgetPreview`) | B | Draw the Todo widget from today's day entry. |
| `_weight` | method (`HomeWidgetPreview`) | B | Draw the Weight widget with its sparkline. |
| `_finance` | method (`HomeWidgetPreview`) | B | Draw the Finance widget with the first bill or the "no bills" line. |
| `_intimacy` | method (`HomeWidgetPreview`) | B | Draw the Private widget; days counted by local calendar day. |
| `_timer` | method (`HomeWidgetPreview`) | B | Draw the Timer widget (static; the native widget counts up). |
| `_header` | method (`HomeWidgetPreview`) | B | Draw a card header: icon, title and an action pill. |
| `_labels` | static method (`HomeWidgetPreview`) | B | Read a payload's labels. |
| `_fill` | static method (`HomeWidgetPreview`) | B | Replace `{n}` and `{m}` in a label. |
| `_signed` | static method (`HomeWidgetPreview`) | B | Format a signed one-decimal change with a real minus sign. |
| `_Text` (constructor) | constructor (`_Text`) | B | Hold the preview's theme, scale and mask flag. |
| `_Text.value` | method (`_Text`) | B | Return a value, or `••••` when values are hidden. |
| `_Text.big` | method (`_Text`) | B | Build a large number. |
| `_Text.body` | method (`_Text`) | B | Build a body line; titles are never masked. |
| `_Text.small` | method (`_Text`) | B | Build a secondary line, masking digits only. |
| `_Placeholder` (constructor) | const constructor (`_Placeholder`) | B | Create the neutral placeholder. |
| `_Placeholder.build` | method (`_Placeholder`) | B | Build an icon over "MyDay". |
| `_SparkPainter` (constructor) | constructor (`_SparkPainter`) | B | Create the sparkline painter from weights and a color. |
| [`paint`](#paint) | method (`_SparkPainter`) | A | Paint the sparkline polyline. |
| `shouldRepaint` | method (`_SparkPainter`) | B | Repaint when the points or color change. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/settings/widgets/home_widget_preview.dart`
reports 21, matching the 21 rows above. Fields and the `displayScale` constant carry plain `///`
comments or none and are not listed.

## Documentation

### `Widget build(BuildContext context)` <a id="build"></a>
- **Kind:** method of `HomeWidgetPreview`
- **Source:** `lib/features/settings/widgets/home_widget_preview.dart` (line 42)
- **Purpose:** Build the preview card.
- **Inputs:** `context`.
- **Returns:** The card, centered and scaled by `displayScale` (0.85).
- **Side effects:** None.
- **Algorithm:** A missing payload or *Icon only* draws `_Placeholder`. Otherwise build a `_Text`
  helper with the theme, text scale and the *Hide values* flag, and dispatch on `kind` to `_todo`,
  `_weight`, `_finance`, `_intimacy` or `_timer`. The content sits in a
  `WidgetPreviewSurface.smallSide` square inside a `FittedBox`.
- **Usage:** One per section of `HomeWidgetSettingsPage.build`.
- **Notes:** The payload is built unmasked; masking happens here, in `_Text`, mirroring the native
  `mask` rule.

### `void paint(Canvas canvas, Size size)` <a id="paint"></a>
- **Kind:** method of `_SparkPainter` (a `CustomPainter`)
- **Source:** `lib/features/settings/widgets/home_widget_preview.dart` (line 512)
- **Purpose:** Paint the sparkline polyline.
- **Inputs:** `canvas`, `size`.
- **Returns:** None.
- **Side effects:** Draws on `canvas`.
- **Algorithm:** Scale the points between their minimum and maximum (a flat series uses a span of
  1) across the full width and height, and stroke the path 2 px wide.
- **Usage:** The Weight preview (`_weight`).
- **Notes:** Fewer than two points draws nothing.
