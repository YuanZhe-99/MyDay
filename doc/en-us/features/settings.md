# Settings

Source: `lib/features/settings/views/settings_page.dart`, `privacy_policy_page.dart`,
`license_page.dart`. Primary source for the section list: the "Settings" subsection of `AGENTS.md`.

`settings_page.dart` provides:

- **Profile** (1.6.0): the first item, above General — the user's avatar and name; tapping it opens the edit dialog (see [Profile](profile.md)).
- **General**: language, global week start day for app calendars and weekly grouping, theme, and the **interface style** (1.6.0) — Material 3 or Expressive (default); Expressive also floats the bottom navigation bar. Device-local, never synced.
- **Privacy**: Intimacy module toggle with a hide confirmation (see
  [Intimacy](intimacy.md#hidden-by-default) — hiding never deletes data).
- **On-device AI** (1.5.0): on Android, iOS and macOS, `AiSettingsTiles` — the *Use on-device AI*
  switch (off by default), then, while it is on, the model status with *Download* (Android) or
  *Check again*, *Use the faster model* when both sizes are served, notes, *Technical details*, and
  *Clear generated insights*. On Windows and Linux a single "not available on this platform" line.
  See [On-device AI](../on-device-ai.md).
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
