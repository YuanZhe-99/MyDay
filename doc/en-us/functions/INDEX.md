# MyDay `lib/` Function Index


WebDAVConfigPage.build delegates generic settings controls to myapps_data.
Its declarations are unchanged; application operation callbacks remain here.

Settings groups delegate rendering to myapps_ui; see [shared-ui.md](../shared-ui.md).

Profile rows now document shared exports and app adapters; implementation ownership is in [shared-ui.md](../shared-ui.md).

This is the top-level index of the hand-written Function Explanation Layer documentation for
`lib/` in the MyDay repo. Each row links to a per-source-file page under `doc/en-us/functions/`
mirroring the `lib/` tree (with `.dart` replaced by `.md`).

**Historical extraction totals.** Two different numbers are worth keeping straight, and this page reports both.

| Measure | Count |
|---|---|
| `grep -r '/// Purpose:' lib --include=*.dart` | **1795** |
| Declarations-table rows across all 113 pages | **1865** |
| — of those rows, Tier A (full entry) | 1037 |
| — of those rows, Tier B (index row only) | 828 |

The **Declarations** and **Tier A** columns below count **rows in each page's Declarations
table**, which is the mechanically checkable figure. A row is not always one `/// Purpose:` block,
and the 70-row net excess of the table count over the grep count is fully itemized — every page whose row count
differs from its own `grep` carries a `**Reconciliation:**` note saying exactly why. There are
three recurring reasons:

- **File-level library comments** (`backup_service.dart`, `webdav_service.dart`,
  `import_export_service.dart`, `json_preservation.dart`, `sync_progress.dart`,
  `sync_wake_lock.dart`): a `/// Purpose:` block above the `import` block documents the file, not a
  declaration, so it is counted by `grep` but gets no row.
- **Real declarations with no `Purpose:` block** (enums, typedefs, top-level `const`s, Riverpod providers,
  `appRouter`): no `grep` hit, but a row, because they are part of the file's surface.
- **Deliberately grouped rows** on the thin facade pages over `myapps_data` (`sync_merge.md`,
  `auto_sync_service.md`, `data_modules.md`): one row covers a class and its members, or a family
  of related constants. Those pages say so at the top of their tables.

Nothing here is forced to hit a round number. Audited end to end in v1.3.2, which also added the
missing `app_date_picker.dart` page — the file had never had one. (Revisions before v1.3.2 quoted
1436/1435; that figure came from a `grep` that also swept `test/`, and its per-area breakdown had
drifted from the per-file rows.)

## Root (`lib/`)

| Source file | Page | Declarations | Tier A |
|---|---|---|---|
| `lib/features/ai/services/ai_source_backend.dart` | [features/ai/services/ai_source_backend.md](features/ai/services/ai_source_backend.md) | 21 | 0 |
| `lib/features/ai/widgets/ai_source_controls.dart` | [features/ai/widgets/ai_source_controls.md](features/ai/widgets/ai_source_controls.md) | 4 | 0 |
| `lib/shared/services/webdav_privacy.dart` | [shared/services/webdav_privacy.md](shared/services/webdav_privacy.md) | 3 | 0 |
| `lib/main.dart` | [main.md](main.md) | 1 | 1 |

## app/

| Source file | Page | Declarations | Tier A |
|---|---|---|---|
| `lib/app/app.dart` | [app/app.md](app/app.md) | 2 | 0 |
| `lib/app/build_flavor.dart` | [app/build_flavor.md](app/build_flavor.md) | 3 | 1 |
| `lib/app/data_modules.dart` | [app/data_modules.md](app/data_modules.md) | 13 | 13 |
| `lib/app/router.dart` | [app/router.md](app/router.md) | 1 | 1 |
| `lib/app/theme.dart` | [app/theme.md](app/theme.md) | 7 | 6 |

## features/ai/

