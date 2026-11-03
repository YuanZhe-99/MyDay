# lib/shared/services/home_widget_service.dart

Android 和 iOS 桌面小组件（1.8.3）的应用端。`HomeWidgetService` 是共享 MyApps-Widget 桥接（`packages/myapps_widget`）之上的静态门面：它为每种小组件类型（`myday.todo`、`myday.weight`、`myday.finance`、`myday.intimacy`、`myday.timer`）发布一个信封，其 payload 由 [`HomeWidgetPayloads`](home_widget_payloads.md) 构建，并通过 [`HomeWidgetActions`](home_widget_actions.md) 应用小组件控件排队的点击。同一文件还包含每种类型的设置模型（`HomeWidgetKindSettings`，存放在 `storage_config.json` 的 `homeWidgets` 下）以及 `HomeWidgetLaunch`，后者为路由器把小组件深层链接转换为标签页位置。在 Android 和 iOS 之外，每个入口点都是空操作。功能、数据流和快照格式见 [桌面小组件](../../../features/home-screen-widgets.md)，`homeWidgets` 键见 [数据格式](../../../data-formats.md#storage_configjson)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `HomeWidgetPrivacyChoice` | 枚举 | B | 一种小组件类型如何显示其数值：`show`、`maskValues`、`iconOnly`。 |
| `HomeWidgetPrivacyChoice.fromName` | 静态方法（`HomeWidgetPrivacyChoice`） | B | 读取存储的选项；未知时为 null。 |
| `HomeWidgetKindSettings`（构造函数） | const 构造函数（`HomeWidgetKindSettings`） | B | 保存一种类型的文字缩放和隐私选项。 |
| `HomeWidgetKindSettings.copyWith` | 方法（`HomeWidgetKindSettings`） | B | 返回替换所选字段的副本，并限制文字缩放范围。 |
| `HomeWidgetKindSettings.toJson` | 方法（`HomeWidgetKindSettings`） | B | 序列化以写入 `storage_config.json`。 |
| `HomeWidgetLaunchRequest`（构造函数） | const 构造函数（`HomeWidgetLaunchRequest`） | B | 保存一次等待目标页面处理的小组件点击。 |
| [`isWidgetLink`](#iswidgetlink) | 静态方法（`HomeWidgetLaunch`） | A | 判断一个位置是否为桌面小组件链接。 |
| [`redirect`](#redirect) | 静态方法（`HomeWidgetLaunch`） | A | 把小组件深层链接转换为标签页位置并记录其动作。 |
| [`take`](#take) | 静态方法（`HomeWidgetLaunch`） | A | 若待处理请求属于给定类型之一，则取走它。 |
| `HomeWidgetService._()` | 构造函数（`HomeWidgetService`） | B | 阻止直接实例化；只暴露静态成员。 |
| 类型与平台常量 | 静态常量（`HomeWidgetService`） | B | `todoKind` … `timerKind`、`kinds`、`appGroupId`、`formatVersion`、`configKey`、`androidProviders`、`iosKinds`。 |
| `bridge` | 静态字段（`HomeWidgetService`） | B | 描述每种 MyDay 类型的共享 `MyAppsWidgetBridge`。 |
| `isSupported` | 静态 getter（`HomeWidgetService`） | B | 此平台是否有桌面小组件（Android 和 iOS）。 |
| [`tabFor`](#tabfor) | 静态方法（`HomeWidgetService`） | A | 返回一种类型打开的标签页路径。 |
| [`defaultSettings`](#defaultsettings) | 静态方法（`HomeWidgetService`） | A | 返回一种类型的默认设置。 |
| [`loadSettings`](#loadsettings) | 静态方法（`HomeWidgetService`） | A | 读取每种类型的设置，并填入默认值。 |
| [`_parseSettings`](#_parsesettings) | 静态方法（`HomeWidgetService`） | A | 宽容地解析一种类型的存储设置。 |
| [`saveSettings`](#savesettings) | 静态方法（`HomeWidgetService`） | A | 存储一种类型的设置并刷新小组件。 |
| [`init`](#init) | 静态方法（`HomeWidgetService`） | A | 开始为小组件提供数据。 |
| [`notifyDataChanged`](#notifydatachanged) | 静态方法（`HomeWidgetService`） | A | 数据或设置变化后安排一次防抖刷新。 |
| [`drainActions`](#drainactions) | 静态方法（`HomeWidgetService`） | A | 应用小组件控件排队的动作，一次一轮。 |
| [`_drain`](#_drain) | 静态方法（`HomeWidgetService`） | A | 执行一轮处理。 |
| [`refresh`](#refresh) | 静态方法（`HomeWidgetService`） | A | 重建每种类型的信封并重绘小组件。 |
| [`payloadBuilders`](#payloadbuilders) | 静态方法（`HomeWidgetService`） | A | 为每种类型准备一个 payload 构建器。 |
| [`envelopePrivacy`](#envelopeprivacy) | 静态方法（`HomeWidgetService`） | A | 把隐私选项映射为信封的隐私级别。 |
| [`_l10n`](#_l10n) | 静态方法（`HomeWidgetService`） | A | 解析本地化和 intl 语言区域标签。 |
| [`didChangeAppLifecycleState`](#didchangeapplifecyclestate) | 方法（`_LifecycleObserver`） | A | 应用恢复时处理小组件动作并安排刷新。 |

**对账：** `grep -c 'Purpose:' lib/shared/services/home_widget_service.dart` 报告 24，对应上面 27 行。多出的三行是没有 `Purpose:` 块的真实声明：`HomeWidgetPrivacyChoice` 枚举、`HomeWidgetService` 类型与平台常量的分组行（一行覆盖一族相关常量，与 `data_modules.md` 相同），以及门面持有共享包的 `bridge` 字段。其他字段（`HomeWidgetLaunch.pending`、`timerActionHandler`、`_scheduler`、`_applied`、`_draining`、`_observer`）只带普通 `///` 注释，视为数据而非声明。

## 文档

### `static bool isWidgetLink(Uri uri)` <a id="iswidgetlink"></a>
- **种类：** `HomeWidgetLaunch` 的静态方法
- **来源：** `lib/shared/services/home_widget_service.dart`（第 114 行）
- **用途：** 判断一个位置是否为桌面小组件链接。
- **输入：** `uri`——要求 go_router 打开的位置。
- **返回：** 当路径恰好一段且该段是 MyDay 小组件类型（`tabFor` 返回路径）时为 `true`。
- **副作用：** 无。
- **算法：** `uri.pathSegments.length == 1 && HomeWidgetService.tabFor(segment) != null`。
- **用法：** [`appRouter`](../../app/router.md#approuter) 的顶层 `redirect` 先调用它，因此只有小组件链接才需要异步读取亲密可见性。
- **备注：** 普通路由（`/todo`、`/settings`……）永远不是小组件链接，因为其路径段不是 `myday.*` 类型。

### `static String? redirect(Uri uri, {required bool intimacyVisible})` <a id="redirect"></a>
- **种类：** `HomeWidgetLaunch` 的静态方法
- **来源：** `lib/shared/services/home_widget_service.dart`（第 125 行）
- **用途：** 把小组件深层链接转换为标签页位置。
- **输入：** `uri`；`intimacyVisible`——亲密模块是否显示。
- **返回：** 要重定向到的标签页路径；`uri` 不是小组件链接时为 null。
- **副作用：** 链接带有 `do` 动作时，把 `pending` 设为一个 `HomeWidgetLaunchRequest`。
- **算法：**
  1. 除非路径是 `tabFor` 能映射到标签页的单个路径段，否则返回 null。
  2. 模块隐藏时，`myday.intimacy` 和 `myday.timer` 返回 `/todo`，不记录动作。
  3. 查询带有 `do` 时，把 `HomeWidgetLaunchRequest(kind, action: do, id: id)` 存入 `pending`。
  4. 返回标签页路径。
- **用法：** `appRouter` 的 `redirect`，在读取 `TodoStorage.getIntimacyVisible()` 之后。
- **备注：** 同时接受 Android 路由形式 `/myday.todo?do=add` 和 iOS URL `myday://widget/myday.todo?do=add`；两者都只有一个路径段。见 [深层链接](../../../features/home-screen-widgets.md#deep-links)。

### `static HomeWidgetLaunchRequest? take(Set<String> kinds)` <a id="take"></a>
- **种类：** `HomeWidgetLaunch` 的静态方法
- **来源：** `lib/shared/services/home_widget_service.dart`（第 151 行）
- **用途：** 若待处理请求属于 `kinds` 之一，则取走它。
- **输入：** `kinds`——调用页面处理的小组件类型。
- **返回：** 请求；没有待处理请求或它属于其他页面时为 null。
- **副作用：** 匹配时清空 `pending`。
- **算法：** 读取 `pending.value`；为 null 或其类型不在 `kinds` 中时返回 null；否则设 `pending.value = null` 并返回它。
- **用法：** 待办、体重、财务和亲密页面的 `_onWidgetLaunch` 辅助方法，在数据加载后以及在 `pending` 监听器中调用。
- **备注：** 属于其他标签页的请求保持待处理，直到该标签页取走它。

### `static String? tabFor(String kind)` <a id="tabfor"></a>
- **种类：** `HomeWidgetService` 的静态方法
- **来源：** `lib/shared/services/home_widget_service.dart`（第 272 行）
- **用途：** 返回一种类型打开的标签页路径。
- **输入：** `kind`。
- **返回：** `/todo`、`/weight`、`/finance`、`/intimacy`（`myday.intimacy` 和 `myday.timer` 都是），未知类型为 null。
- **副作用：** 无。
- **算法：** 对五个类型常量做 `switch`。
- **用法：** `HomeWidgetLaunch.isWidgetLink` 和 `HomeWidgetLaunch.redirect`。
- **备注：** 无。

### `static HomeWidgetKindSettings defaultSettings(String kind)` <a id="defaultsettings"></a>
- **种类：** `HomeWidgetService` 的静态方法
- **来源：** `lib/shared/services/home_widget_service.dart`（第 285 行）
- **用途：** 返回一种类型的默认设置。
- **输入：** `kind`。
- **返回：** 文字缩放 100%；`myday.intimacy` 为*隐藏数值*（`maskValues`），其他类型为*显示*。
- **副作用：** 无。
- **算法：** 对 `kind == intimacyKind` 做一次条件判断。
- **用法：** `_parseSettings` 的回退值。
- **备注：** 私密小组件默认隐藏数值，直到用户另行选择。

### `static Future<Map<String, HomeWidgetKindSettings>> loadSettings()` <a id="loadsettings"></a>
- **种类：** `HomeWidgetService` 的静态方法
- **来源：** `lib/shared/services/home_widget_service.dart`（第 297 行）
- **用途：** 读取每种类型的设置。
- **输入：** 无。
- **返回：** `kinds` 中每项一个 `HomeWidgetKindSettings`，已填入默认值。
- **副作用：** 通过 `TodoStorage.readConfig()` 读取 `storage_config.json`。
- **算法：** 读取 `homeWidgets` 值，再对每种类型调用 `_parseSettings(kind, raw)`。
- **用法：** `refresh` 和 `HomeWidgetSettingsPage._load`。
- **备注：** 格式错误的条目回退为默认值；读取本身是宽松的。

### `static HomeWidgetKindSettings _parseSettings(String kind, Object? raw)` <a id="_parsesettings"></a>
- **种类：** `HomeWidgetService` 的私有静态方法
- **来源：** `lib/shared/services/home_widget_service.dart`（第 307 行）
- **用途：** 解析一种类型的存储设置。
- **输入：** `kind`；`raw`——存储的 `homeWidgets` 值，可为任意 JSON 形状。
- **返回：** `HomeWidgetKindSettings`。
- **副作用：** 无。
- **算法：** `raw` 不是映射或其 `kind` 条目不是映射时，返回默认值。否则取数值型 `textScale` 并经 `WidgetTextScale.clamp` 限制范围，`privacy` 经 `HomeWidgetPrivacyChoice.fromName` 读取，各自回退到默认值。
- **用法：** `loadSettings`。
- **备注：** 遇到意外输入从不抛出。

### `static Future<void> saveSettings(String kind, HomeWidgetKindSettings settings)` <a id="savesettings"></a>
- **种类：** `HomeWidgetService` 的静态方法
- **来源：** `lib/shared/services/home_widget_service.dart`（第 328 行）
- **用途：** 存储一种类型的设置并刷新小组件。
- **输入：** `kind`、`settings`。
- **返回：** 存储完成时完成。
- **副作用：** 合并写入 `storage_config.json` 中的 `homeWidgets`，并调用 `notifyDataChanged`。
- **算法：** 读取当前 `homeWidgets` 映射（或从空开始），用 `settings.toJson()` 替换 `kind` 条目，再用单键补丁 `TodoStorage.writeConfig({configKey: all})` 写回。
- **用法：** `HomeWidgetSettingsPage._update`。
- **备注：** 只存在于本设备；从不同步、备份或导出。

### `static Future<void> init()` <a id="init"></a>
- **种类：** `HomeWidgetService` 的静态方法
- **来源：** `lib/shared/services/home_widget_service.dart`（第 347 行）
- **用途：** 开始为小组件提供数据。
- **输入：** 无。
- **返回：** 第一次处理完成后完成；第一次刷新不 await。
- **副作用：** 把 `notifyDataChanged` 订阅到 `AutoSyncService.addOnLocalDataChanged`，把桥接的动作排队监听器设为 `drainActions`，注册一个 `_LifecycleObserver`，处理队列并刷新每种类型。
- **算法：** `!isSupported` 时立即返回；否则接好这三项订阅，`await drainActions()`，然后 `unawaited(refresh())`。
- **用法：** 由 [`main()`](../../main.md#main) 调用一次，不 await。
- **备注：** 观察者只创建一次（`??=`）。

### `static void notifyDataChanged()` <a id="notifydatachanged"></a>
- **种类：** `HomeWidgetService` 的静态方法
- **来源：** `lib/shared/services/home_widget_service.dart`（第 363 行）
- **用途：** 数据或设置变化后安排一次防抖刷新。
- **输入：** 无。
- **返回：** 无。
- **副作用：** 重启 2 秒的 `WidgetRefreshScheduler` 计时器，之后由它调用 `refresh`。
- **算法：** 不受支持时为空操作；否则 `_scheduler.schedule()`。
- **用法：** `TodoStorage`、`WeightStorage`、`FinanceStorage` 和 `IntimacyStorage` 的 `_saveNow`；同步与恢复的重新加载（经 `init` 的订阅）；应用恢复；`AppSettingsNotifier.setLocale`；`IntimacyVisibilityNotifier.setVisible`；`saveSettings`。
- **备注：** 一连串保存只产生一次刷新。

### `static Future<void> drainActions()` <a id="drainactions"></a>
- **种类：** `HomeWidgetService` 的静态方法
- **来源：** `lib/shared/services/home_widget_service.dart`（第 376 行）
- **用途：** 应用小组件控件排队的动作。
- **输入：** 无。
- **返回：** 动作被应用、发布并确认后完成。
- **副作用：** 见 `_drain`。
- **算法：** 不受支持时为空操作；否则返回正在进行的一轮，或启动 `_drain()` 并在完成时清空 `_draining`。
- **用法：** `init`、桥接的动作排队监听器，以及应用恢复时的 `_LifecycleObserver`。
- **备注：** 并发调用共享同一轮。失败时动作留在队列中，等待下次处理。

### `static Future<void> _drain()` <a id="_drain"></a>
- **种类：** `HomeWidgetService` 的私有静态方法
- **来源：** `lib/shared/services/home_widget_service.dart`（第 386 行）
- **用途：** 执行一轮处理。
- **输入：** 无。
- **返回：** 完成时完成。
- **副作用：** 可能写入 `todo_data.json` 和 `intimacy_data.json`；写入后调用 `AutoSyncService.notifySaved()` 和 `notifyLocalDataChangedNow()`；发布每个信封；在原生队列中确认已处理的动作。
- **算法：**
  1. 读取 `bridge.pendingActions()`；为空则停止。把它们分为待办、计时器和其他动作。
  2. 待办：加载 `TodoStorage`，应用 `HomeWidgetActions.applyTodo`，有变化则保存；把 id 记入 `_applied`。
  3. 计时器：若计时器页面注册了 `timerActionHandler`，把动作交给它；否则加载 `IntimacyStorage`，对存储的会话应用 `HomeWidgetActions.applyTimer`，有变化则以新的 UTC `modifiedAt` 保存 `data.withTimerSession(...)`。记下 id。
  4. 写入后通知自动同步和已打开的页面。
  5. `await refresh()`，然后确认待办、计时器和其他动作的 id。
- **用法：** 只经由 `drainActions`。
- **备注：** 错误被记录并吞掉；失败后不确认任何动作，因此它们会被重试。其他类型的动作被确认但不产生效果。

### `static Future<void> refresh()` <a id="refresh"></a>
- **种类：** `HomeWidgetService` 的静态方法
- **来源：** `lib/shared/services/home_widget_service.dart`（第 454 行）
- **用途：** 重建每种类型的信封并重绘小组件。
- **输入：** 无。
- **返回：** 发布完成时完成。
- **副作用：** 读取数据文件和 `storage_config.json`；写入原生小组件存储；亲密模块隐藏时清除私密和计时器信封。
- **算法：**
  1. 加载设置和 `payloadBuilders(now)`。
  2. 对每种类型构建 payload，选*隐藏数值*时设置 `mask`；构建器返回 null 时调用 `bridge.clear(kind)`，否则发布 `bridge.envelope(kind, payload, generatedAt: now, textScale, privacy: envelopePrivacy(...))`。
  3. 把每个 `_applied` 列表裁剪到 `HomeWidgetPayloads.maxAppliedActions`。
- **用法：** 刷新调度器、`init` 和 `_drain`。
- **备注：** 每种类型独立失败，失败会被记录，因为过时的小组件无害。

### `static Future<Map<String, Future<Map<String, dynamic>?> Function(bool mask)>> payloadBuilders(DateTime now)` <a id="payloadbuilders"></a>
- **种类：** `HomeWidgetService` 的静态方法
- **来源：** `lib/shared/services/home_widget_service.dart`（第 497 行）
- **用途：** 为每种类型准备一个 payload 构建器。
- **输入：** `now`——payload 所描述的时刻。
- **返回：** 按类型索引的构建器；每个接收 `mask` 标志并返回 payload，亲密模块隐藏时私密和计时器类型返回 null。
- **副作用：** 读取 `storage_config.json`，并为应用语言初始化 intl 日期符号；每个构建器被调用时读取自己的数据文件。
- **算法：** 解析 `_l10n()`，调用 `initializeDateFormatting(localeTag)`（忽略错误），读取亲密可见性，然后返回包装对应 `HomeWidgetPayloads` 构建器的闭包：`todo` 和 `timer` 还接收各自的 `_applied` id，`finance` 还加载 `ExchangeRateStorage`。
- **用法：** `refresh` 和设置页预览（`HomeWidgetSettingsPage._load`）。
- **备注：** 预览以 `mask: false` 调用每个构建器；遮罩由预览组件自己施加。

### `static WidgetPrivacy envelopePrivacy(String kind, HomeWidgetPrivacyChoice choice)` <a id="envelopeprivacy"></a>
- **种类：** `HomeWidgetService` 的静态方法
- **来源：** `lib/shared/services/home_widget_service.dart`（第 551 行）
- **用途：** 把隐私选项映射为信封的隐私级别。
- **输入：** `kind`、`choice`。
- **返回：** *显示* → 该类型的默认级别（待办为 `normal`，其他为 `sensitive`）；*隐藏数值* → `sensitive`；*只显示图标* → `hidden`。
- **副作用：** 无。
- **算法：** 对 `choice` 做 `switch`。
- **用法：** `refresh`。
- **备注：** `sensitive` 让 iOS 在设备锁定时遮盖小组件。

### `static Future<(AppLocalizations, String)> _l10n()` <a id="_l10n"></a>
- **种类：** `HomeWidgetService` 的私有静态方法
- **来源：** `lib/shared/services/home_widget_service.dart`（第 565 行）
- **用途：** 解析本地化和 intl 语言区域标签。
- **输入：** 无。
- **返回：** 本地化对象和一个标签，例如 `en`、`zh` 或 `zh_TW`。
- **副作用：** 读取 `storage_config.json`（`TodoStorage.getLocaleTag()`）。
- **算法：** 使用存储的语言区域标签，否则使用平台语言区域；`lookupAppLocalizations`；繁体中文（国家 `TW` 或文字 `Hant`）追加 `_TW`。
- **用法：** `payloadBuilders`。
- **备注：** 与设置 provider 的解析方式相同；任何失败都回退为英语。

### `void didChangeAppLifecycleState(AppLifecycleState state)` <a id="didchangeapplifecyclestate"></a>
- **种类：** `_LifecycleObserver`（一个 `WidgetsBindingObserver`）的方法
- **来源：** `lib/shared/services/home_widget_service.dart`（第 594 行）
- **用途：** 响应应用生命周期变化。
- **输入：** `state`。
- **返回：** 无。
- **副作用：** `resumed` 时启动 `drainActions()` 并调用 `notifyDataChanged()`。
- **算法：** 忽略 `resumed` 以外的所有状态。
- **用法：** 由 `init` 注册一次。
- **备注：** 覆盖应用挂起期间发生的点击。
