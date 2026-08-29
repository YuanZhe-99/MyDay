# lib/shared/widgets/shell_scaffold.dart

每个路由页面都在其中渲染的 `ShellRoute` 包装（`ShellScaffold`）——见 [架构 — 导航](../../../architecture.md#navigation)。它拥有外壳的导航，把同一份目的地列表渲染成底部 `NavigationBar` 或侧边 `NavigationRail`，取决于 `useNavigationRail`（见 [../utils/adaptive_layout.md#usenavigationrail](../utils/adaptive_layout.md#usenavigationrail)）；基于 `intimacyVisibilityProvider` 过滤亲密目的地（见 [intimacy_visibility.dart](../providers/intimacy_visibility.md)）；并在外壳挂载期间把 `ReminderService` 的 snackbar 回调接到当前 `BuildContext`。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `ShellScaffold`（构造函数） | 构造函数（`ShellScaffold`） | B | 创建壳脚手架实例。 |
| `createState` | 方法（`ShellScaffold`） | B | 为此组件创建可变状态对象。 |
| [`_activeRoutes`](#_activeroutes) | 方法（`_ShellScaffoldState`） | A | 返回当前可见性标志对应的路由列表。 |
| [`_destinations`](#_destinations) | 方法（`_ShellScaffoldState`） | A | 一次性描述外壳的目的地，含图标和标签。 |
| [`_currentIndex`](#_currentindex) | 方法（`_ShellScaffoldState`） | A | 为当前路由查找所选导航索引。 |
| `initState` | 方法（`_ShellScaffoldState`） | B | 接提醒 snackbar 回调。 |
| `dispose` | 方法（`_ShellScaffoldState`） | B | 解除提醒 snackbar 回调。 |
| `_showReminderSnackbar` | 方法（`_ShellScaffoldState`） | B | 把提醒通知显示为应用内 snackbar。 |
| [`build`](#build) | 方法（`_ShellScaffoldState`） | A | 构建脚手架主体和两种导航界面之一。 |
| `_ShellDestination`（构造函数） | 构造函数（`_ShellDestination`） | B | 创建外壳目的地实例。 |

`grep -c 'Purpose:' lib/shared/widgets/shell_scaffold.dart` 报告 10，与本文件中全部十个真实声明一致。未发现错挂或未文档化的声明。`build` 在 v1.4.0 被提升为 Tier A，此时它不再是单一的 `Scaffold`，而成为应用唯一的导航模式决策点。

## 文档

### `List<String> _activeRoutes(bool visible)` <a id="_activeroutes"></a>
- **种类：** `_ShellScaffoldState` 的私有方法
- **源：** `lib/shared/widgets/shell_scaffold.dart`（第 44 行）
- **用途：** 返回当前亲密可见性标志对应的、有序的外壳路由列表。
- **输入：** `visible`——当前 `intimacyVisibilityProvider` 的值。
- **返回：** `List<String>`——含 `/intimacy` 的 5 路由列表，或不含它的 4 路由列表。
- **副作用：** 无。
- **算法：** `visible ? _routes : _routesHidden`，其中 `_routes = ['/todo', '/finance', '/weight', '/intimacy', '/settings']`，`_routesHidden` 是去掉 `/intimacy` 的同一列表。
- **用法：** 由 `_currentIndex` 和 `build` 同时调用，因此索引计算与目的地选择始终基于同一份路由列表。
- **说明：** 这里的路由顺序必须与 `_destinations` 构建条目的顺序一致——两者依据同一个 `visible` 标志过滤，且都把 `/intimacy` 放在第四位。

### `List<_ShellDestination> _destinations(AppLocalizations l10n, bool visible)` <a id="_destinations"></a>
- **种类：** `_ShellScaffoldState` 的私有方法
- **源：** `lib/shared/widgets/shell_scaffold.dart`（第 54 行）
- **用途：** 一次性描述每个外壳目的地——轮廓图标、选中图标、本地化标签——顺序与 `_activeRoutes` 相同。
- **输入：** `l10n`；`visible`。
- **返回：** 5 个条目的 `List<_ShellDestination>`，`visible` 为 false 时为 4 个。
- **副作用：** 无。
- **算法：** 五个 `_ShellDestination` 值的列表字面量——待办、财务、体重、亲密、设置——其中亲密条目位于集合式 `if (visible)` 之后。
- **用法：** 在 `build` 中调用一次；返回的列表同时供给 `NavigationBar` 和 `NavigationRail` 分支。
- **说明：** 它的存在使得一个目的地不可能只出现在一种导航界面而不在另一种，也不可能在两者之间顺序不同。v1.4.0 之前目的地是内联写在唯一的 `NavigationBar` 里的；当同一份列表有两种渲染时，共享的来源正是阻止它们漂移的东西。可见性过滤只住在这里，因此导航栏免费继承它。

### `int _currentIndex(BuildContext context, bool visible)` <a id="_currentindex"></a>
- **种类：** `_ShellScaffoldState` 的私有方法
- **源：** `lib/shared/widgets/shell_scaffold.dart`（第 90 行）
- **用途：** 判断当前路由位置下哪个目的地应被高亮为选中。
- **输入：** `context`（用于读 `GoRouterState.of(context).uri.path`）；`visible`。
- **返回：** `int`——在 `_activeRoutes(visible)` 中匹配的索引，无匹配时为 `0`。
- **副作用：** 无。
- **算法：**
  1. 从 `GoRouterState.of(context).uri.path` 读当前位置路径。
  2. 取 `visible` 对应的有效路由列表。
  3. 遍历列表；返回位置 `startsWith` 的第一个路由的索引。
  4. 无匹配则返回 `0`。
- **用法：** 在 `build()` 中调用一次；结果作为 `selectedIndex` 传给被渲染的那种导航界面。
- **说明：** 使用 `startsWith` 而非精确相等，因此将来任何嵌套在 `/todo/...` 之下的子路由仍会高亮待办标签。回退到 `0` 意味着未匹配的位置会静默高亮待办，而不是不显示任何选中项。

### `Widget build(BuildContext context)` <a id="build"></a>
- **种类：** `_ShellScaffoldState` 的方法
- **源：** `lib/shared/widgets/shell_scaffold.dart`（第 159 行）
- **用途：** 构建外壳——路由子页面加上底部导航栏或侧边导航栏之一。
- **输入：** `context`。
- **返回：** 一个 `Scaffold`。
- **副作用：** 创建 UI 组件；点击目的地时 `select` 调用 `context.go`。
- **算法：**
  1. 读 `l10n`、watch `intimacyVisibilityProvider`，并从单一的 `visible` 标志解析出 `routes`、`destinations` 和 `index`。
  2. 定义 `select(i) => context.go(routes[i])`。
  3. 若 `!useNavigationRail(MediaQuery.sizeOf(context).width)`：返回一个 `Scaffold`，其 body 是路由子页面，其 `bottomNavigationBar` 是由 `destinations` 构建的 `NavigationBar`。
  4. 否则返回一个 `Scaffold`，其 body 是一个 `Row`：由同一份 `destinations` 构建的 `NavigationRail`、`VerticalDivider(width: 1)`，以及 `Expanded(child: widget.child)`。
- **用法：** 由 Flutter 调用；外壳由 `lib/app/router.dart` 中的 `ShellRoute` 构建（见 [../../app/router.md](../../app/router.md)）。
- **说明：** 出现哪种界面是 `useNavigationRail` 的**仅宽度**决策，刻意不是全应用的分栏规则——为什么导航栏不是分栏见 [../../../adaptive-layout.md](../../../adaptive-layout.md)。除提醒回调外这里没有任何状态，因此折叠设备会在下一帧把一种界面换成另一种，没有路由变化也没有状态丢失。导航栏分支中有两个细节值得它们的位置：`groupAlignment: 0` 让目的地居中，因为默认的顶部对齐是给位于前导菜单按钮或 FAB 之下的导航栏用的而这个两者都没有；以及 `LayoutBuilder` + `SingleChildScrollView` + `ConstrainedBox(minHeight:)` + `IntrinsicHeight` 包装让导航栏滚动而不是溢出，因为导航栏可能出现在高度紧凑的窗口上（手机横持是 915 x 412，而五个带标签的目的地大约要 370 逻辑像素）。