| Source file | Page | Declarations | Tier A |
|---|---|---|---|
| `lib/features/ai/services/ai_insights_cache.dart` | [features/ai/services/ai_insights_cache.md](features/ai/services/ai_insights_cache.md) | 8 | 7 |
| `lib/features/ai/services/genai_backend.dart` | [features/ai/services/genai_backend.md](features/ai/services/genai_backend.md) | 3 | 0 |
| `lib/features/ai/services/insight_language.dart` | [features/ai/services/insight_language.md](features/ai/services/insight_language.md) | 3 | 3 |
| `lib/features/ai/services/insight_prompts.dart` | [features/ai/services/insight_prompts.md](features/ai/services/insight_prompts.md) | 21 | 12 |
| `lib/features/ai/services/insight_service.dart` | [features/ai/services/insight_service.md](features/ai/services/insight_service.md) | 12 | 0 |
| `lib/features/ai/services/on_device_ai_service.dart` | [features/ai/services/on_device_ai_service.md](features/ai/services/on_device_ai_service.md) | 4 | 0 |
| `lib/features/ai/services/output_validation.dart` | [features/ai/services/output_validation.md](features/ai/services/output_validation.md) | 0 | 0 |
| `lib/features/ai/widgets/ai_insight_card.dart` | [features/ai/widgets/ai_insight_card.md](features/ai/widgets/ai_insight_card.md) | 11 | 0 |
| `lib/features/ai/widgets/ai_settings_tiles.dart` | [features/ai/widgets/ai_settings_tiles.md](features/ai/widgets/ai_settings_tiles.md) | 6 | 0 |

## features/finance/

| Source file | Page | Declarations | Tier A |
|---|---|---|---|
| `lib/features/finance/models/finance.dart` | [features/finance/models/finance.md](features/finance/models/finance.md) | 28 | 24 |
| `lib/features/finance/services/account_picker_util.dart` | [features/finance/services/account_picker_util.md](features/finance/services/account_picker_util.md) | 4 | 4 |
| `lib/features/finance/services/balance_util.dart` | [features/finance/services/balance_util.md](features/finance/services/balance_util.md) | 16 | 16 |
| `lib/features/finance/services/bank_logo_manifest.g.dart` | [features/finance/services/bank_logo_manifest.g.md](features/finance/services/bank_logo_manifest.g.md) | 1 | 1 |
| `lib/features/finance/services/bank_preset_service.dart` | [features/finance/services/bank_preset_service.md](features/finance/services/bank_preset_service.md) | 12 | 7 |
| `lib/features/finance/services/exchange_rate_api.dart` | [features/finance/services/exchange_rate_api.md](features/finance/services/exchange_rate_api.md) | 3 | 3 |
| `lib/features/finance/services/exchange_rate_storage.dart` | [features/finance/services/exchange_rate_storage.md](features/finance/services/exchange_rate_storage.md) | 18 | 18 |
| `lib/features/finance/services/finance_insight_facts.dart` | [features/finance/services/finance_insight_facts.md](features/finance/services/finance_insight_facts.md) | 3 | 1 |
| `lib/features/finance/services/finance_storage.dart` | [features/finance/services/finance_storage.md](features/finance/services/finance_storage.md) | 12 | 11 |
| `lib/features/finance/services/subscription_processor.dart` | [features/finance/services/subscription_processor.md](features/finance/services/subscription_processor.md) | 7 | 5 |
| `lib/features/finance/services/subscription_summary.dart` | [features/finance/services/subscription_summary.md](features/finance/services/subscription_summary.md) | 7 | 3 |
| `lib/features/finance/views/accounts_page.dart` | [features/finance/views/accounts_page.md](features/finance/views/accounts_page.md) | 64 | 23 |
| `lib/features/finance/views/analysis_page.dart` | [features/finance/views/analysis_page.md](features/finance/views/analysis_page.md) | 34 | 18 |
| `lib/features/finance/views/categories_page.dart` | [features/finance/views/categories_page.md](features/finance/views/categories_page.md) | 22 | 5 |
| `lib/features/finance/views/category_detail_page.dart` | [features/finance/views/category_detail_page.md](features/finance/views/category_detail_page.md) | 14 | 4 |
| `lib/features/finance/views/exchange_rates_page.dart` | [features/finance/views/exchange_rates_page.md](features/finance/views/exchange_rates_page.md) | 19 | 9 |
| `lib/features/finance/views/finance_page.dart` | [features/finance/views/finance_page.md](features/finance/views/finance_page.md) | 42 | 11 |
| `lib/features/finance/views/subscription_detail_page.dart` | [features/finance/views/subscription_detail_page.md](features/finance/views/subscription_detail_page.md) | 12 | 3 |
| `lib/features/finance/views/subscriptions_page.dart` | [features/finance/views/subscriptions_page.md](features/finance/views/subscriptions_page.md) | 27 | 14 |
| `lib/features/finance/widgets/add_subscription_dialog.dart` | [features/finance/widgets/add_subscription_dialog.md](features/finance/widgets/add_subscription_dialog.md) | 13 | 4 |
| `lib/features/finance/widgets/add_transaction_dialog.dart` | [features/finance/widgets/add_transaction_dialog.md](features/finance/widgets/add_transaction_dialog.md) | 39 | 15 |
| `lib/features/finance/widgets/bank_logo_image.dart` | [features/finance/widgets/bank_logo_image.md](features/finance/widgets/bank_logo_image.md) | 7 | 2 |
| `lib/features/finance/widgets/bank_preset_picker.dart` | [features/finance/widgets/bank_preset_picker.md](features/finance/widgets/bank_preset_picker.md) | 11 | 1 |
| `lib/features/finance/widgets/grouped_transaction_list.dart` | [features/finance/widgets/grouped_transaction_list.md](features/finance/widgets/grouped_transaction_list.md) | 2 | 2 |
| `lib/features/finance/widgets/subscription_avatar.dart` | [features/finance/widgets/subscription_avatar.md](features/finance/widgets/subscription_avatar.md) | 4 | 1 |

