# 桌面小组件

自 1.8.3 起，MyDay!!!!! 在 Android 和 iOS 上提供五种桌面小组件类型：**待办**、**体重**、**财务**、**私密**（亲密模块）和**计时器**（亲密秒表）。桌面版没有小组件界面。它们全部构建在共享的 MyApps-Widget 库之上（`packages/myapps_widget`，见其 `doc/en-us/`），与 MyAnime 使用的是同一个库：应用为每种类型计算一份小快照，原生小组件只负责渲染，交互控件上的点按则进入队列，由应用来应用。

| 类型 | Android provider | iOS 小组件（尺寸族） | 默认隐私 |
|---|---|---|---|
| `myday.todo` | `TodoWidgetProvider`（2×2，可调整到 4×4）、`TodoStripWidgetProvider`（2×1） | `MyDayTodoWidget`（小、中、大、`accessoryRectangular`） | `normal` |
| `myday.weight` | `WeightWidgetProvider`（2×2）、`WeightStripWidgetProvider`（2×1） | `MyDayWeightWidget`（小） | `sensitive` |
| `myday.finance` | `FinanceWidgetProvider`（2×2，从 250 dp 起使用宽布局） | `MyDayFinanceWidget`（小、中） | `sensitive` |
| `myday.intimacy` | `IntimacyWidgetProvider`（2×2） | `MyDayIntimacyWidget`（小） | `sensitive` |
| `myday.timer` | `TimerWidgetProvider`（2×2）、`TimerStripWidgetProvider`（2×1） | `MyDayTimerWidget`（小） | `sensitive` |

Android provider 位于 `android/app/src/main/kotlin/com/yuanzhe/my_day/widget/`；iOS 扩展是 `ios/MyDayWidgets/` 中的 `MyDayWidgets` target。只有待办类型提供锁屏尺寸族，因为共享规则禁止默认隐私不是 `normal` 的类型使用锁屏尺寸族。

## 显示内容

**待办。** 标题栏显示日期和*新建*按钮。2×2 尺寸显示未完成任务数、一条进度条和最多三行；4×2 显示两列行，外加明天已排期的任务和当日评分；4×4 最多显示十行。行按当天的阅读顺序排序：先是逾期任务，然后是按提醒时间排列的未完成任务（没有时间的排最后；时间相同时保持每日 → 日常 → 工作的分区顺序），最后是已完成任务，它们以删除线形式保持可见。每行都有一个复选框。2×1 条形尺寸和 iOS 锁屏矩形显示未完成数和下一个带提醒时间的任务。

**体重。** 最新体重、30 天内的变化、设置了身高时的 BMI、最近 30 天的迷你折线图，以及最新记录的时间。今天没有记录且早间提醒时间已过（提醒模式不是 `none`）时，底部显示*今天未记录*。条形尺寸显示最新体重和相对上一条记录的变化。

**财务。** 以默认货币显示本月支出、收入和结余（与财务首页摘要的合计相同），以及最多三个将在 7 天内扣费的订阅。宽布局另外显示支出最多的分类及其占比。

**私密。** 距上次记录的天数、本月次数和平均时长，以及——在用户自己的周期跟踪启用时——距下次预测经期的天数。标题使用中性的*私密*一词，而不是模块名称。

**计时器。** 亲密计时器的秒表状态：运行中（已用时间由原生端递增，Android 上是 `Chronometer`，iOS 上是 `Text(_:style: .timer)`）、已暂停，或空闲并显示上一次会话。按钮：*开始* / *暂停* / *继续*、**+100**（把计数加 100，在那一刻记录为一个抽插时间线事件），以及*完成*，它打开计时器页面以保存记录。

每种类型都显示一个*新建* / *记录* / *添加*按钮，在对应的添加对话框上打开应用。点按其他位置会打开该模块的标签页。

### 平台差异

| 主题 | Android | iOS |
|---|---|---|
| 添加按钮 | 所有尺寸 | 仅中、大尺寸；`systemSmall` 不支持 `Link`，因此小尺寸小组件打开标签页 |
| 待办 4×2 / 中尺寸 | 从 250 dp 起有右列：明天已排期的任务和当日评分 | 右列接续行，然后是明天；计数和评分位于标题栏下方 |
| 待办条形 / 锁屏 | 时间在当前或之后的下一个未完成任务（否则取第一个有时间的，再否则取第一个未完成的），然后是「时间 · 剩 N 项」 | 下一个有时间的未完成任务，否则取第一个未完成任务 |
| 计时器条形 | 播放/暂停方块、时钟、状态和计数、**+100**；没有*完成*（点按打开计时器页面） | ——（仅小尺寸）；整个小组件打开计时器页面，*完成*在那里就是这样实现的 |
| 月份变化后的财务 | 上一份快照的合计及其月份名；支出最多的分类只在当月显示 | 应用运行前显示*打开 MyDay 以更新* |
| 体重、财务尺寸 | 账单显示一行，高度达到 220 dp 时显示三行 | 小、中尺寸族 |

