# lib/features/settings/views/license_page.dart

The MyApps-AI notice includes myapps_ai_ui.

The notice includes MyApps-UI, all three consumed packages, source and GPL v3 URLs.

A single static page showing MyDay's GPLv3 license notice as selectable text. It has no state, no
services, and no external collaborators beyond localization — it exists purely so the About section
in [Settings](../../../../features/settings.md) has a dedicated GPL license screen, distinct from the
auto-generated open-source-licenses page (`showLicensePage`, wired from `settings_page.dart`) and
from [`privacy_policy_page.dart`](privacy_policy_page.md). Since 1.5.0 the text ends with a
"Third-party components" notice for the OpenCC-derived Chinese conversion tables
(`lib/shared/utils/chinese_convert_data.dart`, Apache-2.0), used by the on-device AI cards.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `LicensePage({super.key})` | constructor (`LicensePage`) | B | Create a license page instance. |
| `build` | method (`LicensePage`) | B | Build the scrollable, selectable license text view. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/settings/views/license_page.dart` returns 2.
Both blocks document real declarations (the constructor and `build`) — no misattached blocks and no
undocumented declarations. The `_licenseText` static string field has no `Purpose:` block, consistent
with it being data, not a function.

## Documentation

Both declarations are Tier B (a simple forwarding constructor and a `build` method that only lays out
a title bar and a block of selectable static text) — see the table above for their one-line purpose;
this file has no Tier A entries.

## Related pages

- [Settings](../../../../features/settings.md) — the About section that links to this page.

## Navigation-bar padding (1.6.1)

With the Expressive bottom bar floating over the page (see [../../../../adaptive-layout.md](../../../../adaptive-layout.md)), the `SingleChildScrollView` passes its explicit padding through `navBarAwarePadding(context, ...)` so the last content can scroll above the bar. The page's main lists have no explicit padding, so Flutter applies the bar's inset to them itself.

Includes llama.cpp MIT attribution and Apache-2.0 model provenance for explicitly downloaded Qwen3.5/Gemma 4 artifacts.