## features/intimacy/

| Source file | Page | Declarations | Tier A |
|---|---|---|---|
| `lib/features/intimacy/models/intimacy_record.dart` | [features/intimacy/models/intimacy_record.md](features/intimacy/models/intimacy_record.md) | 45 | 45 |
| `lib/features/intimacy/services/body_metrics.dart` | [features/intimacy/services/body_metrics.md](features/intimacy/services/body_metrics.md) | 8 | 7 |
| `lib/features/intimacy/services/cycle_predictor.dart` | [features/intimacy/services/cycle_predictor.md](features/intimacy/services/cycle_predictor.md) | 16 | 7 |
| `lib/features/intimacy/services/intimacy_insight_facts.dart` | [features/intimacy/services/intimacy_insight_facts.md](features/intimacy/services/intimacy_insight_facts.md) | 16 | 9 |
| `lib/features/intimacy/services/intimacy_storage.dart` | [features/intimacy/services/intimacy_storage.md](features/intimacy/services/intimacy_storage.md) | 7 | 6 |
| `lib/features/intimacy/utils/thrust_timeline.dart` | [features/intimacy/utils/thrust_timeline.md](features/intimacy/utils/thrust_timeline.md) | 17 | 8 |
| `lib/features/intimacy/views/body_page.dart` | [features/intimacy/views/body_page.md](features/intimacy/views/body_page.md) | 4 | 0 |
| `lib/features/intimacy/views/intimacy_page.dart` | [features/intimacy/views/intimacy_page.md](features/intimacy/views/intimacy_page.md) | 186 | 60 |
| `lib/features/intimacy/views/record_detail_page.dart` | [features/intimacy/views/record_detail_page.md](features/intimacy/views/record_detail_page.md) | 19 | 4 |
| `lib/features/intimacy/widgets/add_record_dialog.dart` | [features/intimacy/widgets/add_record_dialog.md](features/intimacy/widgets/add_record_dialog.md) | 9 | 2 |
| `lib/features/intimacy/widgets/body_section.dart` | [features/intimacy/widgets/body_section.md](features/intimacy/widgets/body_section.md) | 35 | 18 |
| `lib/features/intimacy/widgets/cycle_calendar.dart` | [features/intimacy/widgets/cycle_calendar.md](features/intimacy/widgets/cycle_calendar.md) | 9 | 1 |
| `lib/features/intimacy/widgets/intimacy_trend_chart.dart` | [features/intimacy/widgets/intimacy_trend_chart.md](features/intimacy/widgets/intimacy_trend_chart.md) | 25 | 16 |
| `lib/features/intimacy/widgets/thrust_timeline_chart.dart` | [features/intimacy/widgets/thrust_timeline_chart.md](features/intimacy/widgets/thrust_timeline_chart.md) | 6 | 3 |
| `lib/features/intimacy/widgets/timer_page.dart` | [features/intimacy/widgets/timer_page.md](features/intimacy/widgets/timer_page.md) | 36 | 24 |

