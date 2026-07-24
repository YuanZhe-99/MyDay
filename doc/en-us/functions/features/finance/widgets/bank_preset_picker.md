# lib/features/finance/widgets/bank_preset_picker.dart

The bank/fintech-preset picker bottom sheet used when adding or editing a Finance
[`Account`](../../../../features/finance.md#model): `showBankPresetPicker` opens a
`DraggableScrollableSheet` that either lists presets grouped into per-country tabs, or shows live
search results, and resolves to the selected `BankPreset` (from
`lib/features/finance/services/bank_preset_service.dart`) or `null` if dismissed. See
[Finance](../../../../features/finance.md#bankpresetservice) for the `BankPresetService` that
supplies the 250+ presets this widget renders.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`showBankPresetPicker`](#showbankpresetpicker) | top-level function | B | Show the bank preset picker as a modal bottom sheet and return the chosen preset. |
| `_BankPickerSheet` (constructor) | constructor (`_BankPickerSheet`) | B | Create a bank picker sheet instance. |
| `createState` | method (`_BankPickerSheet`) | B | Create the mutable `_BankPickerSheetState`. |
| `initState` | method (`_BankPickerSheetState`) | B | Kick off the initial grouped-presets load. |
| `_load` | method (`_BankPickerSheetState`) | B | Load and group all bank presets by country. |
| `_onSearch` | method (`_BankPickerSheetState`) | B | Run a live preset search as the user types, or clear search mode when empty. |
| `dispose` | method (`_BankPickerSheetState`) | B | Dispose the search text controller. |
| `build` | method (`_BankPickerSheetState`) | B | Render the handle, title, search field, and either the country tabs or search results. |
| `_BankTile` (constructor) | constructor (`_BankTile`) | B | Create a bank tile instance for one preset. |
| `build` | method (`_BankTile`) | B | Render one bank/fintech row with logo, titles, and accent-color dot. |
| [`_parseColor`](#parsecolor) | static method (`_BankTile`) | A | Parse a bank preset's hex color string into a `Color`, defaulting to grey on failure. |

`grep -c 'Purpose:' lib/features/finance/widgets/bank_preset_picker.dart` reports 11, matching all
eleven real declarations in this file. No misattachment or undocumented declarations found.

## Documentation

### `static Color _parseColor(String hex)` <a id="parsecolor"></a>
- **Kind:** static method of `_BankTile`
- **Source:** `lib/features/finance/widgets/bank_preset_picker.dart` (line 311)
- **Purpose:** Convert a `BankPreset.color` hex string (e.g. `'#4285F4'`, defaulted to `'#888888'`
  by `BankPresetService` when a preset has no color) into a Flutter `Color`, falling back to grey
  for any string that fails to parse.
- **Inputs:** `hex` — a color string, expected as `'#RRGGBB'` (6 hex digits) or already-prefixed
  `'#AARRGGBB'` (8 hex digits); the leading `#` is optional.
- **Returns:** `Color` — the parsed color, or `Colors.grey` if parsing throws.
- **Side effects:** None.
- **Algorithm:**
  1. If `hex` (including its leading `#`, before stripping) is exactly 7 characters long — i.e. the
     `'#RRGGBB'` form — prepend `'ff'` to a buffer so the color is fully opaque.
  2. Strip any leading `#` from `hex` and append the remainder to the buffer.
  3. Parse the buffer's string as a base-16 integer and construct `Color(...)` from it.
  4. Catch any exception (malformed hex, wrong digit count, etc.) and return `Colors.grey` instead
     of letting the error propagate.
- **Usage:**
  ```dart
  final color = _parseColor(bank.color);
  return ListTile(
    leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), ...),
    // ...
    trailing: Container(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
  ```
  (`_BankTile.build`, same file — the parsed color tints both the leading avatar and the trailing
  accent dot.)
- **Notes:** The `'#RRGGBB'`-vs-already-has-alpha check is done on the *unstripped* string length
  (7, counting the `#`), so it correctly recognizes every `BankPreset.color` value produced by
  `BankPresetService` (always `'#RRGGBB'`, e.g. the `'#888888'` default). It is not fully robust to
  other shapes, though: a 6-digit string with no leading `#` also has length 6 (not 7), so it would
  skip the `'ff'` prepend and get parsed as a bare 24-bit value — `Color(...)` would then read the
  top byte (meant to be alpha) as `0x00`, producing a fully transparent color instead of throwing,
  so the `try`/`catch` would not catch it. This edge case does not occur in practice because every
  color this function is called with already carries a leading `#`.
