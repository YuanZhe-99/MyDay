# 数据格式

P3 公共资料实现与适配见 [shared-ui.md](shared-ui.md)，格式和模块顺序保持不变。

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
- **`Subscription`**：`id`、`name`、可选 `emoji`/`imagePath`、`startDate`、`trialDays`（默认 `0`）、`billingCycleType`、`billingInterval`（每 X 个月/年，默认 `1`）、`amount`、`currency`（默认 `'CNY'`）、`accountId`、可选 `categoryId`、`note`（默认 `''`）、`isActive`（默认 `true`）、可选 `cancelledAt`、可选 `cancelType`、可选持久化 `nextBillingDate`、`modifiedAt`。`firstBillingDate` = `startDate + trialDays`，按日历日计算（`addCalendarDays`，因此跨夏令时切换时保留开始时刻，v1.5.2）。`Subscription.nextBillingCursor(...)` 是模型和 `SubscriptionProcessor` 都使用的共享月末钳制游标推进——完整算法见 [订阅计费](algorithms/subscription-billing.md)。
- **`IconRef`**：`codePoint`（Material 图标码点）、`fontFamily`（默认 `'MaterialIcons'`）。因为图标数据从这两个字段动态重建，发布构建需要 `--no-tree-shake-icons`。

`FinanceStorage` 还在 `finance_data.json` 中持久化：账户列表（带可选免手续费标准）、分类、交易、订阅、默认币种、订阅提醒/排序、账户排序模式/自定义顺序、交易账户选择器的 `AccountPickerSettings` 和 `settingsModifiedAt`。

### `exchange_rates.json`

`ExchangeRateStorage` 保留基于快照的历史：`RateSnapshot` 映射（去重）、一个 `currentSnapshotId` 和 `lastFetchedAt`。它从旧的平铺 currency→rate 映射格式向前迁移。`ExchangeRateApi` 如何填充它、`balance_util.dart` 如何消费它见 [财务](features/finance.md)。

缺失或空白的文件读作默认快照。自 v1.5.2 起，既有文件无法读取或解析时抛出 `ExchangeRateStorageException`，而不是静默返回默认值；保存也拒绝覆盖这样的文件，因此快照历史绝不会被一个默认快照替换。财务页显示其数据不可读视图，汇率页显示带重试按钮的阻断式错误视图，本地 API 返回 `data_unreadable`。`FinanceStorage.load` 只在某个账户仍带有待迁移的旧版强制余额时才读取此文件，因此普通的财务加载不依赖它。磁盘格式不变。

## 亲密 — `intimacy_data.json`

来源：`lib/features/intimacy/models/intimacy_record.dart`。