## features/profile/

| Source file | Page | Declarations | Tier A |
|---|---|---|---|
| `lib/features/profile/models/profile_data.dart` | [features/profile/models/profile_data.md](features/profile/models/profile_data.md) | 8 | 2 |
| `lib/features/profile/providers/profile_provider.dart` | [features/profile/providers/profile_provider.md](features/profile/providers/profile_provider.md) | 7 | 2 |
| `lib/features/profile/services/avatar_image.dart` | [features/profile/services/avatar_image.md](features/profile/services/avatar_image.md) | 8 | 5 |
| `lib/features/profile/services/profile_merge.dart` | [features/profile/services/profile_merge.md](features/profile/services/profile_merge.md) | 4 | 2 |
| `lib/features/profile/services/profile_store.dart` | [features/profile/services/profile_store.md](features/profile/services/profile_store.md) | 11 | 7 |
| `lib/features/profile/views/avatar_editor.dart` | [features/profile/views/avatar_editor.md](features/profile/views/avatar_editor.md) | 11 | 4 |
| `lib/features/profile/views/profile_avatar.dart` | [features/profile/views/profile_avatar.md](features/profile/views/profile_avatar.md) | 5 | 3 |
| `lib/features/profile/views/profile_header.dart` | [features/profile/views/profile_header.md](features/profile/views/profile_header.md) | 11 | 5 |

## features/settings/

| Source file | Page | Declarations | Tier A |
|---|---|---|---|
| `lib/features/settings/views/license_page.dart` | [features/settings/views/license_page.md](features/settings/views/license_page.md) | 2 | 0 |
| `lib/features/settings/views/privacy_policy_page.dart` | [features/settings/views/privacy_policy_page.md](features/settings/views/privacy_policy_page.md) | 3 | 0 |
| `lib/features/settings/views/settings_page.dart` | [features/settings/views/settings_page.md](features/settings/views/settings_page.md) | 28 | 8 |

## features/todo/

| Source file | Page | Declarations | Tier A |
|---|---|---|---|
| `lib/features/todo/constants/emoji_keywords.dart` | [features/todo/constants/emoji_keywords.md](features/todo/constants/emoji_keywords.md) | 3 | 2 |
| `lib/features/todo/constants/task_emojis.dart` | [features/todo/constants/task_emojis.md](features/todo/constants/task_emojis.md) | 1 | 1 |
| `lib/features/todo/models/task.dart` | [features/todo/models/task.md](features/todo/models/task.md) | 38 | 37 |
| `lib/features/todo/services/todo_insight_facts.dart` | [features/todo/services/todo_insight_facts.md](features/todo/services/todo_insight_facts.md) | 7 | 4 |
| `lib/features/todo/services/todo_storage.dart` | [features/todo/services/todo_storage.md](features/todo/services/todo_storage.md) | 57 | 56 |
| `lib/features/todo/utils/emoji_suggester.dart` | [features/todo/utils/emoji_suggester.md](features/todo/utils/emoji_suggester.md) | 9 | 5 |
| `lib/features/todo/views/todo_page.dart` | [features/todo/views/todo_page.md](features/todo/views/todo_page.md) | 74 | 34 |
| `lib/features/todo/widgets/add_task_dialog.dart` | [features/todo/widgets/add_task_dialog.md](features/todo/widgets/add_task_dialog.md) | 17 | 6 |
| `lib/features/todo/widgets/edit_task_dialog.dart` | [features/todo/widgets/edit_task_dialog.md](features/todo/widgets/edit_task_dialog.md) | 18 | 6 |
| `lib/features/todo/widgets/emoji_suggestion_row.dart` | [features/todo/widgets/emoji_suggestion_row.md](features/todo/widgets/emoji_suggestion_row.md) | 3 | 1 |
| `lib/features/todo/widgets/recurrence_picker.dart` | [features/todo/widgets/recurrence_picker.md](features/todo/widgets/recurrence_picker.md) | 4 | 0 |
| `lib/features/todo/widgets/task_section.dart` | [features/todo/widgets/task_section.md](features/todo/widgets/task_section.md) | 9 | 0 |

