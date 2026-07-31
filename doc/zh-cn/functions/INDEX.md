# MyDay `lib/` 函数索引

这是 MyDay 仓库中 `lib/` 手写函数解释层文档的顶层索引。每行链接到 `doc/en-us/functions/` 下镜像 `lib/` 树的逐源文件页面（`.dart` 换成 `.md`）。

**总计。** 两个不同的数字值得分清，本页报告两者。

| 度量 | 计数 |
|---|---|
| `grep -r '/// Purpose:' lib --include=*.dart` | **1367** |
| 全部 73 页的声明表行 | **1358** |
| ——其中 Tier A（完整条目） | 765 |
| ——其中 Tier B（仅索引行） | 593 |

下面的 **Declarations** 和 **Tier A** 列统计**每页声明表中的行**，这是可机械检查的数字。一行不总是一个 `/// Purpose:` 块，两个总计之间的 9 个声明差距被完整逐项列出——行数与自己的 `grep` 不同的每页都带一条 `**Reconciliation:**` 说明确切原因。有三个反复出现的原因：

- **文件级库注释**（`backup_service.dart`、`webdav_service.dart`、`import_export_service.dart`、`json_preservation.dart`、`sync_progress.dart`、`sync_wake_lock.dart`）：`import` 块上方的一个 `/// Purpose:` 块记录文件，不记录声明，因此被 `grep` 计数但得不到行。
- **没有 `Purpose:` 块的真实声明**（枚举、顶层 `const`、Riverpod provider、`appRouter`）：无 `grep` 命中，但有一行，因为它们是文件表面的一部分。
- **刻意分组的行**位于 `myapps_data` 上的薄门面页（`sync_merge.md`、`auto_sync_service.md`、`data_modules.md`）：一行覆盖一个类及其成员，或一族相关常量。那些页面在表格顶部说明。

这里没有任何东西被强制凑整。在 v1.3.2 中端到端审计，它也添加了缺失的 `app_date_picker.dart` 页面——该文件此前从未有过页面。（v1.3.2 之前的修订引用 1436/1435；那个数字来自也扫过 `test/` 的 `grep`，其逐区域细分已从逐文件行漂移。）

## 根（`lib/`）

| 源文件 | 页面 | 声明数 | Tier A |
|---|---|---|---|
| `lib/main.dart` | [main.md](main.md) | 1 | 1 |

## app/

| 源文件 | 页面 | 声明数 | Tier A |
|---|---|---|---|
| `lib/app/app.dart` | [app/app.md](app/app.md) | 2 | 0 |
| `lib/app/router.dart` | [app/router.md](app/router.md) | 1 | 1 |
| `lib/app/data_modules.dart` | [app/data_modules.md](app/data_modules.md) | 11 | 11 |
| `lib/app/theme.dart` | [app/theme.md](app/theme.md) | 3 | 2 |

## features/finance/

| 源文件 | 页面 | 声明数 | Tier A |
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

| 源文件 | 页面 | 声明数 | Tier A |
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

| 源文件 | 页面 | 声明数 | Tier A |
|---|---|---|---|
| `lib/features/settings/views/license_page.dart` | [features/settings/views/license_page.md](features/settings/views/license_page.md) | 2 | 0 |
| `lib/features/settings/views/privacy_policy_page.dart` | [features/settings/views/privacy_policy_page.md](features/settings/views/privacy_policy_page.md) | 3 | 0 |
| `lib/features/settings/views/settings_page.dart` | [features/settings/views/settings_page.md](features/settings/views/settings_page.md) | 23 | 4 |

## features/todo/

| 源文件 | 页面 | 声明数 | Tier A |
|---|---|---|---|
| `lib/features/todo/models/task.dart` | [features/todo/models/task.md](features/todo/models/task.md) | 38 | 37 |
| `lib/features/todo/services/todo_storage.dart` | [features/todo/services/todo_storage.md](features/todo/services/todo_storage.md) | 33 | 32 |
| `lib/features/todo/views/todo_page.dart` | [features/todo/views/todo_page.md](features/todo/views/todo_page.md) | 71 | 31 |
| `lib/features/todo/widgets/add_task_dialog.dart` | [features/todo/widgets/add_task_dialog.md](features/todo/widgets/add_task_dialog.md) | 15 | 5 |
| `lib/features/todo/widgets/edit_task_dialog.dart` | [features/todo/widgets/edit_task_dialog.md](features/todo/widgets/edit_task_dialog.md) | 16 | 5 |
| `lib/features/todo/widgets/recurrence_picker.dart` | [features/todo/widgets/recurrence_picker.md](features/todo/widgets/recurrence_picker.md) | 4 | 0 |
| `lib/features/todo/widgets/task_section.dart` | [features/todo/widgets/task_section.md](features/todo/widgets/task_section.md) | 9 | 0 |

## features/weight/

| 源文件 | 页面 | 声明数 | Tier A |
|---|---|---|---|
| `lib/features/weight/models/weight_record.dart` | [features/weight/models/weight_record.md](features/weight/models/weight_record.md) | 13 | 13 |
| `lib/features/weight/services/weight_storage.dart` | [features/weight/services/weight_storage.md](features/weight/services/weight_storage.md) | 6 | 5 |
| `lib/features/weight/views/weight_page.dart` | [features/weight/views/weight_page.md](features/weight/views/weight_page.md) | 65 | 31 |