- **`BodyProfile`**（性别中立、全部可选、按人）：`bustCm`、`waistCm`、`hipCm`（只对伴侣有意义——用户自己的胸/腰/臀在体重模块中）、`underbustCm`、`braStandard`（`'eu' | 'fr_es' | 'jp' | 'uk' | 'us' | 'au_nz'`，null = 显示默认）、`cycleEnabled`（默认 `false`）、`showCycleOnCalendar`（默认 `false`）、`erectLengthCm`、`baseCircumferenceCm`、`frontCircumferenceCm`（三个 PSI 输入）。全 null/全 false 的档案报告 `isEmpty == true` 并序列化为完全缺席的键（完全空的档案被丢弃而不是写为 `{}`）。
- **`CycleRecord`**：`id`、可选 `personId`（`null` = 用户，否则是 `Partner.id`）、`date`（本地日历日期，`yyyy-MM-dd` 字符串，无时间分量）、`modifiedAt`。只有增/删——没有编辑流程；按 id 合并使删除传播（见 [三方合并](algorithms/three-way-merge.md)）。
- **`Partner`**：`id`、`name`、可选 `emoji`/`imagePath`、可选 `startDate`/`endDate`（关系日期）、可选 `body`（`BodyProfile?`）、`modifiedAt`。身体档案在同步中与伴侣记录原子同行——身体编辑走 `Partner.copyWith`，它会 bump 整个伴侣记录的 `modifiedAt`。
- **`Toy`**：`id`、`name`、可选 `emoji`/`imagePath`、可选 `purchaseDate`/`retiredDate`、可选 `purchaseLink`、可选 `price`、`modifiedAt`。
- **`Position`**：`id`、`name`、可选 `emoji`、`modifiedAt`。
- **`IntimacyRecord`**：`id`、`type`（`'Regular'` 或 `'Solo'` 字符串）、可选 `location`、`isSolo`（默认 `false`）、可选 `partnerId`、`toyIds`/`positionIds`（`List<String>`）、`pleasureLevel`（1-5）、`duration`（以秒存储）、可选 `thrustCount`、`thrustCountUnit`（规范化为恰好 `1` 或 `100`；任何非 `1` 值被强转为 `100`）、可选 `thrustTimeline`（v1.5.5，见下）、`datetime`、可选 `notes`、`hadOrgasm`/`watchedPorn`/`usedCondom`（默认 `false`）、`modifiedAt`。`thrustCount` 为 null 时 `thrustCount`/`thrustCountUnit` 完全从 JSON 省略。计时器生成的记录的 `duration` 保留秒数（自 v1.5.5 起经记录对话框也是如此，除非编辑了其时长字段）。三个派生值在读取时计算且**绝不持久化**：`resolvedThrustCount`（`thrustCount * thrustCountUnit`，未记录正数时为 null）、`thrustsPerMinute`（该记录的抽插平均速率，`resolvedThrustCount / duration-in-minutes`，除非两个输入都在且时长非零，否则为 null），以及 `hasThrustTimeline`（v1.5.5：时间线至少有两个事件且总数等于 `resolvedThrustCount`，它控制图表的显示）。
- **`TimerHistoryEntry`**：`start`、`duration`（序列化为 `durationMs`）、`thrustCount`（钳制 `>= 0`）、`thrustCountUnit`（规范化为 `1` 或 `100`）、可选 `thrustTimeline`（v1.5.5）。读取存储 `end` 时间戳而非 `durationMs` 的旧条目，并派生 `duration = end - start`。
- **`IntimacyTimerSession`**：`firstStartedAt`、可选 `startedAt`、`accumulated`（当前运行段之前的已流逝时间，序列化为 `accumulatedMs`）、`running`、`thrustCount`、`thrustCountUnit`、可选 `thrustTimeline`（v1.5.5）。`elapsedAt(now)` 暂停时返回 `accumulated`，运行时返回 `accumulated + (now - startedAt)`——因此运行中会话的已流逝时间总是从挂钟时间派生，绝不来自存储的"当前"时长。
- **`thrustTimeline`**（v1.5.5），位于上面三个模型上：计时器抽插计数按钮的各次按下，形如 `[[elapsedMs, delta], ...]`——整数对，最早的在前，`elapsedMs >= 0` 是按下时以毫秒计的秒表时间，`delta > 0` 是它增加的次数。例如 `"thrustTimeline": [[61000, 100], [95500, 50], [130250, 10]]`。其总数（各 delta 之和）预期等于该项的实际计数（`thrustCount * thrustCountUnit`）：两者不同时 `AddRecordDialog` 在保存时丢弃时间线，计时器页在恢复时重新植入，但读取方不强制。没有时间线时该键被**省略**（空时间线规范化为缺失），因此从未使用 v1.5.5 计时器的数据序列化结果与以前完全相同，WebDAV golden 转录逐字节不变。读取是容错的（`ThrustTimeline.fromJson`）：不是两个数字、或时间为负、或 delta 非正的对被跳过，其余按时间排序，没有任何可用内容时读为缺失——损坏的时间线绝不会让文件不可读。单事件时间线是有效的（恢复后又保存的 v1.5.5 之前的会话就带一个），但不绘制图表。`thrustTimeline` 是记录、计时器历史和计时器会话保留模式（`json_preservation.dart`）中的已知键。v1.5.5 之前的构建不认识该键，会把它作为未知字段向前携带——在它们自己的保存中（从磁盘上的文件保留）以及经同步——因此数据经过较旧设备的往返仍能保存下来。这样的构建仍可能修改它旁边的计数；计时器页会在恢复时重新植入，但以这种方式编辑过的记录会保留一条总数不再与计数匹配的时间线。此时 `hasThrustTimeline` 返回 false，详情页隐藏这条过时的曲线，下一次经 `AddRecordDialog` 保存时会丢弃该时间线。
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

总是留在默认应用目录（绝不随自定义存储路径移动）。保存：自定义存储路径、亲密可见性开关、主题、语言区域、周起始日、托盘设置、备份设置、本地 API 设置（`apiPort`、`apiListenAddress`、`apiEnabled`、`apiUsername`、`apiPassword`）、今天已触发的桌面提醒键（`reminderNotifiedKeys`）、仅本地的亲密计时器保持屏幕唤醒偏好（`intimacyTimerKeepScreenAwake`）、仅本地的体重同步警告退出（`intimacyBodyWeightSyncWarningDisabled`）、四个设备本地的列表列数偏好（`todoSectionColumns`、`financeListColumns`、`weightListColumns`、`intimacyListColumns`）、端侧 AI 开关（`onDeviceAiEnabled`、`onDeviceAiPreferFast`，v1.5.0）、界面风格（`uiStyle`，v1.6.0）以及两个导航位置键 `navPlacement` 和 `navRailRight`（v1.6.1）。

