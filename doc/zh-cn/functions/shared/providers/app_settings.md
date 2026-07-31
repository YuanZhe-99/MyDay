# lib/shared/providers/app_settings.dart

应用全局主题模式、语言区域和周起始日偏好的 Riverpod 状态。直接供给 `MyDayApp`（`app/app.dart`），并在屏幕需要配置周起始日的任何地方被读取（Todo/体重/亲密日历、`shared/utils/week_grouping.dart`）。也把语言区域变更推给 `TrayService` 和 `ReminderService`，使它们的用户可见文本保持同步。见 [架构 — 状态管理](../../../architecture.md#state-management)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`AppSettingsNotifier`（构造函数）](#appsettingsnotifier-new) | 构造函数（`AppSettingsNotifier`） | A | 启动通知器并加载持久化设置。 |
| [`_loadPersisted`](#_loadpersisted) | 方法（`AppSettingsNotifier`） | A | 把主题/语言区域/周起始日从存储加载进状态。 |
| [`setThemeMode`](#setthememode) | 方法（`AppSettingsNotifier`） | A | 更新并持久化主题模式。 |
| [`setLocale`](#setlocale) | 方法（`AppSettingsNotifier`） | A | 更新并持久化语言区域，传播给托盘/提醒服务。 |
| [`setWeekStartDay`](#setweekstartday) | 方法（`AppSettingsNotifier`） | A | 更新并持久化日历/周分组的第一工作日。 |
| [`AppSettings`（构造函数）](#appsettings-new) | 构造函数（`AppSettings`） | A | 创建应用设置值。 |
| [`copyWith`](#copywith) | 方法（`AppSettings`） | A | 创建此值的副本并替换所选字段。 |
| `appSettingsProvider` | 顶层变量（`StateNotifierProvider`） | B | 向组件树暴露 `AppSettingsNotifier`。 |

`grep -c 'Purpose:' lib/shared/providers/app_settings.dart` 报告 7，与上面七个 `Purpose:` 文档化声明匹配。第八行 `appSettingsProvider` 是完全无文档块（未文档化，非错附）的真实顶层声明——一行 `StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) => AppSettingsNotifier())` 工厂，平凡到 Tier B。

**对账：** `grep -c 'Purpose:' lib/shared/providers/app_settings.dart` 报告 7，与上面 8 行中的 7 行精确匹配。额外行是 `appSettingsProvider`，`StateNotifierProvider` 顶层变量：无 `Purpose:` 块，但它是文件的公共入口点。

## 文档

### `AppSettingsNotifier() : super(const AppSettings())` <a id="appsettingsnotifier-new"></a>
- **种类：** `AppSettingsNotifier` 的构造函数（扩展 `StateNotifier<AppSettings>`）
- **来源：** `lib/shared/providers/app_settings.dart`（第 17 行）
- **用途：** 用默认设置初始化状态，然后异步开始加载持久化设置。
- **输入：** 无。
- **返回：** 新 `AppSettingsNotifier`。
- **副作用：** 调用 `_loadPersisted()`（即发即忘）。
- **算法：** 把 `state` 初始化为 `const AppSettings()`（系统主题、系统语言区域、周一周起始），然后不 await 地调用 `_loadPersisted()`。
- **用法：** 只被 `appSettingsProvider` 的工厂实例化。
- **备注：** 异步加载解析前对 `appSettingsProvider` 的任何读取看到编译内默认，而非持久化值。

### `Future<void> _loadPersisted()` <a id="_loadpersisted"></a>
- **种类：** `AppSettingsNotifier` 的私有方法
- **来源：** `lib/shared/providers/app_settings.dart`（第 26 行）
- **用途：** 从 `TodoStorage` 读取持久化主题模式、语言区域标签和周起始日并应用到状态，然后把解析语言区域传播给 `TrayService`/`ReminderService`。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 读取 `TodoStorage.getThemeMode()`、`getLocaleTag()`、`getWeekStartDay()`；覆盖 `state`；调用 `TrayService.instance.updateLocale(...)` 和 `ReminderService.instance.updateLocale(...)`。
- **算法：**
  1. 读取三个持久化值。
  2. 经 `switch` 把主题字符串映射到 `ThemeMode`：`'light'` → `ThemeMode.light`、`'dark'` → `ThemeMode.dark`、任何其他（含 `null`）→ `ThemeMode.system`。
  3. 把 `localeTag`（下划线连接标签如 `en` 或 `zh_TW`）解析为 `Locale`，按 `'_'` 拆分，存在国家部分时用两部分 `Locale(language, country)` 构造函数。
  4. 用解析的 `themeMode`/`locale`/`weekStartDay` 把 `state` 设为新 `AppSettings`。
  5. 解析有效语言区域（`locale ?? PlatformDispatcher.instance.locale`）并推给 `TrayService.instance.updateLocale` 和 `ReminderService.instance.updateLocale` 两者。
- **用法：** 从构造函数调用一次。
- **备注：** 状态中 `locale == null` 意为"跟随系统语言区域"——传给托盘/提醒服务的有效语言区域那时总是回退 `PlatformDispatcher.instance.locale`。

### `void setThemeMode(ThemeMode mode)` <a id="setthememode"></a>
- **种类：** `AppSettingsNotifier` 的方法
- **来源：** `lib/shared/providers/app_settings.dart`（第 58 行）
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
- **来源：** `lib/shared/providers/app_settings.dart`（第 68 行）
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
- **来源：** `lib/shared/providers/app_settings.dart`（第 93 行）
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

### `const AppSettings({this.themeMode = ThemeMode.system, this.locale, this.weekStartDay = DateTime.monday})` <a id="appsettings-new"></a>
- **种类：** `AppSettings` 的 const 构造函数
- **来源：** `lib/shared/providers/app_settings.dart`（第 110 行）
- **用途：** 创建带跟随系统默认的不可变设置值。
- **输入：** `themeMode`（默认 `ThemeMode.system`）；`locale`（默认 `null` = 系统）；`weekStartDay`（默认 `DateTime.monday`）。
- **返回：** 新 `AppSettings`。
- **副作用：** 无。
- **算法：** 普通字段初始化 const 构造函数。
- **用法：** `const AppSettings()` 是传给 `AppSettingsNotifier` 构造函数的初始状态。
- **备注：** `weekStartDay` 全程使用 Dart 的周一=1 到周日=7 编号。

### `AppSettings copyWith({ThemeMode? themeMode, Locale? locale, int? weekStartDay, bool clearLocale = false})` <a id="copywith"></a>
- **种类：** `AppSettings` 的方法
- **来源：** `lib/shared/providers/app_settings.dart`（第 121 行）
- **用途：** 创建此设置值的副本并替换所选字段，带把语言区域清除回 `null` 的显式逃生舱口。
- **输入：** `themeMode`、`locale`、`weekStartDay`（都可选，回退当前值）；`clearLocale`（默认 `false`）——为 `true` 时无论 `locale` 参数如何都强制结果 `locale` 为 `null`。
- **返回：** 新 `AppSettings`。
- **副作用：** 无。
- **算法：** `locale: clearLocale ? null : (locale ?? this.locale)`；另两个字段用普通 `?? this.x` 模式。
- **用法：** `state.copyWith(themeMode: mode)`、`state.copyWith(locale: locale, clearLocale: locale == null)`、`state.copyWith(weekStartDay: normalized)`——全部三个都在本文件上面的 `AppSettingsNotifier` 方法内。
- **备注：** 存在 `clearLocale` 参数是因为普通 `locale ?? this.locale` 模式永远无法表示"显式把语言区域设回 null"——没有它，`setLocale(null)` 会与"不改变语言区域"无法区分。