## features/weight/

| Source file | Page | Declarations | Tier A |
|---|---|---|---|
| `lib/features/weight/models/weight_record.dart` | [features/weight/models/weight_record.md](features/weight/models/weight_record.md) | 13 | 13 |
| `lib/features/weight/services/weight_insight_facts.dart` | [features/weight/services/weight_insight_facts.md](features/weight/services/weight_insight_facts.md) | 7 | 7 |
| `lib/features/weight/services/weight_storage.dart` | [features/weight/services/weight_storage.md](features/weight/services/weight_storage.md) | 6 | 5 |
| `lib/features/weight/views/weight_page.dart` | [features/weight/views/weight_page.md](features/weight/views/weight_page.md) | 73 | 33 |

## l10n/

`lib/l10n/` is already documented at [l10n/INDEX.md](l10n/INDEX.md) (generated code, not part of
the 1761 `Purpose:` blocks and 1833 table rows above).

## shared/

| Source file | Page | Declarations | Tier A |
|---|---|---|---|
| `lib/shared/providers/app_settings.dart` | [shared/providers/app_settings.md](shared/providers/app_settings.md) | 18 | 17 |
| `lib/shared/providers/intimacy_visibility.dart` | [shared/providers/intimacy_visibility.md](shared/providers/intimacy_visibility.md) | 6 | 5 |
| `lib/shared/services/auto_sync_service.dart` | [shared/services/auto_sync_service.md](shared/services/auto_sync_service.md) | 11 | 11 |
| `lib/shared/services/backup_service.dart` | [shared/services/backup_service.md](shared/services/backup_service.md) | 12 | 12 |
| `lib/shared/services/data_file_safety.dart` | [shared/services/data_file_safety.md](shared/services/data_file_safety.md) | 6 | 6 |
| `lib/shared/services/image_service.dart` | [shared/services/image_service.md](shared/services/image_service.md) | 6 | 6 |
| `lib/shared/services/import_export_service.dart` | [shared/services/import_export_service.md](shared/services/import_export_service.md) | 2 | 2 |
| `lib/shared/services/local_api_server.dart` | [shared/services/local_api_server.md](shared/services/local_api_server.md) | 67 | 62 |
| `lib/shared/services/mobile_notification_service.dart` | [shared/services/mobile_notification_service.md](shared/services/mobile_notification_service.md) | 9 | 7 |
| `lib/shared/services/reminder_service.dart` | [shared/services/reminder_service.md](shared/services/reminder_service.md) | 34 | 31 |
| `lib/shared/services/sync_merge.dart` | [shared/services/sync_merge.md](shared/services/sync_merge.md) | 7 | 7 |
| `lib/shared/services/sync_progress.dart` | [shared/services/sync_progress.md](shared/services/sync_progress.md) | 0 | 0 |
| `lib/shared/services/sync_wake_lock.dart` | [shared/services/sync_wake_lock.md](shared/services/sync_wake_lock.md) | 0 | 0 |
| `lib/shared/services/tray_service.dart` | [shared/services/tray_service.md](shared/services/tray_service.md) | 16 | 13 |
| `lib/shared/services/webdav_service.dart` | [shared/services/webdav_service.md](shared/services/webdav_service.md) | 12 | 12 |
| `lib/shared/utils/adaptive_layout.dart` | [shared/utils/adaptive_layout.md](shared/utils/adaptive_layout.md) | 58 | 18 |
| `lib/shared/utils/chinese_convert.dart` | [shared/utils/chinese_convert.md](shared/utils/chinese_convert.md) | 5 | 4 |
| `lib/shared/utils/chinese_convert_data.dart` | [shared/utils/chinese_convert_data.md](shared/utils/chinese_convert_data.md) | 2 | 0 |
| `lib/shared/utils/id_list_delta.dart` | [shared/utils/id_list_delta.md](shared/utils/id_list_delta.md) | 6 | 6 |
| `lib/shared/utils/json_preservation.dart` | [shared/utils/json_preservation.md](shared/utils/json_preservation.md) | 3 | 2 |
| `lib/shared/utils/status_colors.dart` | [shared/utils/status_colors.md](shared/utils/status_colors.md) | 3 | 2 |
| `lib/shared/utils/week_grouping.dart` | [shared/utils/week_grouping.md](shared/utils/week_grouping.md) | 18 | 18 |
| `lib/shared/views/backup_page.dart` | [shared/views/backup_page.md](shared/views/backup_page.md) | 17 | 2 |
| `lib/shared/views/webdav_config_page.dart` | [shared/views/webdav_config_page.md](shared/views/webdav_config_page.md) | 20 | 6 |
| `lib/shared/widgets/adaptive_tile_grid.dart` | [shared/widgets/adaptive_tile_grid.md](shared/widgets/adaptive_tile_grid.md) | 7 | 6 |
| `lib/shared/widgets/app_date_picker.dart` | [shared/widgets/app_date_picker.md](shared/widgets/app_date_picker.md) | 23 | 13 |
| `lib/shared/widgets/delete_confirm.dart` | [shared/widgets/delete_confirm.md](shared/widgets/delete_confirm.md) | 1 | 1 |
| `lib/shared/widgets/shell_scaffold.dart` | [shared/widgets/shell_scaffold.md](shared/widgets/shell_scaffold.md) | 10 | 4 |
| `lib/shared/widgets/stored_image.dart` | [shared/widgets/stored_image.md](shared/widgets/stored_image.md) | 5 | 2 |
| `lib/shared/widgets/sync_conflict_dialog.dart` | [shared/widgets/sync_conflict_dialog.md](shared/widgets/sync_conflict_dialog.md) | 6 | 0 |
| `lib/shared/widgets/unsaved_changes_guard.dart` | [shared/widgets/unsaved_changes_guard.md](shared/widgets/unsaved_changes_guard.md) | 10 | 5 |

