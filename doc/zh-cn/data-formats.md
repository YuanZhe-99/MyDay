# 数据格式

本页记录每个持久化模型的字段级形态、`storage_config.json` 和完整持久化数据清单。字段列表直接读取自每个小节下列出的模型源文件。适用于所有这些文件的存储/写队列/UTC 时间戳规则见 [架构](architecture.md)，它们如何跨设备合并见 [WebDAV 同步](sync.md) / [三方合并](algorithms/three-way-merge.md)。

## 待办 — `todo_data.json`

来源：`lib/features/todo/models/task.dart`。

- **`TaskType`** 枚举：`daily`、`routineOnce`、`workOnce`。
- **`RecurrenceType`** 枚举：`everyNDays`、`monthlyOnDay`、`yearlyOnMonthDay`。
- **`TaskRecurrence`**：`type`（`RecurrenceType`）、`intervalDays`（`everyNDays` 用）、`dayOfMonth`（1-31，`monthlyOnDay`/`yearlyOnMonthDay` 用）、`monthOfYear`（1-12，`yearlyOnMonthDay` 用）。`nextDate(from)` 计算下一次出现，把 day-of-month 钳制到目标月的实际长度。
- **`SubTask`**：`id`、`title`、`isCompleted`、`modifiedAt`。
- **`Task`**：`id`、`title`、可选 `note`、可选 `emoji`、`type`（`TaskType`）、`isCompleted`、可选 `reminderTime`、`subtasks`（`List<SubTask>`）、`createdDate`、可选 `completedDate`、可选 `scheduledDate`（仅一次性任务——它被排定的日期；每日模板为 null）、可选 `deletedDate`（仅每日模板——软删除日期；null 表示激活）、可选 `startDate`（仅每日模板——模板变为激活的日期，默认为创建时选中的日期）、可选 `dueDate`（仅一次性任务）、可选 `recurrence`（`TaskRecurrence?`，仅一次性任务——完成时提示下一次出现）、`modifiedAt`。
- **`DailyCompletionLog`**：两个以 `yyyy-MM-dd` 日期字符串为键的内部映射——`_log: Map<String, Set<String>>`（每天已完成的待办 ID）和 `_subLog: Map<String, Set<String>>`（每天已完成的子任务 ID）。序列化为 `{"tasks": {...}, "subtasks": {...}}`；读取时也接受旧平铺映射格式（无子任务跟踪的裸 date→taskIds 映射）。`DailyCompletionLog.merge(a, b)` 对来自两个日志的每天已完成 ID 集求并集——见 [三方合并](algorithms/three-way-merge.md)。
- **`DailyScoreEntry`**：`score`（经 `DailyScoreLog.normalizeScore` 钳制 -5..5）、`modifiedAt`。
- **`DailyScoreLog`**：以 `yyyy-MM-dd` 为键的 `Map<String, DailyScoreEntry>`；`minScore = -5`、`maxScore = 5`；缺失日期读作分数 `0`，但显式零条目被保留（因此重置为零仍会同步）。`DailyScoreLog.merge(local, remote)` 按天选取 `modifiedAt` 更新的那一侧（平局偏向本地）。

`TodoStorage` 还在 `todo_data.json` 中持久化：每日模板、一次性任务、完成日志、每日评分日志、早晨/完成提醒小时+分钟、任务排序模式/逐小节自定义顺序和 `settingsModifiedAt`。

## 财务 — `finance_data.json`

来源：`lib/features/finance/models/finance.dart`。

