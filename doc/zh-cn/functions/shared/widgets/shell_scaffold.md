# lib/shared/widgets/shell_scaffold.dart

每个路由页面都在其中渲染的 `ShellRoute` 包装（`ShellScaffold`）——见 [架构 — 导航](../../../architecture.md#navigation)。它拥有底部 `NavigationBar`、基于 `intimacyVisibilityProvider` 过滤亲密目的地（见 [intimacy_visibility.dart](../providers/intimacy_visibility.md)），并在壳挂载期间把 `ReminderService` 的 snackbar 回调接到当前 `BuildContext`。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `ShellScaffold`（构造函数） | 构造函数（`ShellScaffold`） | B | 创建壳脚手架实例。 |
| `createState` | 方法（`ShellScaffold`） | B | 为此组件创建可变状态对象。 |
| [`_activeRoutes`](#_activeroutes) | 方法（`_ShellScaffoldState`） | A | 返回当前可见性标志的底部导航路由列表。 |
| [`_currentIndex`](#_currentindex) | 方法（`_ShellScaffoldState`） | A | 为当前路由查找所选底部导航索引。 |
| `initState` | 方法（`_ShellScaffoldState`） | B | 接提醒 snackbar 回调。 |
| `dispose` | 方法（`_ShellScaffoldState`） | B | 解除提醒 snackbar 回调。 |
| `_showReminderSnackbar` | 方法（`_ShellScaffoldState`） | B | 把提醒通知显示为应用内 snackbar。 |
| `build` | 方法（`_ShellScaffoldState`） | B | 构建脚手架主体和底部导航栏。 |

`grep -c 'Purpose:' lib/shared/widgets/shell_scaffold.dart` 报告 8，与本文件全部八个真实声明匹配。未发现错附或未文档化声明。

## 文档

### `List<String> _activeRoutes(bool visible)` <a id="_activeroutes"></a>
- **种类：** `_ShellScaffoldState` 的私有方法
- **来源：** `lib/shared/widgets/shell_scaffold.dart`（第 37 行）
- **用途：** 返回当前亲密可见性标志的有序底部导航路由列表。
- **输入：** `visible` — 当前 `intimacyVisibilityProvider` 值。
- **返回：** `List<String>` — 5 路由列表（带 `/intimacy`）或 4 路由列表（不带）。
- **副作用：** 无。
- **算法：** `visible ? _routes : _routesHidden`，`_routes = ['/todo', '/finance', '/weight', '/intimacy', '/settings']`，`_routesHidden` 是不带 `/intimacy` 的相同列表。
- **用法：** 从 `_currentIndex` 和 `build` 两者调用，使索引计算和渲染目的地始终对同一路由列表一致。
- **备注：** 这里的路由顺序必须匹配 `build()` 中 `NavigationDestination` 组件构建顺序——两者手动保持同步（除这两个静态列表外无单一共享源）。

### `int _currentIndex(BuildContext context, bool visible)` <a id="_currentindex"></a>
- **种类：** `_ShellScaffoldState` 的私有方法
- **来源：** `lib/shared/widgets/shell_scaffold.dart`（第 44 行）
- **用途：** 确定当前路由位置应高亮哪个底部导航目的地为选中。
- **输入：** `context`（读取 `GoRouterState.of(context).uri.path`）；`visible`。
- **返回：** `int` — `_activeRoutes(visible)` 中的匹配索引，无匹配时 `0`。
- **副作用：** 无。
- **算法：**
  1. 从 `GoRouterState.of(context).uri.path` 读取当前位置路径。
  2. 获取 `visible` 的活动路由列表。
  3. 遍历列表；返回位置 `startsWith` 的第一条路由的索引。
  4. 无路由匹配返回 `0`。
- **用法：** 从 `build()` 以 `selectedIndex: _currentIndex(context, visible)` 调用。
- **备注：** 用 `startsWith` 而非精确相等，使未来嵌套在如 `/todo/...` 下的任何子路由仍高亮 Todo 标签。回退 `0` 意味着未匹配位置静默高亮 Todo 而非不显示选择。
