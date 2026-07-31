# 亲密

模型来源：`lib/features/intimacy/models/intimacy_record.dart`。服务：`lib/features/intimacy/services/{body_metrics,cycle_predictor,intimacy_storage}.dart`。视图：`views/body_page.dart`、`views/intimacy_page.dart`。完整字段列表见 [数据格式](../data-formats.md#intimacy--intimacy_datajson)，罩杯/PSI/周期预测算法见 [身体指标](../algorithms/body-metrics.md)。

## 默认隐藏

亲密模块**默认隐藏**，可以从设置 → 隐私启用。隐藏它**不**删除数据——它纯粹是可见性开关（`lib/shared/providers/intimacy_visibility.dart`），且 `/intimacy` 路由无论可见性状态如何都存在于路由器中（见 [架构](../architecture.md#navigation)）。

## 模型

- **`Partner`**：可选 emoji/图像、关系开始/结束日期、可选 `body`（`BodyProfile`）、`modifiedAt`。身体档案在同步中与伴侣记录**原子**同行——身体编辑走 `Partner.copyWith`，它会 bump 伴侣自己的 `modifiedAt`。
- **`BodyProfile`**：性别中立、全部可选——胸/腰/臀 cm（仅伴侣；用户自己的在体重模块）、下胸围 cm、罩杯标准代码（`eu`/`fr_es`/`jp`/`uk`/`us`/`au_nz`）、`cycleEnabled` 和 `showCycleOnCalendar` 标志（都默认**关**），以及 PSI 参考指数的勃起长度/根部周长/前端周长 cm。空档案序列化为完全缺席（不写 `{}`）。
- **`CycleRecord`**：一次月经周期开始日期——`id`、可选 `personId`（`null` = 用户，否则是伴侣 id）、本地日历 `date`（`yyyy-MM-dd`，无时间）、`modifiedAt`。只有增/删，按 id 合并使删除同步（见 [三方合并](../algorithms/three-way-merge.md#deletionunion-semantics)）。
- **`Toy`**：可选 emoji/图像、购买/退役日期、购买链接、价格、成本摘要辅助、`modifiedAt`。
- **`Position`**：名称、可选 emoji、`modifiedAt`。
- **`IntimacyRecord`**：独自/伴侣类型、地点、伴侣 id、玩具 id、姿势 id、愉悦度、时长、带 x100/x1 单位的可选抽插次数、日期时间、备注、高潮/色情/安全套标志、`modifiedAt`。
- **`TimerHistoryEntry`**：计时器开始、时长、可选 x100/x1 抽插次数，带旧 `end` 迁移（旧条目存储 `end` 时间戳而不是时长）。
- **`IntimacyTimerSession`**：持久化的激活/暂停秒表会话，带原始开始时间、上次恢复时间、累积已流逝时间、运行标志、可选 x100/x1 抽插次数，以及供 LWW 同步的自己的独立 `timerSessionModifiedAt`。
- **`IntimacyData`**：伴侣、玩具、姿势、记录、计时器历史、激活计时器会话、用户的 `userBody` 档案（带自己的 `userBodyModifiedAt` LWW 时间戳，与计时器会话相同模式）、用户和伴侣的 `cycleRecords`、计时器保留设置、伴侣/玩具排序模式/自定义顺序和 `settingsModifiedAt`。

## UI

UI 支持记录列表排序/过滤、带显示全部面板的受限默认近期历史列表、伴侣/玩具/姿势管理、默认姿势导入、伴侣分手状态、玩具退役状态、玩具管理激活成本摘要、全部/激活/退役玩具的聚合玩具成本总览、激活/全部每日成本趋势图、最终退役玩具成本、单玩具总/每日成本摘要、逐玩具每日成本副标题、从新记录选择器排除非激活伴侣/玩具、下面描述的整合趋势图、跟随全局周起始日设置的周分组、安全套跟踪，以及一个带非负抽插计数器的秒表计时器，其历史和中断的激活/暂停会话存储在 `intimacy_data.json` 中。

伴侣和玩具详情页显示带平均愉悦度、平均时长和平均抽插速率的摘要卡片；玩具页添加总成本和每日成本。

## 整合趋势图（v1.3.2）

`IntimacyTrendChart`（`lib/features/intimacy/widgets/intimacy_trend_chart.dart`）是模块唯一的记录指标图。它取代了四个独立图表——主页上的愉悦度+频率和时长+抽插次数，外加伴侣/玩具详情页上两者的近乎逐字副本——现在同一个组件服务每个表面。玩具成本总览页上的玩具每日成本趋势刻意*不*属于它：它在对数刻度上、带自己的全部/激活/退役范围选择器，把金额绘制在投影日期时间线上。

五个可选指标：

| 指标 | Id | 单位 | 备注 |
|---|---|---|---|
| 愉悦度 | `pleasure` | 1-5 | 主题主色 |
| 频率 | `frequency` | 记录/周 | 从记录之间的间隔派生，不是从任何单条记录 |
| 时长 | `duration` | 分钟 | |
| 抽插次数 | `thrustCount` | 次数 | `thrustCount * thrustCountUnit` |
| **抽插速率** | `thrustRate` | 抽插/分钟 | 每条记录内的平均速率；只有**同时**有时长和抽插次数的记录贡献 |

每个指标画两次：薄实线是原始逐记录值，虚线是 EWMA 平滑曲线，其平滑因子适配记录之间的真实间隔（`alpha = 1 - exp(-dt/tau)`）。平滑在*所有*记录上预热，但只在所选范围内发出点，因此改变范围绝不改变曲线形状。

因为这些指标量纲不兼容，绘图区是无单位 0-1 空间：每个所选指标对照自己的吸附天花板归一化。前两个所选指标（按上表顺序）拥有标注的左右轴，以系列自己的颜色用真实单位绘制；任何更多指标无轴绘制并从工具提示读取。所选指标芯片兼作图例，因此没有单独图例行。图表拒绝清除最后一个所选指标，因此它绝不渲染为空。

指标选择和时间范围作为 `chartSettings` 在 `intimacy_data.json` 中持久化和同步——见 [数据格式](../data-formats.md#intimacy--intimacy_datajson)。一个选择被每个表面共享：主页拥有写入（它以 UTC bump `settingsModifiedAt` 并保存），详情页通过记录和排序回调已经使用的同一回调链上报变更。

## 计时器/秒表会话持久化

计时器控件包括 **+100、+50、+10 和 -100**。可被 100 整除的计数存储为 `x100` 估计；非 100 倍数计数存储为精确 `x1` 值（`IntimacyRecord`/`TimerHistoryEntry`/`IntimacyTimerSession` 上的 `thrustCountUnit` 总是规范化为恰好 `1` 或 `100`——任何其他存储值在读取时被强转为 `100`）。计时器有一个由 `storage_config.json` 和 `wakelock_plus` 支撑的记住的仅本地保持屏幕唤醒开关；它**不**同步。

会话恢复行为：

- 停止并保存的计时器会话被清除。
- 停止但未保存和暂停的会话恢复为**暂停**。
- 运行中的会话**从挂钟时间恢复**——`IntimacyTimerSession.elapsedAt(now)` 运行时计算 `accumulated + (now - startedAt)`，因此即使应用重启后已流逝时间也反映真实挂钟时间，而不是过期的内存计数器。
- 历史行可以确认为运行中会话并恢复，这会移除该历史行。

## 已删除伴侣处理

删除伴侣也会删除该伴侣的**周期记录**，但刻意**保留**带现在悬空 `partnerId` 的历史活动（`IntimacyRecord`）行。记录块和编辑对话框容忍那个已删除伴侣引用，保存未触碰的编辑会保留存储的 id，而不是丢弃或重新分配。这与应用别处应用的"不为瞬态 UI 便利销毁历史"原则相同（如财务中的强制余额交易）。

## 身体层（v1.2.4）

性别中立、完全可选、处处自动保存：

- 管理菜单有第四个**身体**条目，打开 `views/body_page.dart`（`BodySettingsPage`），它在用户模式下托管共享的 `widgets/body_section.dart`（`BodySectionView`）。伴侣详情页渲染**记录 | 身体**标签；记录标签是既有的摘要/趋势/列表内容，身体标签是伴侣模式下同一个共享组件。玩具详情页绝不获得身体标签。把伴侣标记为分手（分手操作，或新设结束日期）会自动关闭该伴侣的显示主页日历周期选项；用户之后可以手动重新启用。
- **用户胸/腰/臀**各自独立显示来自体重记录的最近正值（`WeightData.effectiveMeasurementsUpTo`）。编辑它们先显示警告：变更会同步到体重模块并创建新体重记录，带"不再提醒我"复选框（退出键：`storage_config.json` 中的 `intimacyBodyWeightSyncWarningDisabled`，由身体页底部的开关镜像）。确认的编辑批次防抖为恰好**一条**新 `WeightRecord`（复用最近体重，没有则为 0，加显示的胸/腰/臀）；历史体重记录绝不修改。伴侣测量住在 `Partner.body` 上，绝不碰体重模块。
- 显示腰和臀都为正时，所有身体界面显示只读腰臀比（`WeightData.calculateWaistHipRatio`）。
- **罩杯估算**（`services/body_metrics.dart`）和 **PSI 参考指数**在 [身体指标](../algorithms/body-metrics.md) 中深入覆盖。
- **周期跟踪**（`services/cycle_predictor.dart`）**默认关**（`BodyProfile.cycleEnabled = false`），在 [身体指标](../algorithms/body-metrics.md#cycle-prediction) 中深入覆盖。`widgets/cycle_calendar.dart` 渲染逐人指示器条/点（实心月经、半透明生育窗口、淡色阶段、排卵点、实心 = 实际 / 空心 = 预测开始标记）、图例和强制的不避孕/非医疗免责声明。
- **主页日历**为每个启用 `showCycleOnCalendar` 的人叠加周期（用户 + 伴侣，默认禁用），日数字下每人一条细指示器行（上限 3），带稳定调色板颜色（用户 = 槽 0，伴侣按排序 id）、图例和逐人所选日条。

## 相关页面

- [数据格式](../data-formats.md) — 上面每个模型的精确 JSON 形态。
- [身体指标](../algorithms/body-metrics.md) — 完整细节的罩杯估算、PSI 和周期预测。
- [三方合并](../algorithms/three-way-merge.md) — 周期记录并集/删除语义。
- [体重](weight.md) — 用户自己的胸/腰/臀测量实际所在之处。
