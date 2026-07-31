# lib/app/router.dart

定义 `MyDayApp`（`app/app.dart`）使用的唯一 `go_router` `GoRouter` 实例。它如何映射到 `ShellScaffold` 中的底部导航栏见 [../../architecture.md#navigation](../../architecture.md#navigation)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`appRouter`](#approuter) | 顶层变量（`GoRouter`） | A | 配置应用的外壳路由和五个底部导航目的地。 |

`grep -c 'Purpose:' lib/app/router.dart` 报告 0——本文件完全没有 `/// Purpose:` 文档注释，但它确实含一个真实声明：顶层 `final appRouter = GoRouter(...)` 配置对象。按校验规则这是未文档化但真实的声明，不是错附；这里列为 Tier A，因为它编码应用的实际路由结构（五个真实路由加外壳包装器），不是平凡的一行转发器。

**对账：** `grep -c 'Purpose:' lib/app/router.dart` 报告 0，而表格有 1 行。`appRouter` 是从集合字面量初始化的顶层 `GoRouter` 变量，不带 `/// Purpose:` 块，但它是真实声明和文件的整个公共表面，因此被列出。

## 文档

### `final appRouter = GoRouter(...)` <a id="approuter"></a>
- **种类：** 顶层变量（`GoRouter` 实例）
- **来源：** `lib/app/router.dart`（第 10 行）
- **用途：** 构建应用唯一的 `GoRouter`，带一个把每个屏幕包在 `ShellScaffold` 中并提供底部导航目的地的 `ShellRoute`。
- **输入：** 无——路由表是在文件加载时构建的静态字面量。
- **返回：** 被 `app/app.dart` 中 `MaterialApp.router(routerConfig: appRouter)` 消费的 `GoRouter` 值。
- **副作用：** 除构建路由器对象图外无。
- **算法：**
  1. 设 `initialLocation: '/todo'`。
  2. 声明一个 `builder` 把路由的 `child` 组件包在 `ShellScaffold` 中的 `ShellRoute`。
  3. 在该外壳下声明五个无路径参数的 `GoRoute`：`/todo` → `TodoPage`、`/finance` → `FinancePage`、`/weight` → `WeightPage`、`/intimacy` → `IntimacyPage`、`/settings` → `SettingsPage`。
- **用法：**
  ```dart
  return MaterialApp.router(
    // ...
    routerConfig: appRouter,
  );
  ```
  （`lib/app/app.dart`，`MyDayApp.build` 内。）
- **备注：** 即使亲密模块从设置中隐藏，`/intimacy` 也总是存在于路由表——可见性由 `ShellScaffold` 过滤它显示哪些目的地来强制（见 `shared/widgets/shell_scaffold.dart`），而不是移除路由。此路由器上没有重定向/守卫逻辑；任何能获得 `BuildContext` 的代码都可以 `context.go('/intimacy')`，无论可见性开关如何。
