# Data Formats

P3 shared profile ownership and adapters: [shared-ui.md](shared-ui.md). Existing formats and module order are retained.

This page documents the field-level shape of every persisted model, `storage_config.json`, and the
full Persisted Data Inventory. Field lists are read directly from the model source files listed
under each section. See [Architecture](architecture.md) for the storage/write-queue/UTC-timestamp
rules that apply to all of these files, and [WebDAV Sync](sync.md) /
[Three-Way Merge](algorithms/three-way-merge.md) for how they merge across devices.

## Todo — `todo_data.json`

Source: `lib/features/todo/models/task.dart`.

- **`TaskType`** enum: `daily`, `routineOnce`, `workOnce`.
- **`RecurrenceType`** enum: `everyNDays`, `monthlyOnDay`, `yearlyOnMonthDay`.
- **`TaskRecurrence`**: `type` (`RecurrenceType`), `intervalDays` (for `everyNDays`), `dayOfMonth`
  (1-31, for `monthlyOnDay`/`yearlyOnMonthDay`), `monthOfYear` (1-12, for `yearlyOnMonthDay`).
  `nextDate(from)` computes the next occurrence, clamping the day-of-month to the target month's
  actual length.
- **`SubTask`**: `id`, `title`, `isCompleted`, `modifiedAt`.
- **`Task`**: `id`, `title`, optional `note`, optional `emoji`, `type` (`TaskType`), `isCompleted`,
  optional `reminderTime`, `subtasks` (`List<SubTask>`), `createdDate`, optional `completedDate`,
  optional `scheduledDate` (one-time tasks only — the date it's scheduled on; null for daily
  templates), optional `deletedDate` (daily templates only — soft-delete date; null means active),
  optional `startDate` (daily templates only — the date the template becomes active, defaults to
  the selected date at creation), optional `dueDate` (one-time tasks only), optional `recurrence`
  (`TaskRecurrence?`, one-time tasks only — prompts for the next occurrence on completion),
  `modifiedAt`.
- **`DailyCompletionLog`**: two internal maps keyed by `yyyy-MM-dd` date strings —
  `_log: Map<String, Set<String>>` (completed task IDs per date) and
  `_subLog: Map<String, Set<String>>` (completed subtask IDs per date). Serializes as
  `{"tasks": {...}, "subtasks": {...}}`; also accepts the legacy flat-map format (a bare
  date→taskIds map with no subtask tracking) on read. `DailyCompletionLog.merge(a, b)` unions the
  completed-ID sets per date from both logs — see
  [Three-Way Merge](algorithms/three-way-merge.md).
- **`DailyScoreEntry`**: `score` (clamped -5..5 via `DailyScoreLog.normalizeScore`), `modifiedAt`.
- **`DailyScoreLog`**: `Map<String, DailyScoreEntry>` keyed by `yyyy-MM-dd`; `minScore = -5`,
  `maxScore = 5`; missing dates read as score `0` but explicit zero entries are retained (so a
  reset-to-zero still syncs). `DailyScoreLog.merge(local, remote)` picks, per date, whichever side's
  entry has the newer `modifiedAt` (ties favor local).

`TodoStorage` also persists in `todo_data.json`: daily templates, one-time tasks, the completion
log, the daily score log, morning/completion reminder hour+minute, task sort modes/custom orders
per section, and `settingsModifiedAt`.

## Finance — `finance_data.json`

Source: `lib/features/finance/models/finance.dart`.

- **`AccountType`** enum: `fund`, `credit`, `recharge`, `financial`.
- **`AccountPickerSettings`**: `sortMode` (`'name'` or `'custom'`), `groupByType`, `customOrder`
  (`List<String>`), `moreAccountIds` (`List<String>`).
- **`Account`**: `id`, `type` (`AccountType`), `bankOrApp`, `name`, `currency` (default `'CNY'`),
  optional `cardNumber`/`expiryDate`/`securityCode`, optional `emoji`/`imagePath`, optional
  `feeWaiverMinimumBalance` and `feeWaiverMonthlyDeposit` (alternative fee-waiver criteria — either
  one being met waives the fee when both are present), legacy `forcedBalance`/`forcedBalanceDate`
  (new-version balances are computed from transactions only; setting a "current balance" in the UI
  creates an income/expense adjustment transaction and then stores the sentinel
  `forcedBalance: 0` + `forcedBalanceDate: 1970-01-01T00:00:00.000Z` purely for old-version
  compatibility — see [Finance](features/finance.md)), `modifiedAt`.