这两个端侧 AI 键只在为 `true` 时写入，关闭时移除，因此键不存在即表示关闭。它们只存在于本设备，因为是否有模型是设备的属性——见 [on-device-ai.md](on-device-ai.md)。

`navPlacement`（`"sideOnWide"` 或 `"side"`：仅宽窗口用侧边导航栏，或任何地方都用；默认的“任何窗口都用底栏”会移除该键；未知值按默认读取）和 `navRailRight`（侧边导航栏位于右侧；只写为 `true`）仅限本设备、从不同步——它们描述的是设备的窗口，与列数偏好一样。见 [adaptive-layout.md](adaptive-layout.md)。

这四个列数偏好存放在这里、因而从不同步，是刻意的：窗口尺寸是设备的属性，不是账户的属性——见 [自适应布局](adaptive-layout.md)。在用户固定列数之前每一个都不存在，存在时保存 1..4 的整数；其余情况（含不存在）一律读作「自动」。

自 v1.5.2 起，对此文件的每次写入都是一次读取-合并-写入，由 `TodoStorage` 通过同一个配置写队列串行执行，并以原子写入（先写临时文件再重命名）落盘。`writeConfig` 只接收要修改的键（值为 `null` 表示移除该键），因此同时保存的两项设置不会再互相丢失。写入拒绝在不是可解析 JSON 对象的既有文件之上构建，改为抛出 `TodoStorageException`，因此 `storagePath` 和 API 凭据绝不会被一个近乎为空的映射替换；缺失或空白的文件视为 `{}`。经 `TodoStorage.readConfig()` 的读取保持宽松，对不可读的文件返回 `{}`。格式不变。

## 持久化数据清单 <a id="persisted-data-inventory"></a>

从 `AGENTS.md` 复制。默认应用数据目录是桌面上的 `Documents/MyDay/` 或移动端的平台应用文档目录；桌面用户可以选择自定义存储路径，但 `storage_config.json` 总是留在默认应用目录。

| 数据 | 文件 | 同步 | 备注 |
| --- | --- | --- | --- |
| 核心偏好 | `storage_config.json` | 否 | 自定义路径、亲密可见性、主题、语言区域、周起始日、托盘、备份、本地 API 设置、今天已触发的桌面提醒键（`reminderNotifiedKeys`）、仅本地的亲密计时器保持屏幕唤醒偏好（`intimacyTimerKeepScreenAwake`）、仅本地的体重同步警告退出（`intimacyBodyWeightSyncWarningDisabled`）、设备本地的列表列数偏好（`todoSectionColumns`、`financeListColumns`、`weightListColumns`、`intimacyListColumns`）、端侧 AI 开关（`onDeviceAiEnabled`、`onDeviceAiPreferFast`）、界面风格（`uiStyle`，1.6.0：仅在选择 Material 3 时写为 `"material3"`；缺省表示 Expressive，即默认风格，同时显示悬浮导航栏）、导航位置（`navPlacement`：`"sideOnWide"` 或 `"side"`，以及 `navRailRight: true`，1.6.1；缺省表示默认：任何窗口都用底栏，显示侧边导航栏时位于左侧） |
| 待办 | `todo_data.json` | 是 | 任务、每日模板、完成日志、每日评分日志、提醒、任务排序/自定义顺序 |
| 财务 | `finance_data.json` | 是 | 账户含可选免手续费标准、分类、交易、订阅、财务设置、交易账户选择器设置 |
| 汇率 | `exchange_rates.json` | 是 | 汇率快照和 `lastFetchedAt` |
| 亲密 | `intimacy_data.json` | 是 | 伴侣含可选身体档案、玩具、姿势、记录、含抽插次数的计时器历史/会话、用户身体档案（`userBody` + `userBodyModifiedAt`）、周期记录、排序设置、趋势图视图设置（`chartSettings`） |
| 体重 | `weight_data.json` | 是 | 身高、含可选胸/腰/臀 cm 字段的记录、提醒、宽限窗口 |
| 个人资料（名称和头像） | `profile.json` | 是 | 自 1.6.0 起：用户的名称和头像路径，各带自己的时间戳；按字段后写者胜；无冲突；仅在首次设置时创建 |
| WebDAV 配置 | `webdav_config.json` | 否 | 用户服务器配置和凭据；随自定义存储路径移动 |
| 同步基线 | `.sync_base/*.json` | 否 | 三方合并的上次同步快照 |
| 图像 | `images/*` | 是 | 引用的财务/亲密图像以及（自 1.6.0 起）个人资料头像（`images/avatar_<uuid>.jpg`）同步；备份含图像。文件为任意图像格式的 `<uuid><ext>`，包括 `.svg`（选择预设时复制的内置银行标志，v1.4.5）；格式不变 |
| 备份 | `backups/backup_*.json` | 否 | 本地恢复捆绑；v2 捆绑引用去重后的图像 blob |
| 备份图像 blob | `backups/blobs/` | 否 | 内容寻址（`sha256`）、跨备份共享、引用计数 GC |
| 端侧 AI 洞察 | `ai_insights.json` | 否 | 生成的洞察卡片的逐设备缓存（v1.5.0）；从不同步、备份或导出；可重建，因此不可读的文件读作空 |