计时器的*上次*一行用上次会话的本地短日期填充其 `{n}`（或使用*今天*的措辞）。在*隐藏数值*下，秒表绘制为 `••:••` 且不计时，体重迷你折线图和待办进度条为空白。

### 隐私与模块开关

**设置 › 桌面小组件**（仅 Android 和 iOS）为每种类型提供一个小节，包含文字大小滑块（90%–150%）、隐私选项和预览：

| 选项 | 存储值 | 信封 `privacy` | 效果 |
|---|---|---|---|
| 显示 | `show` | 该类型的默认值 | 显示数值；在 iOS 上，设备锁定时 `sensitive` 类型会被遮挡 |
| 隐藏数值 | `maskValues` | `sensitive` | 数字和金额绘制为 `••`，保留标题 |
| 只显示图标 | `iconOnly` | `hidden` | 带应用图标的中性占位 |

除**私密**默认*隐藏数值*外，其他类型默认都是*显示*。

私密和计时器类型只在亲密模块可见时存在（设置 › 隐私）。隐藏该模块会清除这两个信封，因此已放置的小组件回退到中性占位，桌面上不会留下任何亲密数据；再次显示时会重新发布它们。设置页面中的亲密小节随模块一起隐藏。

## 数据流

小组件从不读取 MyDay 的数据文件。`HomeWidgetService`（`lib/shared/services/home_widget_service.dart`）使用 `lib/shared/services/home_widget_payloads.dart` 中的纯构建函数为每种类型构建一个信封，并通过 `MyAppsWidgetBridge` 发布：

- Android 把它存入私有 `myapps_widget` 偏好设置的 `envelope.<kind>` 下，并重绘该类型的 provider。
- iOS 把它存入 `group.com.yuanzhe.myDay` App Group 的 `myapps_widget.envelope.<kind>` 下，并重新加载该类型的时间线。

`HomeWidgetService.notifyDataChanged()` 在以下事件中最后一次发生的 2 秒后安排刷新每种类型：

- 待办、体重、财务或亲密数据保存，包括本地 API 写入；
- 同步下载或备份恢复（`AutoSyncService` 的本地数据变更回调）；
- 应用恢复到前台；
- 语言、亲密可见性或任意小组件设置的变更。

日期边界使用设备本地时间，与待办页面相同。待办快照同时携带今天和明天，因此小组件无需应用即可在午夜切换到明天的列表；Android 至少每 30 分钟重绘一次，iOS 在下一个午夜和每个提醒时间安排时间线条目。

### 交互控件

复选框和计时器按钮使用 MyApps-Widget 的待处理动作队列（`packages/myapps_widget/doc/en-us/actions.md`）：Android 所有版本，iOS 17 及以上。在 iOS 14–16 上，同样的控件改为打开应用。

| 类型 | 动作 | `args` | 应用如何应用 |
|---|---|---|---|
| `myday.todo` | `setDone` | `id`、`date`（`yyyy-MM-dd`）、`done` | 每日任务：该日期的完成日志条目及其子任务。一次性任务：`isCompleted`、`completedDate`（该日期）及其子任务 |
| `myday.timer` | `start` | — | 无会话：从 `at` 起新建运行中的会话。已暂停：在 `at` 继续。运行中：不做任何事 |
| `myday.timer` | `pause` | — | 运行中：把 `at − startedAt` 加入已用时间并暂停 |
| `myday.timer` | `add` | `n`（100） | 在 `at` 时刻会话的已用时间处把 `n` 加入计数 |

`HomeWidgetService.drainActions()` 在启动时、恢复到前台时以及原生端报告新动作时运行。它按队列顺序应用动作，写入数据文件，发布在 `appliedActions` 中带有已应用 id 的信封，之后才确认这些动作。待办动作是幂等的（它设置一个状态）。计时器页面打开期间，计时器动作交给已打开的页面而不是文件，因此页面绝不会用其过时的状态覆盖它们。重复的一次性任务和已找不到的任务会在小组件端被跳过：它们的复选框改为在该任务上打开应用，以便「创建下一次」提示仍然出现。

应用运行之前，点按只存在于小组件队列中：它不在 `todo_data.json` 或 `intimacy_data.json` 中，也不会同步。渲染器会在信封之上重放待处理动作，使点按立即显示。

## 深层链接

打开应用的点按使用 `myday://widget/<kind>?do=<what>`：

| `do` | 打开 |
|---|---|
| 缺省 | 该类型的标签页（`/todo`、`/weight`、`/finance`、`/intimacy`） |
| `add` | 该标签页及其添加对话框（任务、体重记录、交易、亲密记录） |
| `toggle` 加 `id` | 待办的今天，切换该任务（应用内路径，带其重复提示） |
| `timer` | 亲密标签页和计时器页面 |

`HomeWidgetLaunch`（位于 `home_widget_service.dart`）把链接转换为一个待处理请求，由标签页在加载完成后消费。亲密模块隐藏时，亲密链接转到 `/todo`。该 scheme 在 `ios/Runner/Info.plist`（`CFBundleURLTypes`）中注册；Android 把链接作为启动 intent 的 data 传入。

