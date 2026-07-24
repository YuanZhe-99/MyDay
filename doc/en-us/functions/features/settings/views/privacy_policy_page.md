# lib/features/settings/views/privacy_policy_page.dart

A single static page showing MyDay's in-app privacy policy, translated into English, Simplified
Chinese, Traditional Chinese, and Japanese, selected by the active app locale rather than by a
language picker on the page itself. It should match `PRIVACY_POLICY.md` at the repo root per
[Settings](../../../../features/settings.md). Like [`license_page.dart`](license_page.md), it has no
services or external state — the only "logic" is picking which canned string to render.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `PrivacyPolicyPage({super.key})` | constructor (`PrivacyPolicyPage`) | B | Create a privacy policy page instance. |
| `build` | method (`PrivacyPolicyPage`) | B | Build the scrollable, selectable privacy-policy text view. |
| `_getText` | method (`PrivacyPolicyPage`) | B | Pick the privacy-policy text block matching the current locale. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/settings/views/privacy_policy_page.dart` returns
3. All three blocks document real declarations (the constructor, `build`, and `_getText`) — no
misattached blocks and no undocumented declarations. The four static string fields (`_en`, `_zh`,
`_zhTW`, `_ja`) have no `Purpose:` block, consistent with them being data, not functions.

## Documentation

All three declarations are Tier B. `_getText` is a plain locale-to-string dispatcher — like
`_progressText` in [`webdav_config_page.dart`](../../../shared/views/webdav_config_page.md#progresstext)
or `_localizedModuleName` in [`backup_page.dart`](../../../shared/views/backup_page.md#localizedmodulename),
it only selects among a fixed set of precomputed values with no external effects, so it stays Tier B
despite the `if`/`switch` branching: it special-cases `zh`+`TW` (Traditional Chinese) ahead of the
plain `zh` case, then switches on `languageCode` for `zh`/`ja`, defaulting to English otherwise. See
the table above for each declaration's one-line purpose; this file has no Tier A entries.

## Related pages

- [Settings](../../../../features/settings.md) — the About section that links to this page, and the
  note that this text should track `PRIVACY_POLICY.md`.
