# lib/shared/utils/status_colors.dart

`StatusColors` (1.6.0) is an `abstract final class` of static color helpers for the two money flows
that carry a meaning of their own: income (positive) and expense (negative). Green and red are kept
for recognisability, but they are derived from the active `ColorScheme`, following Material 3's
custom-color guidance, so they sit in the same tonal family as the rest of the UI in light, dark and
dynamic color. The Finance pages use them for amounts, balances, summary cards and the trend chart
(`finance_page.dart`, `accounts_page.dart`, `analysis_page.dart`, `category_detail_page.dart`). See
[`../../app/theme.md`](../../app/theme.md) for the scheme itself.

Fixed, deliberately theme-independent colors stay as they were: categorical chart palettes, account
type colors, the intimacy cycle-person palette, the BMI and waist-hip scale bars, and white text over
images or snack bars.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `StatusColors` | abstract final class | B | Namespace for the status colors; never instantiated. |
| [`StatusColors.income`](#income) | static method | A | The color for income and positive balances. |
| [`StatusColors.expense`](#expense) | static method | A | The color for expenses and negative amounts. |

## income

- **Inputs:** `scheme` — the color scheme the color will be drawn on.
- **Returns:** `Color` — `Colors.green.harmonizeWith(scheme.primary)` (the `dynamic_color` extension).
- **Notes:** Harmonization only shifts the hue slightly toward the primary color, so it still reads
  as green next to the expense red.

## expense

- **Inputs:** `scheme`.
- **Returns:** `Color` — `scheme.error`.
- **Notes:** The scheme's error role is already a tuned red for its brightness.
