# Settings

Source: `lib/features/settings/views/settings_page.dart`, `privacy_policy_page.dart`,
`license_page.dart`. Primary source for the section list: the "Settings" subsection of `AGENTS.md`.

`settings_page.dart` provides:

- **General**: language, global week start day for app calendars and weekly grouping, and theme.
- **Privacy**: Intimacy module toggle with a hide confirmation (see
  [Intimacy](intimacy.md#hidden-by-default) — hiding never deletes data).
- **Desktop**: minimize-to-tray, close-to-tray, launch at startup, local API enable/status/settings,
  custom storage location, open data folder (see [Platform Notes](../platform-notes.md) for the
  local API and tray/startup mechanics behind these toggles).
- **Data**: WebDAV sync, import/export, backup (see [WebDAV Sync](../sync.md) and
  [Backup & Restore](../backup-restore.md)).
- **About**: app title, version from `package_info_plus`, GPL license, open source licenses, privacy
  policy.
- **Debug**: subscription processor date override in debug builds (used to exercise
  [Subscription Billing](../algorithms/subscription-billing.md) catch-up logic without waiting for
  real time to pass).

`privacy_policy_page.dart` contains the in-app privacy policy in all supported languages and should
match `PRIVACY_POLICY.md` at the repo root. `license_page.dart` displays GPLv3 license information.

## Related pages

- [Architecture](../architecture.md) — localization languages and the theme system these settings
  control.
- [Platform Notes](../platform-notes.md) — desktop-only settings (tray, startup, local API).
- [WebDAV Sync](../sync.md) and [Backup & Restore](../backup-restore.md) — the Data section's
  underlying behavior.