## 快照格式（信封 1，payload 版本 1）

通用 payload 字段：`labels`（措辞，按应用语言从 ARB 文件解析；`{n}` 由原生端替换）和 `mask`（*隐藏数值*时为 true）。时间是 UTC 纪元毫秒；日期是本地 `yyyy-MM-dd`。

### `myday.todo`

```json
{
  "days": [
    {
      "date": "2026-11-02",
      "score": 2,
      "items": [
        {"id": "t1", "t": "Pay the bills", "e": "🧾", "k": "routineOnce", "done": false,
         "time": "", "late": true, "rec": false, "sched": false}
      ]
    },
    {"date": "2026-11-03", "score": null, "items": []}
  ],
  "appliedActions": ["6f1c…"],
  "mask": false,
  "labels": {}
}
```

- `days`——今天和明天，每一天都完全按待办页面显示该日期的方式计算（每日模板按 `startDate`/`deletedDate`，一次性任务在未完成时向后顺延）。每天最多 30 项，按显示顺序。
- `k`——`daily`、`routineOnce` 或 `workOnce`；`time`——提醒时间 `HH:mm` 或空；`late`——计划日期或截止日期早于该天的未完成一次性任务；`rec`——带重复规则的一次性任务；`sched`——恰好排期在该天的一次性任务（用于「明天」预览）。
- 找不到对应日期（快照已超过一天）时，渲染*打开 MyDay 以更新*状态。

### `myday.weight`

```json
{"latest": {"kg": 62.4, "at": 1767336120000}, "previousKg": 63.0, "change30": -1.2,
 "bmi": 21.6, "points": [63.6, 63.2, 62.9, 62.4], "remindAt": "07:30", "mask": false, "labels": {}}
```

没有记录时 `latest` 为 null。`change30` 是最新体重减去 30 天前或更早的最新一条记录（或最近 30 天中最旧的记录）。`points` 是最近 30 天的体重，最旧在前，最多 30 个。`remindAt` 是早间提醒时间，提醒模式为 `none` 时为空。

### `myday.finance`

```json
{"month": "2026-11", "monthLabel": "November", "expense": "¥3,284", "income": "¥12,000",
 "net": "¥8,716", "netNegative": false,
 "top": {"name": "Dining", "emoji": "🍜", "amount": "¥1,120", "share": 34},
 "bills": [{"name": "Netflix", "emoji": "", "day": "2026-11-05", "date": "11/05", "amount": "¥68"}],
 "mask": false, "labels": {}}
```

金额由应用以默认货币格式化。`bills` 是最多三个将在 7 天内扣费的活跃订阅（`upcomingSubscriptions`），渲染器会丢弃 `day` 已过去的账单。

### `myday.intimacy`

```json
{"lastAt": 1767052800000, "month": "2026-11", "monthCount": 6, "avgMinutes": 24,
 "cycleNext": "2026-11-07", "mask": true, "labels": {}}
```

没有记录时 `lastAt` 为 null；本月没有任何记录带时长时 `avgMinutes` 为 null；除非用户自己的周期跟踪开启且预测到了开始日期，否则 `cycleNext` 为空。当前月份与 `month` 不同时，渲染器显示计数 0。

### `myday.timer`

```json
{"session": {"running": true, "startedAt": 1767337200000, "accumulatedMs": 0, "count": 3400},
 "last": {"at": 1767052800000, "durationMs": 1440000}, "step": 100,
 "appliedActions": [], "mask": false, "labels": {}}
```

没有活动秒表时 `session` 为 null；`count` 是实际重复次数。`last` 是最新的记录或计时历史条目。渲染器按上表的语义重放待处理的 `start`、`pause` 和 `add` 动作。

这些 payload 仅限本设备：从不同步、备份或共享。修改其中之一意味着把该类型的 `pv`（`HomeWidgetService.formatVersion`）与两个原生读取端一起升级。

## 平台配置

- **Android**——receiver 在 `AndroidManifest.xml` 中声明；插件贡献自己的 `WidgetActionReceiver`。布局是 `res/layout/widget_*.xml`，在 Android 12+ 上使用 Material You 颜色（`values-v31/widget_colors.xml`），之前的版本使用种子色调。
- **iOS**——`MyDayWidgets` 应用扩展 target（部署目标 iOS 14，`AppIntents` 弱链接）通过文件引用嵌入 `packages/myapps_widget/apple/MyAppsWidgetKit/MyAppsWidgetKit.swift`。Runner 和扩展都带有 `group.com.yuanzhe.myDay` App Group entitlement，签名构建前必须在两个 App ID 上启用它。见 [`../platform-notes.md`](../platform-notes.md)。

## 隐私

小组件会把标题、体重、金额和亲密统计放到桌面上，待办锁屏矩形会把任务标题放到锁屏上。添加小组件之前什么都不会出现，移除它即停止显示，快照从不离开设备。
