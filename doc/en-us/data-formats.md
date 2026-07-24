# Data Formats

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
  `nextBillingDate`, `modifiedAt`. `firstBillingDate` = `startDate + trialDays`.
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
  `datetime`, optional `notes`, `hadOrgasm`/`watchedPorn`/`usedCondom` (default `false`),
  `modifiedAt`. `thrustCount`/`thrustCountUnit` are omitted from JSON entirely when `thrustCount`
  is null.
- **`TimerHistoryEntry`**: `start`, `duration` (serialized as `durationMs`), `thrustCount` (clamped
  `>= 0`), `thrustCountUnit` (normalized to `1` or `100`). Reads legacy entries that stored an `end`
  timestamp instead of `durationMs` and derives `duration = end - start`.
- **`IntimacyTimerSession`**: `firstStartedAt`, optional `startedAt`, `accumulated` (elapsed time
  before the current running segment, serialized as `accumulatedMs`), `running`, `thrustCount`,
  `thrustCountUnit`. `elapsedAt(now)` returns `accumulated` when paused, or
  `accumulated + (now - startedAt)` while running — so a running session's elapsed time is always
  derived from wall-clock time, never from a stored "current" duration.
- **`IntimacyData`**: `partners`, `toys`, `positions`, `records`, `timerHistory`
  (`List<TimerHistoryEntry>`), optional `timerSession`, `timerSessionModifiedAt` (own LWW
  timestamp, epoch-UTC default), optional `userBody` (`BodyProfile?` — the user's own profile,
  only serialized when non-null and non-empty), `userBodyModifiedAt` (own LWW timestamp,
  independent of `settingsModifiedAt`), `cycleRecords` (`List<CycleRecord>` for the user and
  partners), `timerHistoryRetentionDays` (`null` = permanent, otherwise `3`/`7`/`14`),
  `partnerSortModes`/`partnerCustomOrders`/`toySortModes`/`toyCustomOrders` (per-list sort
  settings), `settingsModifiedAt`.

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
intimacy timer keep-screen-awake preference (`intimacyTimerKeepScreenAwake`), and the local-only
body weight-sync warning opt-out (`intimacyBodyWeightSyncWarningDisabled`).

## Persisted Data Inventory

Reproduced from `AGENTS.md`. Default app data directory is `Documents/MyDay/` on desktop or the
platform app documents directory on mobile; desktop users can choose a custom storage path, but
`storage_config.json` always stays in the default app directory.

| Data | File | Synced | Notes |
| --- | --- | --- | --- |
| Core preferences | `storage_config.json` | No | Custom path, intimacy visibility, theme, locale, week start day, tray, backup, local API settings, today's fired desktop reminder keys (`reminderNotifiedKeys`), local-only intimacy timer keep-screen-awake preference (`intimacyTimerKeepScreenAwake`), local-only body weight-sync warning opt-out (`intimacyBodyWeightSyncWarningDisabled`) |
| Todo | `todo_data.json` | Yes | Tasks, daily templates, completion log, daily score log, reminders, task sort/custom order |
| Finance | `finance_data.json` | Yes | Accounts including optional fee waiver criteria, categories, transactions, subscriptions, finance settings, transaction account picker settings |
| Exchange rates | `exchange_rates.json` | Yes | Rate snapshots and `lastFetchedAt` |
| Intimacy | `intimacy_data.json` | Yes | Partners including optional body profiles, toys, positions, records, timer history/session including thrust counts, user body profile (`userBody` + `userBodyModifiedAt`), cycle records, sort settings |
| Weight | `weight_data.json` | Yes | Height, records including optional bust/waist/hip cm fields, reminders, grace window |
| WebDAV config | `webdav_config.json` | No | User server config and credentials; moved with custom storage path |
| Sync base | `.sync_base/*.json` | No | Last-synced snapshots for three-way merge |
| Images | `images/*` | Yes | Referenced finance/intimacy images sync; backups include images |
| Backups | `backups/backup_*.json` | No | Local recovery bundles; v2 bundles reference deduplicated image blobs |
| Backup image blobs | `backups/blobs/` | No | Content-addressed (`sha256`), shared across backups, reference-counted GC |

Files moved by `TodoStorage.setStoragePath()`: `todo_data.json`, `finance_data.json`,
`exchange_rates.json`, `intimacy_data.json`, `weight_data.json`, and `webdav_config.json`.
`storage_config.json` always stays in the default app directory. Directories such as `images/`,
`backups/`, and `.sync_base/` are not moved by that file list.

## Related pages

- [Architecture](architecture.md) — storage/write-queue/UTC-timestamp rules that govern all of the
  above.
- [WebDAV Sync](sync.md) and [Three-Way Merge](algorithms/three-way-merge.md) — how each file
  merges across devices.
- [Backup & Restore](backup-restore.md) — how these files are bundled and validated in backups.