- **`AccountType`** 枚举：`fund`、`credit`、`recharge`、`financial`。
- **`AccountPickerSettings`**：`sortMode`（`'name'` 或 `'custom'`）、`groupByType`、`customOrder`（`List<String>`）、`moreAccountIds`（`List<String>`）。
- **`Account`**：`id`、`type`（`AccountType`）、`bankOrApp`、`name`、`currency`（默认 `'CNY'`）、可选 `cardNumber`/`expiryDate`/`securityCode`、可选 `emoji`/`imagePath`、可选 `feeWaiverMinimumBalance` 和 `feeWaiverMonthlyDeposit`（替代性免手续费标准——两者都出现时满足任一即免手续费）、旧 `forcedBalance`/`forcedBalanceDate`（新版余额只从交易计算；在 UI 中设置"当前余额"会创建一笔收支调整交易，然后纯粹为旧版兼容存储哨兵 `forcedBalance: 0` + `forcedBalanceDate: 1970-01-01T00:00:00.000Z`——见 [财务](features/finance.md)）、`modifiedAt`。
- **`TransactionType`** 枚举：`expense`、`income`、`transfer`。
- **`Transaction`**：`id`、`type`（`TransactionType`）、`amount`、`currency`（默认 `'CNY'`）、可选 `rateSnapshotId`（引用记录时捕获的历史 `RateSnapshot`）、`accountId`、可选 `toAccountId`/`toAmount`/`toCurrency`（跨币种转账的转账目标账户/金额/币种）、可选 `categoryId`、可选 `subscriptionId`、`note`（默认 `''`）、`date`、`modifiedAt`。
- **`Category`**：`id`、`name`、`icon`（`IconRef`）、可选 `emoji`、`type`（`TransactionType`——支持转账分类）、`modifiedAt`。
- **`BillingCycleType`** 枚举：`monthly`、`yearly`。**`CancelType`** 枚举：`immediate`、`atExpiry`。
- **`Subscription`**：`id`、`name`、可选 `emoji`/`imagePath`、`startDate`、`trialDays`（默认 `0`）、`billingCycleType`、`billingInterval`（每 X 个月/年，默认 `1`）、`amount`、`currency`（默认 `'CNY'`）、`accountId`、可选 `categoryId`、`note`（默认 `''`）、`isActive`（默认 `true`）、可选 `cancelledAt`、可选 `cancelType`、可选持久化 `nextBillingDate`、`modifiedAt`。`firstBillingDate` = `startDate + trialDays`。`Subscription.nextBillingCursor(...)` 是模型和 `SubscriptionProcessor` 都使用的共享月末钳制游标推进——完整算法见 [订阅计费](algorithms/subscription-billing.md)。
- **`IconRef`**：`codePoint`（Material 图标码点）、`fontFamily`（默认 `'MaterialIcons'`）。因为图标数据从这两个字段动态重建，发布构建需要 `--no-tree-shake-icons`。

`FinanceStorage` 还在 `finance_data.json` 中持久化：账户列表（带可选免手续费标准）、分类、交易、订阅、默认币种、订阅提醒/排序、账户排序模式/自定义顺序、交易账户选择器的 `AccountPickerSettings` 和 `settingsModifiedAt`。

### `exchange_rates.json`

`ExchangeRateStorage` 保留基于快照的历史：`RateSnapshot` 映射（去重）、一个 `currentSnapshotId` 和 `lastFetchedAt`。它从旧的平铺 currency→rate 映射格式向前迁移。`ExchangeRateApi` 如何填充它、`balance_util.dart` 如何消费它见 [财务](features/finance.md)。

## 亲密 — `intimacy_data.json`

来源：`lib/features/intimacy/models/intimacy_record.dart`。