## l10n/

`lib/l10n/` 已在 [l10n/INDEX.md](l10n/INDEX.md) 中记录（生成代码，不属于上面 1436/1435 个手写声明）。

## shared/

| 源文件 | 页面 | 声明数 | Tier A |
|---|---|---|---|
| `lib/shared/providers/app_settings.dart` | [shared/providers/app_settings.md](shared/providers/app_settings.md) | 8 | 7 |
| `lib/shared/providers/intimacy_visibility.dart` | [shared/providers/intimacy_visibility.md](shared/providers/intimacy_visibility.md) | 6 | 5 |
| `lib/shared/services/auto_sync_service.dart` | [shared/services/auto_sync_service.md](shared/services/auto_sync_service.md) | 11 | 11 |
| `lib/shared/services/backup_service.dart` | [shared/services/backup_service.md](shared/services/backup_service.md) | 12 | 12 |
| `lib/shared/services/data_file_safety.dart` | [shared/services/data_file_safety.md](shared/services/data_file_safety.md) | 6 | 6 |
| `lib/shared/services/image_service.dart` | [shared/services/image_service.md](shared/services/image_service.md) | 5 | 5 |
| `lib/shared/services/import_export_service.dart` | [shared/services/import_export_service.md](shared/services/import_export_service.md) | 2 | 2 |
| `lib/shared/services/local_api_server.dart` | [shared/services/local_api_server.md](shared/services/local_api_server.md) | 63 | 58 |
| `lib/shared/services/mobile_notification_service.dart` | [shared/services/mobile_notification_service.md](shared/services/mobile_notification_service.md) | 9 | 7 |
| `lib/shared/services/reminder_service.dart` | [shared/services/reminder_service.md](shared/services/reminder_service.md) | 33 | 30 |
| `lib/shared/services/sync_merge.dart` | [shared/services/sync_merge.md](shared/services/sync_merge.md) | 7 | 7 |
| `lib/shared/services/sync_progress.dart` | [shared/services/sync_progress.md](shared/services/sync_progress.md) | 0 | 0 |
| `lib/shared/services/sync_wake_lock.dart` | [shared/services/sync_wake_lock.md](shared/services/sync_wake_lock.md) | 0 | 0 |
| `lib/shared/services/tray_service.dart` | [shared/services/tray_service.md](shared/services/tray_service.md) | 16 | 13 |
| `lib/shared/services/webdav_service.dart` | [shared/services/webdav_service.md](shared/services/webdav_service.md) | 12 | 12 |
| `lib/shared/utils/json_preservation.dart` | [shared/utils/json_preservation.md](shared/utils/json_preservation.md) | 3 | 2 |
| `lib/shared/utils/week_grouping.dart` | [shared/utils/week_grouping.md](shared/utils/week_grouping.md) | 16 | 16 |
| `lib/shared/views/backup_page.dart` | [shared/views/backup_page.md](shared/views/backup_page.md) | 17 | 2 |
| `lib/shared/views/webdav_config_page.dart` | [shared/views/webdav_config_page.md](shared/views/webdav_config_page.md) | 20 | 6 |
| `lib/shared/widgets/app_date_picker.dart` | [shared/widgets/app_date_picker.md](shared/widgets/app_date_picker.md) | 23 | 13 |
| `lib/shared/widgets/delete_confirm.dart` | [shared/widgets/delete_confirm.md](shared/widgets/delete_confirm.md) | 1 | 1 |
| `lib/shared/widgets/shell_scaffold.dart` | [shared/widgets/shell_scaffold.md](shared/widgets/shell_scaffold.md) | 8 | 2 |
| `lib/shared/widgets/sync_conflict_dialog.dart` | [shared/widgets/sync_conflict_dialog.md](shared/widgets/sync_conflict_dialog.md) | 6 | 0 |
| `lib/shared/widgets/unsaved_changes_guard.dart` | [shared/widgets/unsaved_changes_guard.md](shared/widgets/unsaved_changes_guard.md) | 10 | 5 |

## 区域总计

| 区域 | 文件 | 声明数 | Tier A | Tier B |
|---|---|---|---|---|
| 根（`lib/`） | 1 | 1 | 1 | 0 |
| `app/` | 4 | 17 | 14 | 3 |
| `features/finance/` | 20 | 385 | 190 | 195 |
| `features/intimacy/` | 11 | 363 | 175 | 188 |
| `features/settings/` | 3 | 28 | 4 | 24 |
| `features/todo/` | 7 | 186 | 110 | 76 |
| `features/weight/` | 3 | 84 | 49 | 35 |
| `shared/` | 24 | 294 | 222 | 72 |
| **总计** | **73** | **1358** | **765** | **593** |

这里的每行都是上面逐文件行的算术和，在 v1.3.2 中重新派生。文件计数也与 `find lib -name '*.dart' -not -path 'lib/l10n/*'` 完全匹配——73 个源文件、73 个页面，没有无页面的文件，也没有无文件的面。
