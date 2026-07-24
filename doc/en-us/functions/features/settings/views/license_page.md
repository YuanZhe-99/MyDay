# lib/features/settings/views/license_page.dart

A single static page showing MyDay's GPLv3 license notice as selectable text. It has no state, no
services, and no external collaborators beyond localization — it exists purely so the About section
in [Settings](../../../../features/settings.md) has a dedicated GPL license screen, distinct from the
auto-generated open-source-licenses page (`showLicensePage`, wired from `settings_page.dart`) and
from [`privacy_policy_page.dart`](privacy_policy_page.md).

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
