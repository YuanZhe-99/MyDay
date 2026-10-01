# lib/shared/utils/status_colors.dart

`StatusColors`（1.6.0）是一个 `abstract final class`，提供两种自带含义的资金流向的静态颜色辅助：收入（正向）和支出（负向）。绿色和红色保留下来以便辨认，但它们由当前 `ColorScheme` 派生，遵循 Material 3 的自定义颜色指引，因此在浅色、深色和动态取色下都与界面其余部分处于同一色调家族。财务各页用它们绘制金额、余额、摘要卡片和趋势图（`finance_page.dart`、`accounts_page.dart`、`analysis_page.dart`、`category_detail_page.dart`）。配色方案本身见 [`../../app/theme.md`](../../app/theme.md)。

刻意与主题无关的固定颜色保持不变：分类图表调色板、账户类型颜色、亲密模块的周期人物调色板、BMI 与腰臀比色条，以及图片或提示条上的白色文字。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `StatusColors` | abstract final class | B | 状态颜色的命名空间；从不实例化。 |
| [`StatusColors.income`](#income) | 静态方法 | A | 收入与正余额的颜色。 |
| [`StatusColors.expense`](#expense) | 静态方法 | A | 支出与负金额的颜色。 |

## income

- **输入：** `scheme`——该颜色将绘制于其上的配色方案。
- **返回：** `Color`——`Colors.green.harmonizeWith(scheme.primary)`（`dynamic_color` 扩展）。
- **备注：** 协调只会让色相朝主色轻微偏移，因此与支出的红色并列时仍然读作绿色。

## expense

- **输入：** `scheme`。
- **返回：** `Color`——`scheme.error`。
- **备注：** 配色方案的 error 角色本身就是针对其亮度调好的红色。
