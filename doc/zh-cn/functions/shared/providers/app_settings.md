# lib/shared/providers/app_settings.dart

应用全局主题模式、语言区域、周起始日偏好、四个设备本地列表列数偏好以及两个端侧 AI 开关的 Riverpod 状态。直接供给 `MyDayApp`（`app/app.dart`），并在屏幕需要配置周起始日（Todo/体重/亲密日历、`shared/utils/week_grouping.dart`）或需要知道端侧 AI 是否开启（洞察卡片和设置中的 AI 图块）的任何地方被读取。也把语言区域变更推给 `TrayService` 和 `ReminderService`，使它们的用户可见文本保持同步，并把 AI 开关推给 `OnDeviceAiService`。见 [架构 — 状态管理](../../../architecture.md#state-management) 和 [端侧 AI](../../../on-device-ai.md)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`AppSettingsNotifier`（构造函数）](#appsettingsnotifier-new) | 构造函数（`AppSettingsNotifier`） | A | 启动通知器并加载持久化设置。 |
| [`AppSettingsNotifier.fixed`](#appsettingsnotifier-fixed) | 命名构造函数（`AppSettingsNotifier`） | A | 创建从固定设置开始、不读磁盘的通知器。 |
| [`_loadPersisted`](#_loadpersisted) | 方法（`AppSettingsNotifier`） | A | 把每个持久化偏好加载进状态并推给各服务。 |
| [`setThemeMode`](#setthememode) | 方法（`AppSettingsNotifier`） | A | 更新并持久化主题模式。 |
| [`setLocale`](#setlocale) | 方法（`AppSettingsNotifier`） | A | 更新并持久化语言区域，传播给托盘/提醒服务。 |
| [`setWeekStartDay`](#setweekstartday) | 方法（`AppSettingsNotifier`） | A | 更新并持久化日历/周分组的第一工作日。 |
| [`setTodoSectionColumns`](#settodosectioncolumns) | 方法（`AppSettingsNotifier`） | A | 更新并持久化待办分区列数偏好。 |
| [`setFinanceListColumns`](#setfinancelistcolumns) | 方法（`AppSettingsNotifier`） | A | 更新并持久化财务交易列数偏好。 |
| [`setWeightListColumns`](#setweightlistcolumns) | 方法（`AppSettingsNotifier`） | A | 更新并持久化体重记录列数偏好。 |
| [`setIntimacyListColumns`](#setintimacylistcolumns) | 方法（`AppSettingsNotifier`） | A | 更新并持久化亲密记录列数偏好。 |
| [`setOnDeviceAiEnabled`](#setondeviceaienabled) | 方法（`AppSettingsNotifier`） | A | 开启或关闭端侧 AI，持久化并切换 `OnDeviceAiService`。 |
| [`setOnDeviceAiPreferFast`](#setondeviceaipreferfast) | 方法（`AppSettingsNotifier`） | A | 偏好更快的端侧模型，持久化并让服务重新探测。 |
| [`setUiStyle`](#setuistyle) | 方法（`AppSettingsNotifier`） | A | 选择界面风格（Material 3 或 Expressive）并持久化（1.6.0）。 |
| [`AppSettings`（构造函数）](#appsettings-new) | 构造函数（`AppSettings`） | A | 创建应用设置值。 |
| [`copyWith`](#copywith) | 方法（`AppSettings`） | A | 创建此值的副本并替换所选字段。 |
| `appSettingsProvider` | 顶层变量（`StateNotifierProvider`） | B | 向组件树暴露 `AppSettingsNotifier`。 |

**对账：** `grep -c 'Purpose:' lib/shared/providers/app_settings.dart` 报告 14，与上面 15 行中的 14 行精确匹配。额外行是 `appSettingsProvider`，`StateNotifierProvider` 顶层变量：完全无文档块（未文档化，非错附）——一行 `StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) => AppSettingsNotifier())` 工厂，平凡到 Tier B，但它是文件的公共入口点。`AppSettings` 的字段（`themeMode`、`locale`、`weekStartDay`、四个列数字段、`onDeviceAiEnabled`、`onDeviceAiPreferFast`）是数据而非行；较新的字段带无 `Purpose:` 的普通 `///` 字段注释。

## 文档

### `AppSettingsNotifier() : super(const AppSettings())` <a id="appsettingsnotifier-new"></a>
- **种类：** `AppSettingsNotifier` 的构造函数（扩展 `StateNotifier<AppSettings>`）
- **来源：** `lib/shared/providers/app_settings.dart`（第 19 行）
- **用途：** 用默认设置初始化状态，然后异步开始加载持久化设置。
- **输入：** 无。
- **返回：** 新 `AppSettingsNotifier`。
- **副作用：** 调用 `_loadPersisted()`（即发即忘）。
- **算法：** 把 `state` 初始化为 `const AppSettings()`（系统主题、系统语言区域、周一周起始、自动列数、端侧 AI 关闭），然后不 await 地调用 `_loadPersisted()`。
- **用法：** 只被 `appSettingsProvider` 的工厂实例化。
- **备注：** 异步加载解析前对 `appSettingsProvider` 的任何读取看到编译内默认，而非持久化值。

### `AppSettingsNotifier.fixed(super.settings)` <a id="appsettingsnotifier-fixed"></a>
- **种类：** `AppSettingsNotifier` 的命名构造函数
- **来源：** `lib/shared/providers/app_settings.dart`（第 29 行）
- **用途：** 创建状态从给定 `AppSettings` 开始的通知器，不从磁盘读取任何东西。
- **输入：** `settings` — 初始状态，经 super 参数转给 `StateNotifier` 的构造函数。
- **返回：** 新 `AppSettingsNotifier`。
- **副作用：** 无——与默认构造函数不同，从不调用 `_loadPersisted()`，因此构造时既不触碰 `TodoStorage` 也不触碰 `OnDeviceAiService`。
- **算法：** 无函数体的 super 参数构造函数。
- **用法：**
  ```dart
  appSettingsProvider.overrideWithValue(
    AppSettingsNotifier.fixed(AppSettings(onDeviceAiEnabled: enabled)),
  ),
  ```
  （`test/ai_insight_card_ui_test.dart`、`test/ai_settings_tiles_ui_test.dart`。）
- **备注：** 供覆盖 `appSettingsProvider` 的测试使用。setter 未变，因此在 fixed 通知器上调用 setter 仍经 `TodoStorage` 持久化（AI setter 仍切换 `OnDeviceAiService.instance`）。

### `Future<void> _loadPersisted()` <a id="_loadpersisted"></a>
- **种类：** `AppSettingsNotifier` 的私有方法
- **来源：** `lib/shared/providers/app_settings.dart`（第 36 行）
- **用途：** 从 `TodoStorage` 读取每个持久化偏好并应用到状态，然后把解析语言区域传播给 `TrayService`/`ReminderService`，把 AI 开关传播给 `OnDeviceAiService`。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 读取 `TodoStorage.getThemeMode()`、`getLocaleTag()`、`getWeekStartDay()`、四个 `get...Columns()` getter、`getOnDeviceAiEnabled()` 和 `getOnDeviceAiPreferFast()`；覆盖 `state`；调用 `TrayService.instance.updateLocale(...)` 和 `ReminderService.instance.updateLocale(...)`；依次 await `OnDeviceAiService.instance.setPreferFast(...)` 和 `setEnabled(...)`。
- **算法：**
  1. 读取九个持久化值。
  2. 经 `switch` 把主题字符串映射到 `ThemeMode`：`'light'` → `ThemeMode.light`、`'dark'` → `ThemeMode.dark`、任何其他（含 `null`）→ `ThemeMode.system`。
  3. 把 `localeTag`（下划线连接标签如 `en` 或 `zh_TW`）解析为 `Locale`，按 `'_'` 拆分，存在国家部分时用两部分 `Locale(language, country)` 构造函数。
  4. 用所有解析值把 `state` 设为新 `AppSettings`。
  5. 解析有效语言区域（`locale ?? PlatformDispatcher.instance.locale`）并推给 `TrayService.instance.updateLocale` 和 `ReminderService.instance.updateLocale` 两者。
  6. 把 AI 开关推给 `OnDeviceAiService.instance`：先 `setPreferFast`，再 `setEnabled`，使开启时用已选好的模型大小探测平台。
- **用法：** 从默认构造函数调用一次。
- **备注：** 状态中 `locale == null` 意为"跟随系统语言区域"——传给托盘/提醒服务的有效语言区域那时总是回退 `PlatformDispatcher.instance.locale`。持久化开关为关时，`setEnabled(false)` 对（已禁用的）服务是空操作，因此除非用户选择开启，启动时从不查询平台模型。

### `void setThemeMode(ThemeMode mode)` <a id="setthememode"></a>
- **种类：** `AppSettingsNotifier` 的方法
- **来源：** `lib/shared/providers/app_settings.dart`（第 83 行）
- **用途：** 更新应用主题模式并持久化选择。
- **输入：** `mode`。
- **返回：** 无。
- **副作用：** 更新 `state`；调用 `TodoStorage.setThemeMode(str)`（即发即忘）。
- **算法：** `state = state.copyWith(themeMode: mode)`；经 `switch` 把 `mode` 映射回可空字符串（`light`/`dark`/系统的 `null`），然后持久化。
- **用法：**
  ```dart
  ref.read(appSettingsProvider.notifier).setThemeMode(mode);
  ```
  （`lib/features/settings/views/settings_page.dart`，主题单选选择。）
- **备注：** `ThemeMode.system` 持久化为 `null`，匹配 `_loadPersisted` 的反向映射。

### `void setLocale(Locale? locale)` <a id="setlocale"></a>
- **种类：** `AppSettingsNotifier` 的方法
- **来源：** `lib/shared/providers/app_settings.dart`（第 98 行）
- **用途：** 更新应用语言区域（或清除回系统）、持久化选择并把有效语言区域传播给 `TrayService`/`ReminderService`。
- **输入：** `locale` — `null` 意为"跟随系统"。
- **返回：** 无。
- **副作用：** 更新 `state`；调用 `TrayService.instance.updateLocale` 和 `ReminderService.instance.updateLocale`；调用 `TodoStorage.setLocaleTag(...)`。
- **算法：**
  1. `state = state.copyWith(locale: locale, clearLocale: locale == null)`——需要显式 `clearLocale` 标志，因为 `copyWith` 的普通 `??` 模式无法区分"不改变"与"设为 null"。
  2. 以与 `_loadPersisted` 相同方式解析有效语言区域并推给两个服务。
  3. `locale == null` 时经 `setLocaleTag` 持久化 `null`；否则构建标签（存在国家代码时 `'$languageCode_$countryCode'`，否则只 `languageCode`）并持久化。
- **用法：**
  ```dart
  ref.read(appSettingsProvider.notifier).setLocale(locale);
  ```
  （`lib/features/settings/views/settings_page.dart`，语言选择。）
- **备注：** 为什么存在 `clearLocale` 见下面 `copyWith` 的备注。

### `void setWeekStartDay(int weekday)` <a id="setweekstartday"></a>
- **种类：** `AppSettingsNotifier` 的方法
- **来源：** `lib/shared/providers/app_settings.dart`（第 118 行）
- **用途：** 更新应用日历和周分组使用的第一工作日，持久化规范化值。
- **输入：** `weekday` — Dart 工作日编号（周一=1 .. 周日=7）；不必已有效。
- **返回：** 无。
- **副作用：** 更新 `state`；调用 `TodoStorage.setWeekStartDay(normalized)`。
- **算法：** `normalizeWeekStartDay(weekday)`（见 [周分组 — normalizeWeekStartDay](../utils/week_grouping.md#normalizeweekstartday)）把越界输入钳制回周一；然后更新 `state` 并持久化规范化值。
- **用法：**
  ```dart
  ref.read(appSettingsProvider.notifier).setWeekStartDay(weekday);
  ```
  （`lib/features/settings/views/settings_page.dart`，周起始日单选选择。）
- **备注：** 仓库中每个日历/周分组调用点都从该提供者状态读取 `weekStartDay`，因此这是全应用周起始的单一真相源。

### `void setUiStyle(AppUiStyle style)` <a id="setuistyle"></a>
- **种类：** `AppSettingsNotifier` 的方法
- **来源：** `lib/shared/providers/app_settings.dart`
- **用途：** 选择界面风格（1.6.0）。
- **输入：** `style`——`AppUiStyle.material3` 或 `AppUiStyle.expressive`。
- **返回：** 无。
- **副作用：** 替换 provider 状态；调用 `TodoStorage.setUiStyle`（Material 3 存 `'material3'`，Expressive 传 null）。应用重建主题，外壳重建底栏。
- **备注：** 默认 Expressive。Expressive 同时选用悬浮岛式底栏，Material 3 保持经典通栏；宽窗口的侧栏在两种风格下相同。该设置仅限本设备，从不同步。`AppSettings.uiStyle`（默认 `AppUiStyle.expressive`）在 `_loadPersisted` 中由 `TodoStorage.getUiStyle()` 加载。

### `const AppSettings({this.themeMode = ThemeMode.system, this.locale, this.weekStartDay = DateTime.monday, ..., this.onDeviceAiEnabled = false, this.onDeviceAiPreferFast = false})` <a id="appsettings-new"></a>
- **种类：** `AppSettings` 的 const 构造函数
- **来源：** `lib/shared/providers/app_settings.dart`（第 220 行）
- **用途：** 创建带跟随系统默认的不可变设置值。
- **输入：** `themeMode`（默认 `ThemeMode.system`）；`locale`（默认 `null` = 系统）；`weekStartDay`（默认 `DateTime.monday`）；`todoSectionColumns`、`financeListColumns`、`weightListColumns`、`intimacyListColumns`（各默认 `listColumnsAuto`）；`onDeviceAiEnabled` 和 `onDeviceAiPreferFast`（各默认 `false`）。
- **返回：** 新 `AppSettings`。
- **副作用：** 无。
- **算法：** 普通字段初始化 const 构造函数。
- **用法：** `const AppSettings()` 是传给 `AppSettingsNotifier` 构造函数的初始状态；测试把 `AppSettings(onDeviceAiEnabled: ...)` 传给 `AppSettingsNotifier.fixed`。
- **备注：** `weekStartDay` 全程使用 Dart 的周一=1 到周日=7 编号。端侧 AI 默认关闭。

### `AppSettings copyWith({ThemeMode? themeMode, Locale? locale, int? weekStartDay, int? todoSectionColumns, int? financeListColumns, int? weightListColumns, int? intimacyListColumns, bool? onDeviceAiEnabled, bool? onDeviceAiPreferFast, bool clearLocale = false})` <a id="copywith"></a>
- **种类：** `AppSettings` 的方法
- **来源：** `lib/shared/providers/app_settings.dart`（第 237 行）
- **用途：** 创建此设置值的副本并替换所选字段，带把语言区域清除回 `null` 的显式逃生舱口。
- **输入：** 每个字段作为可选参数（各回退当前值）；`clearLocale`（默认 `false`）——为 `true` 时无论 `locale` 参数如何都强制结果 `locale` 为 `null`。
- **返回：** 新 `AppSettings`。
- **副作用：** 无。
- **算法：** `locale: clearLocale ? null : (locale ?? this.locale)`；其他每个字段用普通 `?? this.x` 模式。
- **用法：** `state.copyWith(themeMode: mode)`、`state.copyWith(locale: locale, clearLocale: locale == null)`、`state.copyWith(onDeviceAiEnabled: enabled)` 及其他 setter——全部在本文件上面的 `AppSettingsNotifier` 方法内。
- **备注：** 存在 `clearLocale` 参数是因为普通 `locale ?? this.locale` 模式永远无法表示"显式把语言区域设回 null"——没有它，`setLocale(null)` 会与"不改变语言区域"无法区分。

### `void setTodoSectionColumns(int columns)` <a id="settodosectioncolumns"></a>
- **种类：** `AppSettingsNotifier` 的方法
- **来源：** `lib/shared/providers/app_settings.dart`（第 130 行）
- **用途：** 更新并持久化待办页每行放几个任务分区。
- **输入：** `columns`——`listColumnsAuto`（0）或固定的列数。
- **返回：** 无。
- **副作用：** 替换 provider 状态并写入 `storage_config.json`。
- **算法：** `state = state.copyWith(...)`，然后 `TodoStorage.setTodoSectionColumns(columns)`。
- **用法：** 待办页 app bar 的 `listColumnsButton` 在 `onChanged` 中调用它。
- **备注：** 单位是**分区**，不是图块。存放在从不同步的 `storage_config.json` 中，是设备本地的，因为窗口尺寸是设备的属性而不是账户的属性——见 [../../../adaptive-layout.md](../../../adaptive-layout.md)。存储的是原始偏好；渲染的是该偏好被钳制到当前宽度放得下的结果，因此在桌面上做出的选择能挺过折叠并在展开时回来。

### `void setFinanceListColumns(int columns)` <a id="setfinancelistcolumns"></a>
- **种类：** `AppSettingsNotifier` 的方法
- **来源：** `lib/shared/providers/app_settings.dart`（第 140 行）
- **用途：** 更新并持久化财务列表每行放几个交易图块。
- **输入：** `columns`。
- **返回：** 无。
- **副作用：** 替换 provider 状态并写入 `storage_config.json`。
- **算法：** 同 `setTodoSectionColumns`，针对 `financeListColumns`。
- **用法：** 财务页 app bar 的 `listColumnsButton`。
- **备注：** 逐界面存储，因此四个列表界面彼此独立。

### `void setWeightListColumns(int columns)` <a id="setweightlistcolumns"></a>
- **种类：** `AppSettingsNotifier` 的方法
- **来源：** `lib/shared/providers/app_settings.dart`（第 150 行）
- **用途：** 更新并持久化每行放几个体重记录图块。
- **输入：** `columns`。
- **返回：** 无。
- **副作用：** 替换 provider 状态并写入 `storage_config.json`。
- **算法：** 同 `setTodoSectionColumns`，针对 `weightListColumns`。
- **用法：** 体重页 app bar 的 `listColumnsButton`；同一偏好也驱动「显示全部」底部面板，该面板测量屏幕而不是页面，因为它绘制在根 overlay 上。
- **备注：** 无。

### `void setIntimacyListColumns(int columns)` <a id="setintimacylistcolumns"></a>
- **种类：** `AppSettingsNotifier` 的方法
- **来源：** `lib/shared/providers/app_settings.dart`（第 160 行）
- **用途：** 更新并持久化每行放几个亲密记录图块。
- **输入：** `columns`。
- **返回：** 无。
- **副作用：** 替换 provider 状态并写入 `storage_config.json`。
- **算法：** 同 `setTodoSectionColumns`，针对 `intimacyListColumns`。
- **用法：** 亲密页 app bar 的 `listColumnsButton` 及其「显示全部」面板。
- **备注：** 无。

### `void setOnDeviceAiEnabled(bool enabled)` <a id="setondeviceaienabled"></a>
- **种类：** `AppSettingsNotifier` 的方法
- **来源：** `lib/shared/providers/app_settings.dart`（第 171 行）
- **用途：** 开启或关闭端侧 AI（各模块的洞察卡片）。
- **输入：** `enabled`。
- **返回：** 无。
- **副作用：** 替换 provider 状态；调用 `TodoStorage.setOnDeviceAiEnabled(enabled)`（写入 `storage_config.json`）和 `OnDeviceAiService.instance.setEnabled(enabled)`——两者都即发即忘。
- **算法：** `state = state.copyWith(onDeviceAiEnabled: enabled)`，然后持久化，再切换服务。
- **用法：** [`ai_settings_tiles.dart`](../../features/ai/widgets/ai_settings_tiles.md) 中的「使用端侧 AI」开关（`onChanged: notifier.setOnDeviceAiEnabled`）。
- **备注：** 默认关闭且设备本地（从不同步）。开启使服务重新探测平台；关闭取消正在运行的请求、使所有排队请求失败，之后洞察卡片不渲染任何内容。见 [端侧 AI](../../../on-device-ai.md)。

### `void setOnDeviceAiPreferFast(bool enabled)` <a id="setondeviceaipreferfast"></a>
- **种类：** `AppSettingsNotifier` 的方法
- **来源：** `lib/shared/providers/app_settings.dart`（第 182 行）
- **用途：** 在平台同时提供两种大小时偏好更快的端侧模型。
- **输入：** `enabled`。
- **返回：** 无。
- **副作用：** 替换 provider 状态；调用 `TodoStorage.setOnDeviceAiPreferFast(enabled)` 和 `OnDeviceAiService.instance.setPreferFast(enabled)`（即发即忘），AI 开启时后者会重新探测状态。
- **算法：** `state = state.copyWith(onDeviceAiPreferFast: enabled)`，然后持久化，再更新服务。
- **用法：** [`ai_settings_tiles.dart`](../../features/ai/widgets/ai_settings_tiles.md) 中的"偏好更快模型"开关（`onChanged: notifier.setOnDeviceAiPreferFast`），仅在 AI 开启、Android 上且状态报告提供大小选择时显示。
- **备注：** 只在 Android 上有意义（AICore 提供完整模型和快速模型）；设备本地。
