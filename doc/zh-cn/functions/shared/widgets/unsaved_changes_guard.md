# lib/shared/widgets/unsaved_changes_guard.dart

应用每个编辑对话框/表单使用的共享"丢弃未保存更改？"模式（Todo 增/改任务、财务账户/类别/订阅/汇率、亲密添加记录、体重编辑记录）。`UnsavedChangesGuard` 包装 `PopScope` 并暴露 `UnsavedChangesController`，使被包装构建器能经同一丢弃确认路径触发自己的弹出。`formSignature`/`_formValueSignature` 构建表单字段值的可比较字符串快照，使调用方能通过比较初始签名与当前签名检测"是否有任何实际变化"。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `maybeDiscardAndPop`（抽象） | 方法（`UnsavedChangesController`） | B | 弹出前确认挂起更改能否被丢弃。 |
| `pop`（抽象） | 方法（`UnsavedChangesController`） | B | 弹出路由（契约声明）。 |
| `UnsavedChangesGuard`（构造函数） | 构造函数（`UnsavedChangesGuard`） | B | 创建未保存更改守卫实例。 |
| `createState` | 方法（`UnsavedChangesGuard`） | B | 为此组件创建可变状态对象。 |
| `build` | 方法（`_UnsavedChangesGuardState`） | B | 构建 `PopScope` 包裹子树。 |
| [`maybeDiscardAndPop`](#maybediscardandpop) | 方法（`_UnsavedChangesGuardState`） | A | 需要时显示丢弃确认对话框，然后弹出。 |
| [`pop`](#pop) | 方法（`_UnsavedChangesGuardState`） | A | 允许下次弹出并在下一帧执行它。 |
| [`showDiscardChangesDialog`](#showdiscardchangesdialog) | 顶层函数 | A | 显示共享丢弃更改确认对话框。 |
| [`formSignature`](#formsignature) | 顶层函数 | A | 从表单字段值构建可比较签名字符串。 |
| [`_formValueSignature`](#_formvaluesignature) | 顶层函数 | A | 把一个表单字段值序列化为签名片段。 |

`grep -c 'Purpose:' lib/shared/widgets/unsaved_changes_guard.dart` 报告 10，与本文件全部十个真实声明匹配。未发现错附或未文档化声明。两个抽象 `UnsavedChangesController` 方法这里归为 Tier B，因为它们不带自己的实现——真实逻辑住在 `_UnsavedChangesGuardState` 的具体覆盖中，下面文档化为 Tier A。`showDiscardChangesDialog` 和 `formSignature` 也按"`shared/` 下所有顶层函数"规则为 Tier A，即使它们很短，因为本文件住在 `shared/widgets/` 下。

## 文档

### `Future<bool> maybeDiscardAndPop<T extends Object?>([T? result])`（具体覆盖） <a id="maybediscardandpop"></a>
- **种类：** `_UnsavedChangesGuardState` 的方法（实现 `UnsavedChangesController`）
- **来源：** `lib/shared/widgets/unsaved_changes_guard.dart`（第 75 行）
- **用途：** 决定受守卫路由现在能否弹出，只在有未保存更改时显示丢弃确认对话框。
- **输入：** `result` — 弹出继续时传给 `Navigator.pop` 的值。
- **返回：** `Future<bool>` — 路由实际被弹出 `true`，否则 `false`。
- **副作用：** 可能显示丢弃确认对话框（`showDiscardChangesDialog`）；可能调用 `pop(result)`。
- **算法：**
  1. 已 `_closing` 或 `_confirming` 时立即返回 `false`（重入守卫）。
  2. `widget.hasUnsavedChanges()` 为 `false` 时调用 `pop(result)` 并返回 `true`——无需对话框。
  3. 否则设 `_confirming = true`、await `showDiscardChangesDialog(context)`、然后清除 `_confirming`。
  4. await 期间组件被卸载、或对话框结果不是恰好 `true` 时不弹出地返回 `false`。
  5. 否则调用 `pop(result)` 并返回 `true`。
- **用法：**
  ```dart
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    maybeDiscardAndPop(result);
  },
  ```
  （同文件，`_UnsavedChangesGuardState.build`，接到 `PopScope`。）
- **备注：** 实现应返回路由是否实际被弹出——直接调用它的调用方（如对话框自己的"取消"按钮）依赖布尔决定是否也运行自己的后续逻辑。

### `void pop<T extends Object?>([T? result])`（具体覆盖） <a id="pop"></a>
- **种类：** `_UnsavedChangesGuardState` 的方法（实现 `UnsavedChangesController`）
- **来源：** `lib/shared/widgets/unsaved_changes_guard.dart`（第 97 行）
- **用途：** 允许受守卫 `PopScope` 弹出，然后在下一帧执行实际 `Navigator.pop`。
- **输入：** `result`。
- **返回：** 无。
- **副作用：** 设 `_closing = true`；调用 `setState(() => _allowPop = true)`；安排调用 `Navigator.of(context).pop<T>(result)` 的帧后回调。
- **算法：**
  1. 已 `_closing` 或未 `mounted` 时立即返回（幂等守卫）。
  2. 设 `_closing = true` 和 `setState(() => _allowPop = true)`，使 `PopScope.canPop` 重建时成为 `true`。
  3. 注册 `WidgetsBinding.instance.addPostFrameCallback` 在 `canPop` 成为 `true` 的帧布局后调用 `Navigator.of(context).pop`，用另一个 `mounted` 检查守卫。
- **用法：** 被对话框自己的保存按钮经传入 `UnsavedChangesGuard` 的 `builder` 的 `guard` 参数调用，如成功保存后 `guard.pop(savedValue)`，并被 `maybeDiscardAndPop` 丢弃时内部调用。
- **备注：** 一帧延迟（现在设 `_allowPop`、实际 `Navigator.pop` 推迟到下一帧）存在，使 `PopScope.canPop` 在实际尝试弹出时已翻转为 `true`——`canPop` 变化的同一帧弹出否则可能被 `PopScope` 吞掉。

### `Future<bool> showDiscardChangesDialog(BuildContext context)` <a id="showdiscardchangesdialog"></a>
- **种类：** 顶层 async 函数
- **来源：** `lib/shared/widgets/unsaved_changes_guard.dart`（第 113 行）
- **用途：** 显示共享"丢弃更改？"确认对话框。
- **输入：** `context`。
- **返回：** `Future<bool>` — 用户选丢弃 `true`，否则 `false`（取消或关闭）。
- **副作用：** 经 `showDialog<bool>` 显示模态 `AlertDialog`。
- **算法：** 构建带本地化标题/消息（`commonDiscardChangesTitle`/`commonDiscardChangesMessage`）的 `AlertDialog`；取消弹出 `false`；填充、error 色丢弃按钮弹出 `true`；返回结果或 null 时 `false`。
- **用法：** `_UnsavedChangesGuardState.maybeDiscardAndPop` 内部调用；也任何守卫组件外需要相同确认的屏幕可直接使用。
- **备注：** 无。

### `String formSignature(Iterable<Object?> values)` <a id="formsignature"></a>
- **种类：** 顶层函数
- **来源：** `lib/shared/widgets/unsaved_changes_guard.dart`（第 145 行）
- **用途：** 从表单当前字段值构建单个可比较字符串，使调用方能通过比较初始签名与较后签名检测编辑。
- **输入：** `values` — 表单字段值的有序可迭代（典型为控制器文本、日期、枚举和嵌套列表）。
- **返回：** `String` — 每个值签名用（单元分隔符）控制字符连接。
- **副作用：** 无。
- **算法：** `values.map(_formValueSignature).join('')`。
- **用法：**
  ```dart
  String _signature() => formSignature([
    _titleController.text.trim(),
    _noteController.text.trim(),
    _subtaskController.text.trim(),
    _selectedType.name,
    _reminderTime,
    _selectedEmoji,
    _scheduledDate,
    _dueDate,
    _recurrenceSignature(_recurrence),
    _subtaskTitles,
  ]);
  ```
  （`lib/features/todo/widgets/add_task_dialog.dart`，`_signature`，供给 Todo/财务/亲密/体重对话框中 `UnsavedChangesGuard` 调用点使用的 `hasUnsavedChanges: () => _signature() != _initialSignature` 风格检查。）
- **备注：** 控制字符分隔符的选择（这里和 `_formValueSignature`）避免与可能含逗号、冒号或其他人类输入标点的普通用户输入文本产生歧义。

### `String _formValueSignature(Object? value)` <a id="_formvaluesignature"></a>
- **种类：** 顶层私有函数
- **来源：** `lib/shared/widgets/unsaved_changes_guard.dart`（第 153 行）
- **用途：** 把一个字段值序列化为 `formSignature` 的稳定字符串片段。
- **输入：** `value` — `null`、`DateTime`、`TimeOfDay`、`Iterable`、`Map` 或任何有可用 `toString()` 的东西。
- **返回：** `String`。
- **副作用：** 无。
- **算法：**
  1. `null` → `''`。
  2. `DateTime` → `toIso8601String()`。
  3. `TimeOfDay` → `'$hour:$minute'`。
  4. `Iterable` → 递归把每个元素经 `_formValueSignature` 映射并用（记录分隔符）连接。
  5. `Map` → 按键排序条目（`toString()` 比较），然后用（组分隔符）连接 `'key:value'` 对（值递归序列化）。
  6. 其他任何 → `value.toString()`。
- **用法：** 只从 `formSignature` 的 `.map(...)` 调用。
- **备注：** `Map` 条目连接前按键排序正为使签名比较与插入顺序无关——键值对相同但插入顺序不同的两个映射产生相同签名。
