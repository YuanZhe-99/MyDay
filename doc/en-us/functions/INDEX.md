# MyDay `lib/` Function Index

This is the top-level index of the hand-written Function Explanation Layer documentation for
`lib/` in the MyDay repo. Each row links to a per-source-file page under `doc/en-us/functions/`
mirroring the `lib/` tree (with `.dart` replaced by `.md`).

**Totals:** `grep -r '/// Purpose:' lib --include=*.dart` reports **1367** (per the Function
Explanation Layer convention in `AGENTS.md`; generated `lib/l10n/` code carries no such comments —
see [l10n/INDEX.md](l10n/INDEX.md)). The per-file rows below sum to **1348** documented
declarations across 72 pages.

Individual per-file discrepancies are called out with a reconciliation note on each file page:
some files have real declarations with no `/// Purpose:` comment at all (added as extra rows),
while at least one file (`sync_merge.dart`) has a single declaration whose doc comment is
legitimately referenced by two Declarations-table entries. **The remaining ~19-declaration gap
between the grep and the row sum is known drift that predates v1.3.2** and has not been audited
page by page; the per-file tables, not these headline totals, are the reliable figures. (Earlier
revisions of this page quoted 1436/1435, which appears to have come from a grep that also swept
`test/`.) Nothing here is forced to hit a round number.

| Tier | Count |
|---|---|
| Tier A (full entry) | 766 |
| Tier B (index row only) | 582 |
| **Total** | **1348** |

## Root (`lib/`)

| Source file | Page | Declarations | Tier A |
|---|---|---|---|
| `lib/main.dart` | [main.md](main.md) | 1 | 1 |

## app/

| Source file | Page | Declarations | Tier A |
|---|---|---|---|
| `lib/app/app.dart` | [app/app.md](app/app.md) | 2 | 0 |
| `lib/app/router.dart` | [app/router.md](app/router.md) | 1 | 1 |
| `lib/app/data_modules.dart` | [app/data_modules.md](app/data_modules.md) | 12 | 12 |
| `lib/app/theme.dart` | [app/theme.md](app/theme.md) | 3 | 2 |

## features/finance/

| Source file | Page | Declarations | Tier A |
|---|---|---|---|
| `lib/features/finance/models/finance.dart` | [features/finance/models/finance.md](features/finance/models/finance.md) | 28 | 24 |
| `lib/features/finance/services/account_picker_util.dart` | [features/finance/services/account_picker_util.md](features/finance/services/account_picker_util.md) | 4 | 4 |
| `lib/features/finance/services/balance_util.dart` | [features/finance/services/balance_util.md](features/finance/services/balance_util.md) | 14 | 14 |
| `lib/features/finance/services/bank_preset_service.dart` | [features/finance/services/bank_preset_service.md](features/finance/services/bank_preset_service.md) | 10 | 6 |
| `lib/features/finance/services/exchange_rate_api.dart` | [features/finance/services/exchange_rate_api.md](features/finance/services/exchange_rate_api.md) | 3 | 3 |
| `lib/features/finance/services/exchange_rate_storage.dart` | [features/finance/services/exchange_rate_storage.md](features/finance/services/exchange_rate_storage.md) | 16 | 16 |
| `lib/features/finance/services/finance_storage.dart` | [features/finance/services/finance_storage.md](features/finance/services/finance_storage.md) | 11 | 10 |
| `lib/features/finance/services/subscription_processor.dart` | [features/finance/services/subscription_processor.md](features/finance/services/subscription_processor.md) | 7 | 5 |
| `lib/features/finance/views/accounts_page.dart` | [features/finance/views/accounts_page.md](features/finance/views/accounts_page.md) | 64 | 23 |
| `lib/features/finance/views/analysis_page.dart` | [features/finance/views/analysis_page.md](features/finance/views/analysis_page.md) | 34 | 18 |
| `lib/features/finance/views/categories_page.dart` | [features/finance/views/categories_page.md](features/finance/views/categories_page.md) | 22 | 5 |
| `lib/features/finance/views/category_detail_page.dart` | [features/finance/views/category_detail_page.md](features/finance/views/category_detail_page.md) | 14 | 4 |
| `lib/features/finance/views/exchange_rates_page.dart` | [features/finance/views/exchange_rates_page.md](features/finance/views/exchange_rates_page.md) | 18 | 9 |
| `lib/features/finance/views/finance_page.dart` | [features/finance/views/finance_page.md](features/finance/views/finance_page.md) | 29 | 6 |
| `lib/features/finance/views/subscription_detail_page.dart` | [features/finance/views/subscription_detail_page.md](features/finance/views/subscription_detail_page.md) | 12 | 3 |
| `lib/features/finance/views/subscriptions_page.dart` | [features/finance/views/subscriptions_page.md](features/finance/views/subscriptions_page.md) | 35 | 19 |
| `lib/features/finance/widgets/add_subscription_dialog.dart` | [features/finance/widgets/add_subscription_dialog.md](features/finance/widgets/add_subscription_dialog.md) | 13 | 4 |
| `lib/features/finance/widgets/add_transaction_dialog.dart` | [features/finance/widgets/add_transaction_dialog.md](features/finance/widgets/add_transaction_dialog.md) | 39 | 15 |
| `lib/features/finance/widgets/bank_preset_picker.dart` | [features/finance/widgets/bank_preset_picker.md](features/finance/widgets/bank_preset_picker.md) | 11 | 1 |
| `lib/features/finance/widgets/grouped_transaction_list.dart` | [features/finance/widgets/grouped_transaction_list.md](features/finance/widgets/grouped_transaction_list.md) | 1 | 1 |