- **`TransactionType`** enum: `expense`, `income`, `transfer`.
- **`Transaction`**: `id`, `type` (`TransactionType`), `amount`, `currency` (default `'CNY'`),
  optional `rateSnapshotId` (references a historical `RateSnapshot` captured at recording time),
  `accountId`, optional `toAccountId`/`toAmount`/`toCurrency` (transfer target account/amount/
  currency for cross-currency transfers), optional `categoryId`, optional `subscriptionId`, `note`
  (default `''`), `date`, `modifiedAt`.
- **`Category`**: `id`, `name`, `icon` (`IconRef`), optional `emoji`, `type` (`TransactionType` —
  transfer categories are supported), `modifiedAt`.
- **`BillingCycleType`** enum: `monthly`, `yearly`. **`CancelType`** enum: `immediate`, `atExpiry`.
- **`Subscription`**: `id`, `name`, optional `emoji`/`imagePath`, `startDate`, `trialDays` (default
  `0`), `billingCycleType`, `billingInterval` (every X months/years, default `1`), `amount`,
  `currency` (default `'CNY'`), `accountId`, optional `categoryId`, `note` (default `''`),
  `isActive` (default `true`), optional `cancelledAt`, optional `cancelType`, optional persisted
  `nextBillingDate`, `modifiedAt`. `firstBillingDate` = `startDate + trialDays`, counted in calendar
  days (`addCalendarDays`, so the start time of day is kept across a DST change, v1.5.2).
  `Subscription.nextBillingCursor(...)` is the shared month-end-clamping cursor advance used by both
  the model and `SubscriptionProcessor` — see
  [Subscription Billing](algorithms/subscription-billing.md) for the full algorithm.
- **`IconRef`**: `codePoint` (Material icon code point), `fontFamily` (default `'MaterialIcons'`).
  Because icon data is reconstructed dynamically from these two fields, release builds require
  `--no-tree-shake-icons`.

`FinanceStorage` also persists in `finance_data.json`: the account list (with optional fee-waiver
criteria), categories, transactions, subscriptions, default currency, subscription
reminders/sort order, account sort modes/custom orders, `AccountPickerSettings` for the transaction
account picker, and `settingsModifiedAt`.

### `exchange_rates.json`

`ExchangeRateStorage` keeps a snapshot-based history: a map of `RateSnapshot`s (deduplicated),
a `currentSnapshotId`, and `lastFetchedAt`. It migrates forward from an older flat
currency→rate map format. See [Finance](features/finance.md) for how `ExchangeRateApi` populates
this and how `balance_util.dart` consumes it.

A missing or blank file reads as the default snapshot. Since v1.5.2 an existing file that cannot be
read or parsed raises `ExchangeRateStorageException` instead of silently returning the defaults, and
a save refuses to overwrite such a file, so the snapshot history is never replaced by one default
snapshot. The Finance page shows its unreadable-data view, the exchange-rates page a blocking error
view with a retry button, and the local API `data_unreadable`. `FinanceStorage.load` reads this file
only when an account still carries a legacy forced balance to migrate, so ordinary finance loads do
not depend on it. The on-disk format is unchanged.

## Intimacy — `intimacy_data.json`

Source: `lib/features/intimacy/models/intimacy_record.dart`.

