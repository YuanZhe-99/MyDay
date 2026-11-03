# lib/features/settings/widgets/home_widget_preview.dart

[`HomeWidgetSettingsPage`](../views/home_widget_settings_page.md) 上一种桌面小组件类型的实时预览（1.8.3）。它用与原生小组件相同的 payload（由 [`HomeWidgetService.payloadBuilders`](../../../shared/services/home_widget_service.md#payloadbuilders) 构建）绘制 2×2 小组件，文字大小乘以该类型的文字缩放，并施加其隐私选项，外层是来自 `myapps_widget_ui` 的共享 `WidgetPreviewSurface`。它以应用的配色近似原生小组件，并非任一平台的像素级复制。见 [桌面小组件](../../../../features/home-screen-widgets.md)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `HomeWidgetPreview`（构造函数） | const 构造函数（`HomeWidgetPreview`） | B | 由类型、其未遮罩的 payload 和其设置创建预览。 |
| [`build`](#build) | 方法（`HomeWidgetPreview`） | A | 构建居中并缩放的预览卡片。 |
| `_todo` | 方法（`HomeWidgetPreview`） | B | 用今天的日期条目绘制待办小组件。 |
| `_weight` | 方法（`HomeWidgetPreview`） | B | 绘制带迷你折线图的体重小组件。 |
| `_finance` | 方法（`HomeWidgetPreview`） | B | 绘制显示第一笔账单或「无账单」行的财务小组件。 |
| `_intimacy` | 方法（`HomeWidgetPreview`） | B | 绘制私密小组件；天数按本地日历日计算。 |
| `_timer` | 方法（`HomeWidgetPreview`） | B | 绘制计时器小组件（静态；原生小组件会计时）。 |
| `_header` | 方法（`HomeWidgetPreview`） | B | 绘制卡片标题：图标、标题和动作胶囊。 |
| `_labels` | 静态方法（`HomeWidgetPreview`） | B | 读取 payload 的标签。 |
| `_fill` | 静态方法（`HomeWidgetPreview`） | B | 替换标签中的 `{n}` 和 `{m}`。 |
| `_signed` | 静态方法（`HomeWidgetPreview`） | B | 用真正的减号格式化带符号的一位小数变化量。 |
| `_Text`（构造函数） | 构造函数（`_Text`） | B | 保存预览的主题、缩放和遮罩标志。 |
| `_Text.value` | 方法（`_Text`） | B | 返回数值；隐藏数值时返回 `••••`。 |
| `_Text.big` | 方法（`_Text`） | B | 构建大号数字。 |
| `_Text.body` | 方法（`_Text`） | B | 构建正文行；标题从不遮罩。 |
| `_Text.small` | 方法（`_Text`） | B | 构建次要行，只遮罩数字。 |
| `_Placeholder`（构造函数） | const 构造函数（`_Placeholder`） | B | 创建中性占位图。 |
| `_Placeholder.build` | 方法（`_Placeholder`） | B | 构建「MyDay」上方的图标。 |
| `_SparkPainter`（构造函数） | 构造函数（`_SparkPainter`） | B | 由体重和颜色创建迷你折线图绘制器。 |
| [`paint`](#paint) | 方法（`_SparkPainter`） | A | 绘制迷你折线图的折线。 |
| `shouldRepaint` | 方法（`_SparkPainter`） | B | 点或颜色变化时重绘。 |

**对账：** `grep -c 'Purpose:' lib/features/settings/widgets/home_widget_preview.dart` 报告 21，与上面 21 行匹配。字段和 `displayScale` 常量只带普通 `///` 注释或没有注释，不列出。

## 文档

### `Widget build(BuildContext context)` <a id="build"></a>
- **种类：** `HomeWidgetPreview` 的方法
- **来源：** `lib/features/settings/widgets/home_widget_preview.dart`（第 42 行）
- **用途：** 构建预览卡片。
- **输入：** `context`。
- **返回：** 居中并按 `displayScale`（0.85）缩放的卡片。
- **副作用：** 无。
- **算法：** payload 缺失或选*只显示图标*时绘制 `_Placeholder`。否则用主题、文字缩放和*隐藏数值*标志构建一个 `_Text` 辅助对象，并按 `kind` 分派到 `_todo`、`_weight`、`_finance`、`_intimacy` 或 `_timer`。内容放在 `FittedBox` 内一个 `WidgetPreviewSurface.smallSide` 大小的正方形中。
- **用法：** `HomeWidgetSettingsPage.build` 的每个分区一个。
- **备注：** payload 以未遮罩形式构建；遮罩在这里的 `_Text` 中进行，与原生 `mask` 规则一致。

### `void paint(Canvas canvas, Size size)` <a id="paint"></a>
- **种类：** `_SparkPainter`（一个 `CustomPainter`）的方法
- **来源：** `lib/features/settings/widgets/home_widget_preview.dart`（第 512 行）
- **用途：** 绘制迷你折线图的折线。
- **输入：** `canvas`、`size`。
- **返回：** 无。
- **副作用：** 在 `canvas` 上绘制。
- **算法：** 把点在其最小值与最大值之间缩放（平坦序列使用跨度 1），铺满整个宽度和高度，并以 2 px 宽描绘路径。
- **用法：** 体重预览（`_weight`）。
- **备注：** 少于两个点时不绘制。