## features/intimacy/

| Source file | Page | Declarations | Tier A |
|---|---|---|---|
| `lib/features/intimacy/models/intimacy_record.dart` | [features/intimacy/models/intimacy_record.md](features/intimacy/models/intimacy_record.md) | 43 | 43 |
| `lib/features/intimacy/services/body_metrics.dart` | [features/intimacy/services/body_metrics.md](features/intimacy/services/body_metrics.md) | 8 | 7 |
| `lib/features/intimacy/services/cycle_predictor.dart` | [features/intimacy/services/cycle_predictor.md](features/intimacy/services/cycle_predictor.md) | 16 | 7 |
| `lib/features/intimacy/services/intimacy_storage.dart` | [features/intimacy/services/intimacy_storage.md](features/intimacy/services/intimacy_storage.md) | 7 | 6 |
| `lib/features/intimacy/views/body_page.dart` | [features/intimacy/views/body_page.md](features/intimacy/views/body_page.md) | 4 | 0 |
| `lib/features/intimacy/views/intimacy_page.dart` | [features/intimacy/views/intimacy_page.md](features/intimacy/views/intimacy_page.md) | 175 | 53 |
| `lib/features/intimacy/widgets/add_record_dialog.dart` | [features/intimacy/widgets/add_record_dialog.md](features/intimacy/widgets/add_record_dialog.md) | 9 | 2 |
| `lib/features/intimacy/widgets/body_section.dart` | [features/intimacy/widgets/body_section.md](features/intimacy/widgets/body_section.md) | 35 | 18 |
| `lib/features/intimacy/widgets/cycle_calendar.dart` | [features/intimacy/widgets/cycle_calendar.md](features/intimacy/widgets/cycle_calendar.md) | 9 | 1 |
| `lib/features/intimacy/widgets/intimacy_trend_chart.dart` | [features/intimacy/widgets/intimacy_trend_chart.md](features/intimacy/widgets/intimacy_trend_chart.md) | 25 | 16 |
| `lib/features/intimacy/widgets/timer_page.dart` | [features/intimacy/widgets/timer_page.md](features/intimacy/widgets/timer_page.md) | 32 | 22 |

## features/settings/

| Source file | Page | Declarations | Tier A |
|---|---|---|---|
| `lib/features/settings/views/license_page.dart` | [features/settings/views/license_page.md](features/settings/views/license_page.md) | 2 | 0 |
| `lib/features/settings/views/privacy_policy_page.dart` | [features/settings/views/privacy_policy_page.md](features/settings/views/privacy_policy_page.md) | 3 | 0 |
| `lib/features/settings/views/settings_page.dart` | [features/settings/views/settings_page.md](features/settings/views/settings_page.md) | 23 | 4 |

## features/todo/

| Source file | Page | Declarations | Tier A |
|---|---|---|---|
| `lib/features/todo/models/task.dart` | [features/todo/models/task.md](features/todo/models/task.md) | 38 | 37 |
| `lib/features/todo/services/todo_storage.dart` | [features/todo/services/todo_storage.md](features/todo/services/todo_storage.md) | 33 | 32 |
| `lib/features/todo/views/todo_page.dart` | [features/todo/views/todo_page.md](features/todo/views/todo_page.md) | 71 | 31 |
| `lib/features/todo/widgets/add_task_dialog.dart` | [features/todo/widgets/add_task_dialog.md](features/todo/widgets/add_task_dialog.md) | 15 | 5 |
| `lib/features/todo/widgets/edit_task_dialog.dart` | [features/todo/widgets/edit_task_dialog.md](features/todo/widgets/edit_task_dialog.md) | 16 | 5 |
| `lib/features/todo/widgets/recurrence_picker.dart` | [features/todo/widgets/recurrence_picker.md](features/todo/widgets/recurrence_picker.md) | 4 | 0 |
| `lib/features/todo/widgets/task_section.dart` | [features/todo/widgets/task_section.md](features/todo/widgets/task_section.md) | 9 | 0 |

## features/weight/

| Source file | Page | Declarations | Tier A |
|---|---|---|---|
| `lib/features/weight/models/weight_record.dart` | [features/weight/models/weight_record.md](features/weight/models/weight_record.md) | 13 | 13 |
| `lib/features/weight/services/weight_storage.dart` | [features/weight/services/weight_storage.md](features/weight/services/weight_storage.md) | 6 | 5 |
| `lib/features/weight/views/weight_page.dart` | [features/weight/views/weight_page.md](features/weight/views/weight_page.md) | 65 | 31 |