- **`BodyProfile`**（性别中立、全部可选、按人）：`bustCm`、`waistCm`、`hipCm`（只对伴侣有意义——用户自己的胸/腰/臀在体重模块中）、`underbustCm`、`braStandard`（`'eu' | 'fr_es' | 'jp' | 'uk' | 'us' | 'au_nz'`，null = 显示默认）、`cycleEnabled`（默认 `false`）、`showCycleOnCalendar`（默认 `false`）、`erectLengthCm`、`baseCircumferenceCm`、`frontCircumferenceCm`（三个 PSI 输入）。全 null/全 false 的档案报告 `isEmpty == true` 并序列化为完全缺席的键（完全空的档案被丢弃而不是写为 `{}`）。
- **`CycleRecord`**：`id`、可选 `personId`（`null` = 用户，否则是 `Partner.id`）、`date`（本地日历日期，`yyyy-MM-dd` 字符串，无时间分量）、`modifiedAt`。只有增/删——没有编辑流程；按 id 合并使删除传播（见 [三方合并](algorithms/three-way-merge.md)）。
- **`Partner`**：`id`、`name`、可选 `emoji`/`imagePath`、可选 `startDate`/`endDate`（关系日期）、可选 `body`（`BodyProfile?`）、`modifiedAt`。身体档案在同步中与伴侣记录原子同行——身体编辑走 `Partner.copyWith`，它会 bump 整个伴侣记录的 `modifiedAt`。
- **`Toy`**：`id`、`name`、可选 `emoji`/`imagePath`、可选 `purchaseDate`/`retiredDate`、可选 `purchaseLink`、可选 `price`、`modifiedAt`。
- **`Position`**：`id`、`name`、可选 `emoji`、`modifiedAt`。
- **`IntimacyRecord`**：`id`、`type`（`'Regular'` 或 `'Solo'` 字符串）、可选 `location`、`isSolo`（默认 `false`）、可选 `partnerId`、`toyIds`/`positionIds`（`List<String>`）、`pleasureLevel`（1-5）、`duration`（以秒存储）、可选 `thrustCount`、`thrustCountUnit`（规范化为恰好 `1` 或 `100`；任何非 `1` 值被强转为 `100`）、`datetime`、可选 `notes`、`hadOrgasm`/`watchedPorn`/`usedCondom`（默认 `false`）、`modifiedAt`。`thrustCount` 为 null 时 `thrustCount`/`thrustCountUnit` 完全从 JSON 省略。两个派生值在读取时计算且**绝不持久化**：`resolvedThrustCount`（`thrustCount * thrustCountUnit`，未记录正数时为 null）和 `thrustsPerMinute`（该记录的抽插平均速率，`resolvedThrustCount / duration-in-minutes`，除非两个输入都在且时长非零，否则为 null）。
- **`TimerHistoryEntry`**：`start`、`duration`（序列化为 `durationMs`）、`thrustCount`（钳制 `>= 0`）、`thrustCountUnit`（规范化为 `1` 或 `100`）。读取存储 `end` 时间戳而非 `durationMs` 的旧条目，并派生 `duration = end - start`。
- **`IntimacyTimerSession`**：`firstStartedAt`、可选 `startedAt`、`accumulated`（当前运行段之前的已流逝时间，序列化为 `accumulatedMs`）、`running`、`thrustCount`、`thrustCountUnit`。`elapsedAt(now)` 暂停时返回 `accumulated`，运行时返回 `accumulated + (now - startedAt)`——因此运行中会话的已流逝时间总是从挂钟时间派生，绝不来自存储的"当前"时长。
- **`IntimacyData`**：`partners`、`toys`、`positions`、`records`、`timerHistory`（`List<TimerHistoryEntry>`）、可选 `timerSession`、`timerSessionModifiedAt`（自己的 LWW 时间戳，epoch-UTC 默认）、可选 `userBody`（`BodyProfile?`——用户自己的档案，只在非 null 且非空时序列化）、`userBodyModifiedAt`（自己的 LWW 时间戳，独立于 `settingsModifiedAt`）、`cycleRecords`（用户和伴侣的 `List<CycleRecord>`）、`timerHistoryRetentionDays`（`null` = 永久，否则 `3`/`7`/`14`）、`partnerSortModes`/`partnerCustomOrders`/`toySortModes`/`toyCustomOrders`（逐列表排序设置）、可选 `chartSettings`（`IntimacyChartSettings?`）、`settingsModifiedAt`。
- **`IntimacyChartSettings`**（v1.3.2）：整合趋势图的视图偏好，由亲密主页和每个伴侣/玩具详情页共享。两个键：`metrics`（`List<String>`，默认 `['pleasure', 'duration', 'thrustRate']`；可识别 id 是 `pleasure`、`frequency`、`duration`、`thrustCount`、`thrustRate`）和 `range`（`String`，默认 `'3m'`；可识别 id 是 `1w`、`1m`、`3m`、`6m`、`1y`、`all`）。标识符是**字符串，绝不是枚举索引**，并逐字往返——不识别某 id 的构建把它保留在列表中而不是丢弃，因此经旧设备同步是无损的。不可识别的 id 只是不绘制；若没有可识别的东西留下，图表渲染默认值。整个对象在用户首次更改选择之前从 JSON 省略，这正是 v1.3.2 添加它时让 WebDAV golden 转录保持逐字节相同的原因。

## 体重 — `weight_data.json`

来源：`lib/features/weight/models/weight_record.dart`。