- **`BodyProfile`** (gender-neutral, all-optional, per person): `bustCm`, `waistCm`, `hipCm` (only
  meaningful for partners — the user's own bust/waist/hip live in the Weight module instead),
  `underbustCm`, `braStandard` (`'eu' | 'fr_es' | 'jp' | 'uk' | 'us' | 'au_nz'`, null = display
  default), `cycleEnabled` (default `false`), `showCycleOnCalendar` (default `false`),
  `erectLengthCm`, `baseCircumferenceCm`, `frontCircumferenceCm` (the three PSI inputs). An
  all-null/all-false profile reports `isEmpty == true` and serializes as entirely absent keys (a
  wholly-empty profile is dropped rather than written as `{}`).
- **`CycleRecord`**: `id`, optional `personId` (`null` = the user, otherwise a `Partner.id`),
  `date` (local calendar date as `yyyy-MM-dd` string, no time component), `modifiedAt`. Add/delete
  only — there is no edit flow; merged per id so deletions propagate (see
  [Three-Way Merge](algorithms/three-way-merge.md)).
- **`Partner`**: `id`, `name`, optional `emoji`/`imagePath`, optional `startDate`/`endDate`
  (relationship dates), optional `body` (`BodyProfile?`), `modifiedAt`. The body profile travels
  atomically with the partner record in sync — body edits go through `Partner.copyWith`, which
  bumps `modifiedAt` on the whole partner record.
- **`Toy`**: `id`, `name`, optional `emoji`/`imagePath`, optional `purchaseDate`/`retiredDate`,
  optional `purchaseLink`, optional `price`, `modifiedAt`.
- **`Position`**: `id`, `name`, optional `emoji`, `modifiedAt`.
- **`IntimacyRecord`**: `id`, `type` (`'Regular'` or `'Solo'` string), optional `location`,
  `isSolo` (default `false`), optional `partnerId`, `toyIds`/`positionIds` (`List<String>`),
  `pleasureLevel` (1-5), `duration` (stored as `duration`-in-seconds), optional `thrustCount`,
  `thrustCountUnit` (normalized to exactly `1` or `100`; any non-`1` value is coerced to `100`),
  optional `thrustTimeline` (v1.5.5, see below), `datetime`, optional `notes`,
  `hadOrgasm`/`watchedPorn`/`usedCondom` (default `false`), `modifiedAt`.
  `thrustCount`/`thrustCountUnit` are omitted from JSON entirely when `thrustCount` is null.
  `duration` keeps its seconds for timer-made records (since v1.5.5, also through the record
  dialog unless its duration fields are edited). Three derived values are computed at read time
  and **never persisted**: `resolvedThrustCount` (`thrustCount * thrustCountUnit`, null when no
  positive count was recorded), `thrustsPerMinute` (the record's average thrusting rate,
  `resolvedThrustCount / duration-in-minutes`, null unless both inputs are present and the
  duration is non-zero), and `hasThrustTimeline` (v1.5.5: the timeline has at least two events
  and its total equals `resolvedThrustCount`, which gates the chart).
- **`TimerHistoryEntry`**: `start`, `duration` (serialized as `durationMs`), `thrustCount` (clamped
  `>= 0`), `thrustCountUnit` (normalized to `1` or `100`), optional `thrustTimeline` (v1.5.5). Reads
  legacy entries that stored an `end` timestamp instead of `durationMs` and derives
  `duration = end - start`.
- **`IntimacyTimerSession`**: `firstStartedAt`, optional `startedAt`, `accumulated` (elapsed time
  before the current running segment, serialized as `accumulatedMs`), `running`, `thrustCount`,
  `thrustCountUnit`, optional `thrustTimeline` (v1.5.5). `elapsedAt(now)` returns `accumulated`
  when paused, or `accumulated + (now - startedAt)` while running — so a running session's elapsed
  time is always derived from wall-clock time, never from a stored "current" duration.
- **`thrustTimeline`** (v1.5.5), on all three models above: the timer's thrust-counter presses as
  `[[elapsedMs, delta], ...]` — integer pairs, oldest first, `elapsedMs >= 0` the stopwatch time of
  the press in milliseconds and `delta > 0` the repetitions it added. For example
  `"thrustTimeline": [[61000, 100], [95500, 50], [130250, 10]]`. Its total (the sum of the deltas)
  is expected to equal the item's actual count (`thrustCount * thrustCountUnit`):
  `AddRecordDialog` drops the timeline on save when they differ, and the timer page re-seeds it on
  restore, but readers do not enforce it. The key is **omitted** when there is no timeline (an
  empty one is normalized to absent), so data that never used the v1.5.5 timer serializes exactly
  as before and the WebDAV golden transcripts are byte-identical. Reading is tolerant
  (`ThrustTimeline.fromJson`): a pair that is not two numbers, or has a negative time or a
  non-positive delta, is skipped, the rest are sorted by time, and nothing usable reads as absent —
  a damaged timeline never makes the file unreadable. A single-event timeline is valid (a
  pre-1.5.5 session restored and then saved carries one) but draws no chart. `thrustTimeline` is a
  known key in the record, timer-history and timer-session preservation schemas
  (`json_preservation.dart`). Builds before v1.5.5 do not know the key and carry it forward as an
  unknown field — on their own saves (preserved from the file on disk) and through sync — so the
  data survives a round trip through an older device. Such a build can still change the count
  beside it; the timer page then re-seeds on restore, but a record edited that way keeps a timeline
  whose total no longer matches its count. `hasThrustTimeline` then reports false, so the detail
  page hides the stale curve, and the next save from `AddRecordDialog` drops the timeline.
- **`IntimacyData`**: `partners`, `toys`, `positions`, `records`, `timerHistory`
  (`List<TimerHistoryEntry>`), optional `timerSession`, `timerSessionModifiedAt` (own LWW
  timestamp, epoch-UTC default), optional `userBody` (`BodyProfile?` — the user's own profile,
  only serialized when non-null and non-empty), `userBodyModifiedAt` (own LWW timestamp,
  independent of `settingsModifiedAt`), `cycleRecords` (`List<CycleRecord>` for the user and
  partners), `timerHistoryRetentionDays` (`null` = permanent, otherwise `3`/`7`/`14`),
  `partnerSortModes`/`partnerCustomOrders`/`toySortModes`/`toyCustomOrders` (per-list sort
  settings), optional `chartSettings` (`IntimacyChartSettings?`), `settingsModifiedAt`.
- **`IntimacyChartSettings`** (v1.3.2): the consolidated trend chart's view preferences, shared by
  the intimacy home page and every partner/toy detail page. Two keys: `metrics` (`List<String>`,
  default `['pleasure', 'duration', 'thrustRate']`; recognized ids are `pleasure`, `frequency`,
  `duration`, `thrustCount`, `thrustRate`) and `range` (`String`, default `'3m'`; recognized ids
  are `1w`, `1m`, `3m`, `6m`, `1y`, `all`). Identifiers are **strings, never enum indices**, and
  are round-tripped verbatim — a build that does not recognize an id keeps it in the list instead
  of dropping it, so syncing through an older device is lossless. Unrecognized ids are simply not
  drawn; if nothing recognizable remains, the chart renders the defaults. The whole object is
  omitted from JSON until the user first changes the selection, which is why adding it in v1.3.2
  left the WebDAV golden transcripts byte-identical.

## Weight — `weight_data.json`

Source: `lib/features/weight/models/weight_record.dart`.

- **`WeightRecord`**: `id`, `weight` (kg), optional `bodyFat` (percentage), optional
  `bustCm`/`waistCm`/`hipCm` (cm), `datetime`, optional `notes`, `modifiedAt`.
- **`WeightData`**: optional `height` (cm), `records` (`List<WeightRecord>`), `reminderMode`
  (`'none' | 'once' | 'twice'`), optional `morningHour`/`morningMinute`/`eveningHour`/
  `eveningMinute`, `reminderGraceMinutes` (default `180`), `settingsModifiedAt`.
- `WeightData.calculateBMI(heightCm, weightKg)` returns `null` when `heightCm` is null or `<= 0`,
  otherwise `weightKg / (heightM * heightM)`.
- `WeightData.calculateWaistHipRatio(waistCm, hipCm)` returns `null` unless both are positive,
  otherwise `waistCm / hipCm`.
- `WeightData.effectiveMeasurementsUpTo(records, at)` and `effectiveMeasurementTimeline(records)`
  walk records in chronological order (tie-broken by `modifiedAt` then `id`) and carry the latest
  *positive* value of each of bust/waist/hip forward independently — a record with a blank or
  zero/negative field inherits the previous record's value for display purposes without ever
  writing that inherited value back into the record itself. See [Weight](features/weight.md).

## `storage_config.json`

Always stays in the default app directory (never moved by a custom storage path). Holds: custom
storage path, intimacy visibility toggle, theme, locale, week start day, tray settings, backup
settings, local API settings (`apiPort`, `apiListenAddress`, `apiEnabled`, `apiUsername`,
`apiPassword`), today's fired desktop reminder keys (`reminderNotifiedKeys`), the local-only
intimacy timer keep-screen-awake preference (`intimacyTimerKeepScreenAwake`), the local-only
body weight-sync warning opt-out (`intimacyBodyWeightSyncWarningDisabled`), the four
device-local list column preferences (`todoSectionColumns`, `financeListColumns`,
`weightListColumns`, `intimacyListColumns`), the on-device AI switches (`onDeviceAiEnabled`,
`onDeviceAiPreferFast`, v1.5.0), the interface style (`uiStyle`, v1.6.0), and the two navigation
placement keys `navPlacement` and `navRailRight` (v1.6.1).

The two on-device AI keys are written only when `true` and removed when switched off, so an
absent key means off. They are device-local because whether a model exists is a property of the
device — see [on-device-ai.md](on-device-ai.md).

`navPlacement` (`"sideOnWide"` or `"side"`; the rail on wide windows only, or everywhere — the default,
bottom bar everywhere, removes the key; unknown values read as the default) and `navRailRight` (the side
rail sits on the right; written only as `true`) are device-local and never synced — they describe the
device's window, like the column preferences. See [adaptive-layout.md](adaptive-layout.md).

The four list column preferences are stored here, and therefore never synced, on purpose: window
size is a property of the device, not of the account — see
[adaptive-layout.md](adaptive-layout.md). Each is absent until the user pins a count and holds an
integer 1..4; anything else, including the absent case, reads back as "auto".

Every write to this file is a read-merge-write that `TodoStorage` serializes through one config
write queue and writes atomically (temporary file, then rename) since v1.5.2. `writeConfig` takes
only the keys being changed (a `null` value removes the key), so two settings saved at once can no
longer drop each other. A write refuses to build on an existing file that is not a parseable JSON
object and throws `TodoStorageException` instead, so `storagePath` and the API credentials are never
replaced by a near-empty map; a missing or blank file counts as `{}`. Reads through
`TodoStorage.readConfig()` stay lenient and return `{}` for an unreadable file. The format is
unchanged.

## Persisted Data Inventory

Reproduced from `AGENTS.md`. Default app data directory is `Documents/MyDay/` on desktop or the
platform app documents directory on mobile; desktop users can choose a custom storage path, but
`storage_config.json` always stays in the default app directory.

| Data | File | Synced | Notes |
| --- | --- | --- | --- |
| Core preferences | `storage_config.json` | No | Custom path, intimacy visibility, theme, locale, week start day, tray, backup, local API settings, today's fired desktop reminder keys (`reminderNotifiedKeys`), local-only intimacy timer keep-screen-awake preference (`intimacyTimerKeepScreenAwake`), local-only body weight-sync warning opt-out (`intimacyBodyWeightSyncWarningDisabled`), device-local list column preferences (`todoSectionColumns`, `financeListColumns`, `weightListColumns`, `intimacyListColumns`), on-device AI switches (`onDeviceAiEnabled`, `onDeviceAiPreferFast`), interface style (`uiStyle`, 1.6.0: written only as `"material3"` when Material 3 is chosen; absent means Expressive, the default, which also shows the floating navigation bar), navigation placement (`navPlacement`: `"sideOnWide"` or `"side"`, and `navRailRight: true`, 1.6.1; absent means the default: bottom bar everywhere, rail on the left when shown) |
| Todo | `todo_data.json` | Yes | Tasks, daily templates, completion log, daily score log, reminders, task sort/custom order |
| Finance | `finance_data.json` | Yes | Accounts including optional fee waiver criteria, categories, transactions, subscriptions, finance settings, transaction account picker settings |
| Exchange rates | `exchange_rates.json` | Yes | Rate snapshots and `lastFetchedAt` |
| Intimacy | `intimacy_data.json` | Yes | Partners including optional body profiles, toys, positions, records, timer history/session including thrust counts, user body profile (`userBody` + `userBodyModifiedAt`), cycle records, sort settings, trend-chart view settings (`chartSettings`) |
| Weight | `weight_data.json` | Yes | Height, records including optional bust/waist/hip cm fields, reminders, grace window |
| Profile (display name and avatar) | `profile.json` | Yes | Since 1.6.0: the user's display name and avatar path, each with its own timestamp; last writer wins per field; conflict-free; created only when first set |
| WebDAV config | `webdav_config.json` | No | User server config and credentials; moved with custom storage path |
| Sync base | `.sync_base/*.json` | No | Last-synced snapshots for three-way merge |
| Images | `images/*` | Yes | Referenced finance/intimacy images and, since 1.6.0, the profile avatar (`images/avatar_<uuid>.jpg`) sync; backups include images. Files are `<uuid><ext>` in any image format, including `.svg` (bundled bank logos copied on preset pick, v1.4.5); no format change |
| Backups | `backups/backup_*.json` | No | Local recovery bundles; v2 bundles reference deduplicated image blobs |
| Backup image blobs | `backups/blobs/` | No | Content-addressed (`sha256`), shared across backups, reference-counted GC |
| On-device AI insights | `ai_insights.json` | No | Per-device cache of generated insight cards (v1.5.0); never synced, backed up or exported; rebuildable, so an unreadable file reads as empty |

`TodoStorage.setStoragePath()` moves **everything** in the old data folder — the data files,
`webdav_config.json`, `ai_insights.json`, and the `images/`, `backups/` and `.sync_base/`
directories — through `migrateStorageContents` (copy-then-delete; an entry that already exists at
the destination wins and is left alone). Only `storage_config.json` is skipped: it always stays in
the default app directory because it holds the custom path itself.

## `profile.json`

`profile.json` (1.6.0) is the sixth registered module, so it also syncs, is backed up, is included in
ZIP export, and has its own `.sync_base/profile.json`. It holds the user's display name and avatar
(see [`features/profile.md`](features/profile.md)):

```json
{
  "version": 1,
  "displayName": "Yuan",
  "displayNameUpdatedAt": "2026-10-01T14:06:42.530801Z",
  "avatar": "images/avatar_2953ac52-337e-4271-a8e1-bcd97ee416ba.jpg",
  "avatarUpdatedAt": "2026-10-01T14:08:59.163627Z"
}
```

- `displayName` / `displayNameUpdatedAt` — the name and when it last changed (UTC). Trimmed on save;
  clearing it writes `"displayName": null` with a new timestamp.
- `avatar` / `avatarUpdatedAt` — the avatar as a path relative to the data directory
  (`images/avatar_<uuid>.jpg`, a 512 x 512 JPEG) and when it last changed (UTC). A removed avatar is
  written as an explicit `"avatar": null` with its timestamp, so the removal syncs.
- A field is written only once it has a timestamp; a field with no timestamp means "never set" and
  always loses a merge to one that was set. Each field merges by last writer wins, independently of
  the other — see [`sync.md`](sync.md#the-profile-file). Unknown keys survive. `version` is `1`.
- The avatar image is an ordinary file in `images/`, so it syncs through the engine's referenced-only
  additive image phase (the module reports it through `profileReferencedImages`), and is backed up and
  exported with the other images. Each new avatar gets a fresh file name, because image sync never
  overwrites an existing file; replaced avatars are deleted locally only, so old ones remain on the
  WebDAV server and other devices.
- Builds older than 1.6.0 never request `profile.json`, so it does not affect them.

## `profile.json`

`profile.json` (1.6.0) is the sixth registered module, so it also syncs, is backed up, is included in
ZIP export, and has its own `.sync_base/profile.json`. It holds the user's display name and avatar
(see [`features/profile.md`](features/profile.md)):

```json
{
  "version": 1,
  "displayName": "Yuan",
  "displayNameUpdatedAt": "2026-10-01T14:06:42.530801Z",
  "avatar": "images/avatar_2953ac52-337e-4271-a8e1-bcd97ee416ba.jpg",
  "avatarUpdatedAt": "2026-10-01T14:08:59.163627Z"
}
```

- `displayName` / `displayNameUpdatedAt` — the name and when it last changed (UTC). Trimmed on save;
  clearing it writes `"displayName": null` with a new timestamp.
- `avatar` / `avatarUpdatedAt` — the avatar as a path relative to the data directory
  (`images/avatar_<uuid>.jpg`, a 512 x 512 JPEG) and when it last changed (UTC). A removed avatar is
  written as an explicit `"avatar": null` with its timestamp, so the removal syncs.
- A field is written only once it has a timestamp; a field with no timestamp means "never set" and
  always loses a merge to one that was set. Each field merges by last writer wins, independently of
  the other — see [`sync.md`](sync.md#the-profile-file). Unknown keys survive. `version` is `1`.
- The avatar image is an ordinary file in `images/`, so it syncs through the engine's referenced-only
  additive image phase (the module reports it through `profileReferencedImages`), and is backed up and
  exported with the other images. Each new avatar gets a fresh file name, because image sync never
  overwrites an existing file; replaced avatars are deleted locally only, so old ones remain on the
  WebDAV server and other devices.
- Builds older than 1.6.0 never request `profile.json`, so it does not affect them.

## `ai_insights.json`

The on-device AI insight cache (v1.5.0), written atomically through `AiInsightsCache` with its own
write queue. It is **not** a registered data module: never synced, never in a backup bundle or ZIP
export, and it has no preservation schema. Unlike the data files, an unreadable or malformed file
reads as empty — it is a cache, and losing it only costs one regeneration per card. *Clear
generated insights* in Settings deletes it.

```json
{
  "version": 1,
  "insights": {
    "finance": {
      "fingerprint": "3f9a…",
      "generatedAt": "2026-09-28T01:02:03.000Z",
      "language": "zh_CN",
      "lines": ["…", "…", "…", "…"],
      "model": "stable/full · nano-v3",
      "promptVersion": 2,
      "slots": ["flowSummary", "flowAdvice", "subSummary", "subAdvice"],
      "status": "ok"
    }
  }
}
```

- Keys under `insights` are `todo`, `finance`, `weight`, `intimacy`. Unknown keys and malformed
  entries are dropped on read.
- `fingerprint` is the hex SHA-256 described in
  [on-device-ai.md](on-device-ai.md#cache-and-fingerprint); a card regenerates only when it changes.
- `lines` holds the validated sentences in slot order and `slots` the slot id of each, so a card can
  group lines under its section headings even when an earlier slot was dropped.
- `status` is `ok`, or `skipped` when the model refused (`guardrail`) or cannot write the language;
  a skipped entry has no lines and is not retried until the fingerprint changes.
- `generatedAt` is UTC.

## Related pages

- [Architecture](architecture.md) — storage/write-queue/UTC-timestamp rules that govern all of the
  above.
- [WebDAV Sync](sync.md) and [Three-Way Merge](algorithms/three-way-merge.md) — how each file
  merges across devices.
- [Backup & Restore](backup-restore.md) — how these files are bundled and validated in backups.

## AI sources and WebDAV privacy

MyApps-AI v0.5.3 is explicitly split into runtime, platform, models, local UI and llama.cpp packages. Settings uses the unified section skeleton. Global source selection is device-local (`aiSourceSelection`), defaults to system AI, and never chooses online as fallback. Qwen3.5 0.8B/2B Q4_K_M and Gemma 4 E2B Q4_0 run on CPU. Downloads require explicit actions, use pinned URLs and SHA-256, and live under `ai_models/` outside data modules, sync, backup and ZIP. Model leases prevent removal during use. Source switches cancel old work and release model resources. System proofreading remains independent in MyNihongo.

WebDAV notice version 1 must be acknowledged on each device before connection testing, manual/force sync or background sync. The record is in device-local storage_config.json. Existing configurations stay intact while sync is paused; the WebDAV page displays a review banner. Declining saves no configuration and makes no request. JSON/images have no application-level encryption; HTTPS protects transit, HTTP does not. Wire format, locks and conflict policy remain unchanged.
