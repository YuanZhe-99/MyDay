# MyDay!!!!! Documentation

MyDay!!!!! is a privacy-first Flutter daily life companion covering Todo management, personal
finance (including subscriptions and multi-currency exchange rates), an optional intimacy module
(including cycle tracking and body metrics), and weight tracking. It syncs data across devices over
user-controlled WebDAV, keeps local backups, supports ZIP import/export, and offers desktop tray
behavior, launch-at-startup, and a local HTTP API.

- **Dart package:** `my_day`
- **License:** GPL-3.0
- **Primary platforms:** Windows (x64/ARM64), Android (APK/AAB), iOS (sideload IPA), macOS (DMG).
  A Linux project exists for desktop runtime features but is not a primary release artifact.
- **Framework:** Flutter, Dart SDK `^3.11.3`

This tree (`doc/en-us/`) is the English "concept" documentation: how the app is put together, what
its data formats and algorithms look like, and how its features behave. It is separate from the
per-source-file function index under [`functions/`](functions/) (declaration-by-declaration
reference) and from any future `doc/zh-cn/` translation.

## Contents

### Core concepts

- [Architecture](architecture.md) — app shell/startup, state management, navigation, theming,
  localization, repository layout, and core storage/concurrency rules.
- [Data Formats](data-formats.md) — every persisted model's fields, `storage_config.json`, and the
  full Persisted Data Inventory.
- [WebDAV Sync](sync.md) — the 10-step per-record three-way sync flow, retry/heartbeat/lock
  behavior, the Sync Data Reference table, and auto-sync triggers.
- [Backup & Restore](backup-restore.md) — backup format v2, blob garbage collection, restore
  validation and safety, and ZIP-only import/export.
- [Platform Notes](platform-notes.md) — Android/iOS/macOS/Windows caveats, the local HTTP API,
  tray behavior, and startup launch.

### Features

- [Todo](features/todo.md)
- [Finance](features/finance.md)
- [Intimacy](features/intimacy.md)
- [Weight](features/weight.md)
- [Settings](features/settings.md)

### Algorithms (deep dives)

- [Three-Way Merge](algorithms/three-way-merge.md) — the generic `mergeRecords` engine and each
  data file's merge strategy.
- [Subscription Billing](algorithms/subscription-billing.md) — month-end clamping and idempotent
  billing-day generation.
- [Body Metrics](algorithms/body-metrics.md) — bra-size estimation across six regional standards,
  the PSI formula, and median-based cycle prediction.

### Worked examples

- [Sync Walkthrough](examples/sync-walkthrough.md) — two devices, a cross-module conflict, and the
  mixed-resolutions-map safety rule.
- [Subscription Billing Walkthrough](examples/subscription-billing-walkthrough.md) — a Jan-31
  monthly subscription advancing through Feb/Mar/Apr with concrete dates.

## Sourcing

Everything in this tree is derived from the repository's own `AGENTS.md` (the maintained
architecture/behavior guide) cross-checked against the current Dart source under `lib/`. Where this
documentation and the source disagree, the source wins — see each page for the specific files it
was checked against.
