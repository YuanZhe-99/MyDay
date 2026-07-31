# lib/features/intimacy/views/body_page.dart

`BodySettingsPage` 是从亲密管理菜单的**身体**条目打开的整页包装器（见 [亲密](../../../../features/intimacy.md#the-body-layer-v124)），在**用户模式**下托管共享 `BodySectionView`（`lib/features/intimacy/widgets/body_section.dart`）。所有实际身体档案/罩杯/周期逻辑都在 `BodySectionView` 和它调用的服务（`services/body_metrics.dart`、`services/cycle_predictor.dart`——见 [身体指标](../../../../algorithms/body-metrics.md)）中；本文件只拥有 `userBody`/`cycleRecords` 的薄本地副本，使页面能在编辑时立即重建，并把每次变更向上转发给两个回调，使调用方（亲密管理视图）能持久化它。用户的稳定日历颜色总是来自 `cyclePersonColor(personId: null, ...)`，定义在 `widgets/cycle_calendar.dart` 并在[该页面](../widgets/cycle_calendar.md)文档化，它为 `personId: null` 返回调色板槽 0。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `BodySettingsPage`（构造函数） | 构造函数（`BodySettingsPage`） | B | 从当前用户身体档案、周期记录和变更回调创建身体设置页实例。 |
| `BodySettingsPage.createState` | 方法（`BodySettingsPage`） | B | 创建可变 `_BodySettingsPageState`。 |
| `_BodySettingsPageState.initState` | 方法（`_BodySettingsPageState`） | B | 把 `widget.userBody`/`widget.cycleRecords` 复制进本地状态，使编辑能直接重建本页。 |
| `_BodySettingsPageState.build` | 方法（`_BodySettingsPageState`） | B | 渲染脚手架和用户模式下的单个 `BodySectionView`，接两个变更回调。 |

`grep -c 'Purpose:' lib/features/intimacy/views/body_page.dart` 报告 4，与上面计数的全部 4 个真实声明精确匹配（0 个 Tier A、4 个 Tier B）。每个 `/// Purpose:` 块都恰好位于其文档化的真实声明正上方——未发现错附块，也未发现未文档化声明。文件没有其他函数、方法、getter 或 setter；两个类的字段（`BodySettingsPage` 上的 `userBody`、`cycleRecords`、两个回调；`_BodySettingsPageState` 上的 `_userBody`、`_cycleRecords`）是普通数据持有者，不计为声明。

## 文档

本文件没有 Tier A 声明。全部四个声明是简单转发构造函数、`createState()`、把两个构造函数值复制进可变状态的平凡 `initState()`，以及纯组件组合的 `build()` 方法——把身体档案逻辑和周期日历渲染都委托给 `BodySectionView`/`CycleCalendar`，而不是在这里重新实现任何东西。值得注意的是，`build()` 的两个 `onProfileChanged`/`onCycleRecordsChanged` 回调在调用 `setState` 前都用 `mounted` 守卫（未挂载时回退裸字段赋值），然后把新值转发给 `widget.onUserBodyChanged`/`widget.onCycleRecordsChanged`——这是常规防御性 `setState` 处理，不是值得单独条目的独特算法逻辑。

## 相关页面

- [亲密](../../../../features/intimacy.md#the-body-layer-v124) — 本页打开的进入点身体层，包括复用同一 `BodySectionView` 的伴侣模式"记录 | 身体"标签。
- [身体指标](../../../../algorithms/body-metrics.md) — 罩杯估算、PSI 和周期预测，都从 `BodySectionView` 调用，不是本文件。
- [`cycle_calendar.dart`](../widgets/cycle_calendar.md) — `cyclePersonColor`（这里用于用户槽 0 颜色）以及 `BodySectionView` 为周期跟踪渲染的日历/图例组件。