- **`WeightRecord`**：`id`、`weight`（kg）、可选 `bodyFat`（百分比）、可选 `bustCm`/`waistCm`/`hipCm`（cm）、`datetime`、可选 `notes`、`modifiedAt`。
- **`WeightData`**：可选 `height`（cm）、`records`（`List<WeightRecord>`）、`reminderMode`（`'none' | 'once' | 'twice'`）、可选 `morningHour`/`morningMinute`/`eveningHour`/`eveningMinute`、`reminderGraceMinutes`（默认 `180`）、`settingsModifiedAt`。
- `WeightData.calculateBMI(heightCm, weightKg)` 在 `heightCm` 为 null 或 `<= 0` 时返回 `null`，否则 `weightKg / (heightM * heightM)`。
- `WeightData.calculateWaistHipRatio(waistCm, hipCm)` 除非两者都为正，否则返回 `null`，否则 `waistCm / hipCm`。
- `WeightData.effectiveMeasurementsUpTo(records, at)` 和 `effectiveMeasurementTimeline(records)` 按时间顺序（平局按 `modifiedAt` 再按 `id` 打破）遍历记录，并独立向前携带胸/腰/臀每个的最新*正*值——字段空白或为零/负的记录为显示目的继承前一条记录的值，而绝不把该继承值写回记录本身。见 [体重](features/weight.md)。

## `storage_config.json`

总是留在默认应用目录（绝不随自定义存储路径移动）。保存：自定义存储路径、亲密可见性开关、主题、语言区域、周起始日、托盘设置、备份设置、本地 API 设置（`apiPort`、`apiListenAddress`、`apiEnabled`、`apiUsername`、`apiPassword`）、今天已触发的桌面提醒键（`reminderNotifiedKeys`）、仅本地的亲密计时器保持屏幕唤醒偏好（`intimacyTimerKeepScreenAwake`）和仅本地的体重同步警告退出（`intimacyBodyWeightSyncWarningDisabled`）。

## 持久化数据清单

从 `AGENTS.md` 复制。默认应用数据目录是桌面上的 `Documents/MyDay/` 或移动端的平台应用文档目录；桌面用户可以选择自定义存储路径，但 `storage_config.json` 总是留在默认应用目录。

| 数据 | 文件 | 同步 | 备注 |
| --- | --- | --- | --- |
| 核心偏好 | `storage_config.json` | 否 | 自定义路径、亲密可见性、主题、语言区域、周起始日、托盘、备份、本地 API 设置、今天已触发的桌面提醒键（`reminderNotifiedKeys`）、仅本地的亲密计时器保持屏幕唤醒偏好（`intimacyTimerKeepScreenAwake`）、仅本地的体重同步警告退出（`intimacyBodyWeightSyncWarningDisabled`） |
| 待办 | `todo_data.json` | 是 | 任务、每日模板、完成日志、每日评分日志、提醒、任务排序/自定义顺序 |
| 财务 | `finance_data.json` | 是 | 账户含可选免手续费标准、分类、交易、订阅、财务设置、交易账户选择器设置 |
| 汇率 | `exchange_rates.json` | 是 | 汇率快照和 `lastFetchedAt` |
| 亲密 | `intimacy_data.json` | 是 | 伴侣含可选身体档案、玩具、姿势、记录、含抽插次数的计时器历史/会话、用户身体档案（`userBody` + `userBodyModifiedAt`）、周期记录、排序设置、趋势图视图设置（`chartSettings`） |
| 体重 | `weight_data.json` | 是 | 身高、含可选胸/腰/臀 cm 字段的记录、提醒、宽限窗口 |
| WebDAV 配置 | `webdav_config.json` | 否 | 用户服务器配置和凭据；随自定义存储路径移动 |
| 同步基线 | `.sync_base/*.json` | 否 | 三方合并的上次同步快照 |
| 图像 | `images/*` | 是 | 引用的财务/亲密图像同步；备份含图像 |
| 备份 | `backups/backup_*.json` | 否 | 本地恢复捆绑；v2 捆绑引用去重后的图像 blob |
| 备份图像 blob | `backups/blobs/` | 否 | 内容寻址（`sha256`）、跨备份共享、引用计数 GC |

由 `TodoStorage.setStoragePath()` 移动的文件：`todo_data.json`、`finance_data.json`、`exchange_rates.json`、`intimacy_data.json`、`weight_data.json` 和 `webdav_config.json`。`storage_config.json` 总是留在默认应用目录。`images/`、`backups/` 和 `.sync_base/` 等目录不被那个文件列表移动。

## 相关页面

- [架构](architecture.md) — 管辖上述一切的存储/写队列/UTC 时间戳规则。
- [WebDAV 同步](sync.md) 和 [三方合并](algorithms/three-way-merge.md) — 每个文件如何跨设备合并。
- [备份与恢复](backup-restore.md) — 这些文件如何在备份中打包和校验。