## l10n/

`lib/l10n/` is already documented at [l10n/INDEX.md](l10n/INDEX.md) (generated code, not part of
the 1436/1435 hand-documented declarations above).

## shared/

| Source file | Page | Declarations | Tier A |
|---|---|---|---|
| `lib/shared/providers/app_settings.dart` | [shared/providers/app_settings.md](shared/providers/app_settings.md) | 8 | 7 |
| `lib/shared/providers/intimacy_visibility.dart` | [shared/providers/intimacy_visibility.md](shared/providers/intimacy_visibility.md) | 6 | 5 |
| `lib/shared/services/auto_sync_service.dart` | [shared/services/auto_sync_service.md](shared/services/auto_sync_service.md) | 15 | 15 |
| `lib/shared/services/backup_service.dart` | [shared/services/backup_service.md](shared/services/backup_service.md) | 12 | 12 |
| `lib/shared/services/data_file_safety.dart` | [shared/services/data_file_safety.md](shared/services/data_file_safety.md) | 6 | 6 |
| `lib/shared/services/image_service.dart` | [shared/services/image_service.md](shared/services/image_service.md) | 5 | 5 |
| `lib/shared/services/import_export_service.dart` | [shared/services/import_export_service.md](shared/services/import_export_service.md) | 2 | 2 |
| `lib/shared/services/local_api_server.dart` | [shared/services/local_api_server.md](shared/services/local_api_server.md) | 63 | 58 |
| `lib/shared/services/mobile_notification_service.dart` | [shared/services/mobile_notification_service.md](shared/services/mobile_notification_service.md) | 9 | 7 |
| `lib/shared/services/reminder_service.dart` | [shared/services/reminder_service.md](shared/services/reminder_service.md) | 33 | 30 |
| `lib/shared/services/sync_merge.dart` | [shared/services/sync_merge.md](shared/services/sync_merge.md) | 12 | 12 |
| `lib/shared/services/sync_progress.dart` | [shared/services/sync_progress.md](shared/services/sync_progress.md) | 0 | 0 |
| `lib/shared/services/sync_wake_lock.dart` | [shared/services/sync_wake_lock.md](shared/services/sync_wake_lock.md) | 0 | 0 |
| `lib/shared/services/tray_service.dart` | [shared/services/tray_service.md](shared/services/tray_service.md) | 16 | 13 |
| `lib/shared/services/webdav_service.dart` | [shared/services/webdav_service.md](shared/services/webdav_service.md) | 12 | 12 |
| `lib/shared/utils/json_preservation.dart` | [shared/utils/json_preservation.md](shared/utils/json_preservation.md) | 6 | 6 |
| `lib/shared/utils/week_grouping.dart` | [shared/utils/week_grouping.md](shared/utils/week_grouping.md) | 16 | 16 |
| `lib/shared/views/backup_page.dart` | [shared/views/backup_page.md](shared/views/backup_page.md) | 17 | 2 |
| `lib/shared/views/webdav_config_page.dart` | [shared/views/webdav_config_page.md](shared/views/webdav_config_page.md) | 20 | 6 |
| `lib/shared/widgets/delete_confirm.dart` | [shared/widgets/delete_confirm.md](shared/widgets/delete_confirm.md) | 1 | 1 |
| `lib/shared/widgets/shell_scaffold.dart` | [shared/widgets/shell_scaffold.md](shared/widgets/shell_scaffold.md) | 8 | 2 |
| `lib/shared/widgets/sync_conflict_dialog.dart` | [shared/widgets/sync_conflict_dialog.md](shared/widgets/sync_conflict_dialog.md) | 6 | 0 |
| `lib/shared/widgets/unsaved_changes_guard.dart` | [shared/widgets/unsaved_changes_guard.md](shared/widgets/unsaved_changes_guard.md) | 10 | 5 |

## Area totals

| Area | Files | Declarations | Tier A | Tier B |
|---|---|---|---|---|
| Root (`lib/`) | 1 | 1 | 1 | 0 |
| `app/` | 3 | 6 | 3 | 3 |
| `features/finance/` | 20 | 385 | 190 | 195 |
| `features/intimacy/` | 11 | 363 | 175 | 188 |
| `features/settings/` | 3 | 28 | 4 | 24 |
| `features/todo/` | 7 | 186 | 110 | 76 |
| `features/weight/` | 3 | 84 | 49 | 35 |
| `shared/` | 23 | 387 | 302 | 85 |
| **Total** | **71** | **1440** | **834** | **606** |

The `features/intimacy/` row is verified against the per-file rows above as of v1.3.2 (11 files,
363 declarations, 175 Tier A). The other rows, and therefore this Total, carry the same
pre-v1.3.2 drift described under [Totals](#totals) — they do not reconcile with the per-file row
sums (1348 / 766 / 582) and have not been re-audited area by area.
