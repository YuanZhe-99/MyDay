# lib/shared/providers/intimacy_visibility.dart

亲密标签/模块是否可见的 Riverpod 状态。切换总存在于设置中；关闭它隐藏标签但绝不删除 `intimacy_data.json`。被 `ShellScaffold`（`shared/widgets/shell_scaffold.dart`）消费以决定显示哪些底部导航目的地，被设置页用于渲染/持久化切换。见 [架构 — 状态管理](../../../architecture.md#state-management)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`IntimacyVisibility`（构造函数）](#intimacyvisibility-new) | 构造函数（`IntimacyVisibility`） | A | 创建亲密可见性值。 |
| [`copyWith`](#copywith) | 方法（`IntimacyVisibility`） | A | 创建此值的副本并替换所选字段。 |
| [`IntimacyVisibilityNotifier`（构造函数）](#intimacyvisibilitynotifier-new) | 构造函数（`IntimacyVisibilityNotifier`） | A | 启动通知器并开始加载持久化可见性。 |
| [`_loadPersistedState`](#_loadpersistedstate) | 方法（`IntimacyVisibilityNotifier`） | A | 把持久化可见性从 `TodoStorage` 加载进状态。 |
| [`setVisible`](#setvisible) | 方法（`IntimacyVisibilityNotifier`） | A | 从设置切换可见性并持久化。 |
| `intimacyVisibilityProvider` | 顶层变量（`StateNotifierProvider`） | B | 向组件树暴露 `IntimacyVisibilityNotifier`。 |

`grep -c 'Purpose:' lib/shared/providers/intimacy_visibility.dart` 报告 5，与上面五个 `Purpose:` 文档化声明匹配。第六行 `intimacyVisibilityProvider` 是**完全**无文档块（未文档化，非错附）的真实顶层声明——一行 `StateNotifierProvider<IntimacyVisibilityNotifier, IntimacyVisibility>((ref) => IntimacyVisibilityNotifier())` 工厂，平凡到尽管未文档化仍归为 Tier B。

**对账：** `grep -c 'Purpose:' lib/shared/providers/intimacy_visibility.dart` 报告 5，与上面 6 行中的 5 行精确匹配。额外行是 `intimacyVisibilityProvider`，`StateNotifierProvider` 顶层变量：无 `Purpose:` 块，但它是文件的公共入口点。

## 文档

### `const IntimacyVisibility({this.visible = false})` <a id="intimacyvisibility-new"></a>
- **种类：** `IntimacyVisibility` 的 const 构造函数
- **来源：** `lib/shared/providers/intimacy_visibility.dart`（第 18 行）
- **用途：** 创建默认隐藏的不可变可见性值。
- **输入：** `visible`（可选，默认 `false`）。
- **返回：** 新 `IntimacyVisibility` 实例。
- **副作用：** 无。
- **算法：** 普通字段初始化 const 构造函数。
- **用法：** `const IntimacyVisibility()` 是传给 `IntimacyVisibilityNotifier` 中 `StateNotifier` 构造函数的初始状态。
- **备注：** 默认关闭匹配新安装的文档化行为；既有数据使 `_loadPersistedState` 在构造后不久把此默认覆盖为 `true`。

### `IntimacyVisibility copyWith({bool? visible})` <a id="copywith"></a>
- **种类：** `IntimacyVisibility` 的方法
- **来源：** `lib/shared/providers/intimacy_visibility.dart`（第 25 行）
- **用途：** 创建此值的副本，`visible` 可选替换。
- **输入：** `visible`（可选；省略时回退 `this.visible`）。
- **返回：** 新 `IntimacyVisibility`。
- **副作用：** 无。
- **算法：** `IntimacyVisibility(visible: visible ?? this.visible)`。
- **用法：** `state = state.copyWith(visible: visible);`（`setVisible`，同文件）。
- **备注：** 无。

### `IntimacyVisibilityNotifier() : super(const IntimacyVisibility())` <a id="intimacyvisibilitynotifier-new"></a>
- **种类：** `IntimacyVisibilityNotifier` 的构造函数（扩展 `StateNotifier<IntimacyVisibility>`）
- **来源：** `lib/shared/providers/intimacy_visibility.dart`（第 36 行）
- **用途：** 用默认隐藏状态初始化通知器，然后异步开始加载持久化值。
- **输入：** 无。
- **返回：** 新 `IntimacyVisibilityNotifier`。
- **副作用：** `super(...)` 后立即调用 `_loadPersistedState()`（即发即忘）。
- **算法：** 把 `state` 初始化为 `const IntimacyVisibility()`（隐藏），然后不 await 地调用 `_loadPersistedState()`。
- **用法：** 只被 `intimacyVisibilityProvider` 的工厂实例化：`StateNotifierProvider<IntimacyVisibilityNotifier, IntimacyVisibility>((ref) => IntimacyVisibilityNotifier())`。
- **备注：** 异步加载解析前对 `ref.watch(intimacyVisibilityProvider)` 的任何读取看到隐藏默认，而非持久化值。

### `Future<void> _loadPersistedState()` <a id="_loadpersistedstate"></a>
- **种类：** `IntimacyVisibilityNotifier` 的私有方法
- **来源：** `lib/shared/providers/intimacy_visibility.dart`（第 45 行）
- **用途：** 读取持久化亲密可见标志并应用到状态。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 读取 `TodoStorage.getIntimacyVisible()`；用新 `IntimacyVisibility(visible: visible)` 覆盖 `state`。
- **算法：** `await TodoStorage.getIntimacyVisible()`，然后设 `state`。
- **用法：** 从构造函数调用一次，绝不被功能代码直接调用。
- **备注：** 覆盖整个状态对象而非用 `copyWith`，但效果相同，因为 `IntimacyVisibility` 只有一个字段。

### `void setVisible(bool visible)` <a id="setvisible"></a>
- **种类：** `IntimacyVisibilityNotifier` 的方法
- **来源：** `lib/shared/providers/intimacy_visibility.dart`（第 56 行）
- **用途：** 从设置页切换亲密模块可见性并持久化选择。
- **输入：** `visible`。
- **返回：** 无。
- **副作用：** 经 `copyWith` 更新 `state`；调用 `TodoStorage.setIntimacyVisible(visible)`（即发即忘，不 await）。
- **算法：** `state = state.copyWith(visible: visible); TodoStorage.setIntimacyVisible(visible);`
- **用法：**
  ```dart
  ref.read(intimacyVisibilityProvider.notifier).setVisible(value);
  ```
  （`lib/features/settings/views/settings_page.dart`，亲密切换的 `onChanged`，关闭切换时在页面自己的确认隐藏对话框之后。）
- **备注：** 不删除 `intimacy_data.json` 或任何亲密记录；它只翻转 `ShellScaffold` 消费的 UI 可见性标志。