`TodoStorage.setStoragePath()` 通过 `migrateStorageContents` 移动旧数据文件夹中的**一切**——数据文件、`webdav_config.json`、`ai_insights.json`，以及 `images/`、`backups/` 和 `.sync_base/` 目录（先复制后删除；目标位置已存在的条目胜出并保持不动）。只跳过 `storage_config.json`：它总是留在默认应用目录，因为它保存的正是自定义路径本身。

## `profile.json`


`profile.json`（1.6.0）是第六个已注册的模块，因此它同样会同步、会备份、包含在 ZIP 导出中，并有自己的
`.sync_base/profile.json`。它保存用户的名称和头像（见 [`features/profile.md`](features/profile.md)）：

```json
{
  "version": 1,
  "displayName": "Yuan",
  "displayNameUpdatedAt": "2026-10-01T14:06:42.530801Z",
  "avatar": "images/avatar_2953ac52-337e-4271-a8e1-bcd97ee416ba.jpg",
  "avatarUpdatedAt": "2026-10-01T14:08:59.163627Z"
}
```

- `displayName` / `displayNameUpdatedAt`——名称及其最近一次更改的时间（UTC）。保存时会去除首尾空白；清除它会写入 `"displayName": null` 和新的时间戳。
- `avatar` / `avatarUpdatedAt`——头像相对于数据目录的路径（`images/avatar_<uuid>.jpg`，512 x 512 的 JPEG）及其最近一次更改的时间（UTC）。已移除的头像写成带时间戳的显式 `"avatar": null`，使移除操作得以同步。
- 字段只有在有时间戳后才会写出；没有时间戳的字段表示“从未设置”，在合并中总是输给已设置的一方。每个字段按后写者胜独立合并，互不影响——见 [`sync.md`](sync.md#个人资料文件)。未知键会保留。`version` 为 `1`。
- 头像图片是 `images/` 中的普通文件，因此它通过引擎的仅引用添加式图像阶段同步（该模块通过 `profileReferencedImages` 报告它），并与其他图片一起备份和导出。每个新头像都使用全新的文件名，因为图像同步从不覆盖已存在的文件；被替换的头像只在本地删除，所以旧头像会留在 WebDAV 服务器和其他设备上。
- 1.6.0 之前的构建从不请求 `profile.json`，因此它不会影响它们。


## `ai_insights.json`

端侧 AI 洞察缓存（v1.5.0），通过 `AiInsightsCache` 以其自己的写队列原子写入。它**不是**已登记的数据模块：从不同步，从不出现在备份捆绑或 ZIP 导出中，也没有保留模式。与数据文件不同，不可读或格式错误的文件读作空——它是缓存，丢失它的代价只是每张卡片重新生成一次。设置中的*清除已生成的洞察*会删除它。

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

- `insights` 下的键是 `todo`、`finance`、`weight`、`intimacy`。未知键和格式错误的条目在读取时丢弃。
- `fingerprint` 是 [on-device-ai.md](on-device-ai.md#cache-and-fingerprint) 中描述的十六进制 SHA-256；卡片只在它变化时重新生成。
- `lines` 按槽位顺序保存经过校验的句子，`slots` 保存每句对应的槽位 id，因此即使前面的某个槽位被丢弃，卡片也能把各行归到对应的分区标题下。
- `status` 为 `ok`，或在模型拒绝（`guardrail`）或无法使用该语言写作时为 `skipped`；跳过的条目没有行，在指纹变化之前不会重试。
- `generatedAt` 是 UTC。

## 相关页面

- [架构](architecture.md) — 管辖上述一切的存储/写队列/UTC 时间戳规则。
- [WebDAV 同步](sync.md) 和 [三方合并](algorithms/three-way-merge.md) — 每个文件如何跨设备合并。
- [备份与恢复](backup-restore.md) — 这些文件如何在备份中打包和校验。
