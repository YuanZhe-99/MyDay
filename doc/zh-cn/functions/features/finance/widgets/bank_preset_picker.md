# lib/features/finance/widgets/bank_preset_picker.dart

添加或编辑财务 [`Account`](../../../../features/finance.md#model) 时使用的银行/金融科技预设选择器底部面板：`showBankPresetPicker` 打开一个 `DraggableScrollableSheet`，要么列出分入按国家标签的预设，要么显示实时搜索结果，解析为所选 `BankPreset`（来自 `lib/features/finance/services/bank_preset_service.dart`）或被关闭时为 `null`。提供此组件渲染的 250+ 预设的 `BankPresetService` 见 [财务](../../../../features/finance.md#bankpresetservice)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`showBankPresetPicker`](#showbankpresetpicker) | 顶层函数 | B | 作为模态底部面板显示银行预设选择器并返回所选预设。 |
| `_BankPickerSheet`（构造函数） | 构造函数（`_BankPickerSheet`） | B | 创建银行选择器面板实例。 |
| `createState` | 方法（`_BankPickerSheet`） | B | 创建可变 `_BankPickerSheetState`。 |
| `initState` | 方法（`_BankPickerSheetState`） | B | 启动初始分组预设加载。 |
| `_load` | 方法（`_BankPickerSheetState`） | B | 加载并按国家分组所有银行预设。 |
| `_onSearch` | 方法（`_BankPickerSheetState`） | B | 用户输入时运行实时预设搜索，为空时清除搜索模式。 |
| `dispose` | 方法（`_BankPickerSheetState`） | B | 释放搜索文本控制器。 |
| `build` | 方法（`_BankPickerSheetState`） | B | 渲染手柄、标题、搜索字段，以及国家标签或搜索结果。 |
| `_BankTile`（构造函数） | 构造函数（`_BankTile`） | B | 为一个预设创建银行块实例。 |
| `build` | 方法（`_BankTile`） | B | 渲染一个银行/金融科技行，带 logo、标题和强调色点。 |
| [`_parseColor`](#parsecolor) | 静态方法（`_BankTile`） | A | 把银行预设的十六进制颜色字符串解析为 `Color`，失败默认灰色。 |

`grep -c 'Purpose:' lib/features/finance/widgets/bank_preset_picker.dart` 报告 11，与本文件全部十一个真实声明匹配。未发现错附或未文档化声明。

## 文档

### `static Color _parseColor(String hex)` <a id="parsecolor"></a>
- **种类：** `_BankTile` 的静态方法
- **来源：** `lib/features/finance/widgets/bank_preset_picker.dart`（第 311 行）
- **用途：** 把 `BankPreset.color` 十六进制字符串（如 `'#4285F4'`，`BankPresetService` 在预设无颜色时默认为 `'#888888'`）转换为 Flutter `Color`，任何解析失败字符串回退灰色。
- **输入：** `hex` — 颜色字符串，预期 `'#RRGGBB'`（6 个十六进制数字）或已带前缀的 `'#AARRGGBB'`（8 个十六进制数字）；前导 `#` 可选。
- **返回：** `Color` — 解析的颜色，解析抛出时为 `Colors.grey`。
- **副作用：** 无。
- **算法：**
  1. `hex`（含剥离前的前导 `#`）恰好 7 个字符长——即 `'#RRGGBB'` 形式——时，向缓冲区前置 `'ff'`，使颜色完全不透明。
  2. 剥离 `hex` 的任何前导 `#` 并把其余部分追加进缓冲区。
  3. 把缓冲区的字符串解析为 base-16 整数并从它构造 `Color(...)`。
  4. 捕获任何异常（格式错误的十六进制、错误数字位数等）并返回 `Colors.grey`，而不是让错误传播。
- **用法：**
  ```dart
  final color = _parseColor(bank.color);
  return ListTile(
    leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), ...),
    // ...
    trailing: Container(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
  ```
  （`_BankTile.build`，同一文件——解析的颜色同时着染前导头像和尾部强调点。）
- **备注：** `'#RRGGBB'`-vs-已有 alpha 检查在*未剥离*字符串长度上做（7，数 `#`），因此它正确识别 `BankPresetService` 产生的每个 `BankPreset.color` 值（总是 `'#RRGGBB'`，如 `'#888888'` 默认）。不过它对其他形态不完全稳健：无前导 `#` 的 6 数字字符串长度也是 6（不是 7），因此会跳过 `'ff'` 前置并被解析为裸 24 位值——`Color(...)` 随后会把顶部字节（本意是 alpha）读作 `0x00`，产生完全不透明为全透明的颜色而不是抛出，因此 `try`/`catch` 不会捕获它。这个边界情形实践中不发生，因为此函数收到的每个颜色都已带前导 `#`。