## Area totals

| Area | Files | Declarations | Tier A | Tier B |
|---|---|---|---|---|
| Root (`lib/`) | 1 | 1 | 1 | 0 |
| `app/` | 5 | 30 | 25 | 5 |
| `features/ai/` | 11 | 93 | 22 | 71 |
| `features/finance/` | 25 | 421 | 205 | 216 |
| `features/intimacy/` | 15 | 438 | 210 | 228 |
| `features/profile/` | 8 | 65 | 30 | 35 |
| `features/settings/` | 3 | 37 | 8 | 29 |
| `features/todo/` | 12 | 240 | 152 | 88 |
| `features/weight/` | 4 | 99 | 58 | 41 |
| `shared/` | 32 | 403 | 280 | 123 |
| **Total** | **116** | **1819** | **987** | **832** |

Every row here is the arithmetic sum of the per-file rows above, re-derived in v1.5.0 and
adjusted for the pages v1.5.1 through v1.5.5 touched (v1.5.2 added `id_list_delta.md`; v1.5.3 and
v1.5.4 grew the Weight and Intimacy insight-fact pages; v1.5.5 added `thrust_timeline.md`,
`record_detail_page.md` and `thrust_timeline_chart.md`, grew `intimacy_record.md`,
`intimacy_page.md`, `timer_page.md` and `adaptive_layout.md`, and corrected the `adaptive_layout.md`
reconciliation note, which had claimed 17 `Purpose:` blocks and 56 rows against the file's 16 and
55). The file counts also match `find lib -name '*.dart' -not -path 'lib/l10n/*'` exactly — 113
source files, 113 pages, no file without a page and no page without a file. Version 1.6.0 then added the six `features/profile/` pages and `status_colors.md` and grew `theme.md`, `data_modules.md`, `shell_scaffold.md`, `app_settings.md`, `todo_storage.md` and `settings_page.md`; 

Version 1.6.1 then added `avatar_image.md` and `avatar_editor.md` and grew `shell_scaffold.md`, `adaptive_layout.md`, `app_settings.md`, `todo_storage.md`, `settings_page.md`, `profile_store.md`, `profile_provider.md` and `profile_header.md`: the `grep` count is now 1795 against 1865 table rows across 113 pages, one per source file.
Current per-file table sum: 116 files, 1819 declarations (987 Tier A, 832 Tier B).
