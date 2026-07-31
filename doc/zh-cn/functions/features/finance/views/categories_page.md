# lib/features/finance/views/categories_page.dart

分类管理页：三个标签（支出/收入/转账），每个列出该 [`TransactionType`](../../../../features/finance.md#model) 的 [`Category`](../../../../features/finance.md#model) 记录，带增/改/删和由本文件自己的硬编码起始分类表（`_defaultExpenseCategories`、`_defaultIncomeCategories`、`_defaultTransferCategories`）支撑的"一键导入默认值"空状态。点击分类压入 [`CategoryDetailPage`](category_detail_page.md)。本页编辑的 `Category`/`IconRef` 模型字段见 [财务](../../../../features/finance.md#model)，发布构建为何需要 `--no-tree-shake-icons`（图标从存储码点 + 字体族重建）见 [`finance.md` 的模型文档](../models/finance.md#category-new)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `CategoriesPage({...})` | 构造函数（`CategoriesPage`） | B | 创建分类页实例。 |
| `createState` | 方法（`CategoriesPage`） | B | 为此组件创建可变状态对象。 |
| `initState` | 方法（`_CategoriesPageState`） | B | 把分类/交易复制进本地状态并创建 3 标签 `TabController`。 |
| `dispose` | 方法（`_CategoriesPageState`） | B | 释放 `TabController`。 |
| `_notify` | 方法（`_CategoriesPageState`） | B | 把当前分类列表转发给 `widget.onChanged`。 |
| `_ofType` | 方法（`_CategoriesPageState`） | B | 把分类过滤到一个交易类型。 |
| `_addCategory` | 方法（`_CategoriesPageState`） | B | 经对话框添加分类。 |
| `_editCategory` | 方法（`_CategoriesPageState`） | B | 经对话框编辑分类。 |
| `_deleteCategory` | 方法（`_CategoriesPageState`） | B | 从本地状态移除分类并通知。 |
| `_openCategoryDetail` | 方法（`_CategoriesPageState`） | B | 为点击的分类压入 `CategoryDetailPage`。 |
| [`_importDefaults`](#importdefaults) | 方法（`_CategoriesPageState`） | A | 为一个交易类型批量创建硬编码起始分类。 |
| [`_resolveKey`](#resolvekey) | 方法（`_CategoriesPageState`） | A | 把默认分类键字符串映射为其本地化名称。 |
| `build` | 方法（`_CategoriesPageState`） | B | 构建标签栏、标签视图和添加按钮。 |
| `_buildCategoryList` | 方法（`_CategoriesPageState`，组件辅助） | B | 构建一个标签的分类列表（或其导入默认值空状态）。 |
| `_CategoryDialog({...})` | 构造函数（`_CategoryDialog`） | B | 创建分类对话框实例。 |
| `createState` | 方法（`_CategoryDialog`） | B | 为此组件创建可变状态对象。 |
| `initState` | 方法（`_CategoryDialogState`） | B | 从 `widget.category`（或默认值）预填名称/图标/emoji，捕获初始签名。 |
| `dispose` | 方法（`_CategoryDialogState`） | B | 释放名称文本控制器。 |
| `build` | 方法（`_CategoryDialogState`） | B | 构建名称字段、emoji 网格、图标网格和操作。 |
| [`_hasUnsavedChanges`](#hasunsavedchanges) | 方法（`_CategoryDialogState`） | A | 报告表单是否与其初始状态不同。 |
| [`_signature`](#signature) | 方法（`_CategoryDialogState`） | A | 构建对话框字段的可比较字符串快照。 |
| [`_submit`](#submit) | 方法（`_CategoryDialogState`） | A | 校验名称并带 `Category` 弹出。 |

**对账：** `grep -c 'Purpose:' lib/features/finance/views/categories_page.dart` 返回 22，与上面 22 行精确匹配——每个块都恰好位于其真实声明（构造函数、`createState`、`initState`、`dispose` 或方法）正上方；未发现错附在调用点语句上方，也未发现未文档化的真实声明。类声明本身（`CategoriesPage`、`_CategoriesPageState`、`_CategoryDialog`、`_CategoryDialogState`）和顶层数据字面量（`_defaultExpenseCategories`、`_defaultIncomeCategories`、`_defaultTransferCategories`、`_categoryIcons`、`_commonEmojis`）不带 `/// Purpose:` 块，与本代码库记录可调用成员而非类或普通数据表的约定一致。

## 文档

### `void _importDefaults(TransactionType type)` <a id="importdefaults"></a>
- **种类：** `_CategoriesPageState` 的方法
- **来源：** `lib/features/finance/views/categories_page.dart`（第 214-231 行）
- **用途：** 从一个交易类型的本文件硬编码默认分类表批量创建一组本地化起始分类。
- **输入：** `type` — 要导入哪个默认集（支出/收入/转账）。
- **返回：** 无。
- **副作用：** 向 `_categories` 追加新 `Category` 对象；调用 `_notify()`。
- **算法：**
  1. 为 `type` 选匹配的硬编码默认列表——`_defaultExpenseCategories`、`_defaultIncomeCategories` 或 `_defaultTransferCategories`。
  2. 把每个默认条目（`{key, emoji, icon}` 映射）映射为真实 [`Category`](../models/finance.md#category-new)：名称经 [`_resolveKey`](#resolvekey) 本地化，图标的 `codePoint` 取自条目的 `IconData` 常量（`fontFamily` 在 [`IconRef`](../models/finance.md#iconref-new) 内默认 `'MaterialIcons'`）。
  3. 在 `setState` 内把它们全部追加进 `_categories` 并调用 `_notify()`。
- **用法：**
  ```dart
  FilledButton.tonal(
    onPressed: () => _importDefaults(type),
    child: Text(l10n.financeImportDefaults),
  ),
  ```
  （显示在尚无该类型分类的标签的空状态视图上。）
- **备注：** 没有去重检查——调用两次（如已导入后再调）会追加第二批同名同图标的分类，而不是空操作。

### `String _resolveKey(AppLocalizations l10n, String key)` <a id="resolvekey"></a>
- **种类：** `_CategoriesPageState` 的方法
- **来源：** `lib/features/finance/views/categories_page.dart`（第 238-258 行）
- **用途：** 把本文件内部默认分类键字符串之一（如 `'financeCatFood'`）映射为其本地化显示名称。
- **输入：** `l10n`；`key` — `_defaultExpenseCategories`/`_defaultIncomeCategories`/`_defaultTransferCategories` 中使用的字面 `'financeCatXxx'` 字符串之一。
- **返回：** `String` — 本地化名称，不匹配任何已知 case 时原样返回 `key`。
- **副作用：** 无。
- **算法：** 直接 `switch` 表达式，把 17 个已知默认分类键各映射到对应 `AppLocalizations` getter（`financeCatFood` -> `l10n.financeCatFood` 等）；不可识别键落入 `_ => key` 默认分支并逐字返回。
- **用法：**
  ```dart
  name: _resolveKey(l10n, d['key'] as String),
  ```
  （[`_importDefaults`](#importdefaults) 内。）
- **备注：** 逐字回退意味着 `_defaultXxxCategories` 表中拼错或改名的键会静默显示为原始内部键字符串而不是抛出——这只能在那些表被手工编辑时发生，因为当前每个键在这里都有匹配 case。

### `bool _hasUnsavedChanges()` <a id="hasunsavedchanges"></a>
- **种类：** `_CategoryDialogState` 的方法
- **来源：** `lib/features/finance/views/categories_page.dart`（第 700 行）
- **用途：** 告诉 `UnsavedChangesGuard`（[`../../../shared/widgets/unsaved_changes_guard.md`](../../../shared/widgets/unsaved_changes_guard.md)）表单是否已偏离其初始状态。
- **输入：** 无（只读实例状态）。
- **返回：** `bool` — 当前签名与 `_initialSignature` 不同时为 `true`。
- **副作用：** 无。
- **算法：** 把 [`_signature()`](#signature) 与 `initState` 末尾捕获一次的 `_initialSignature` 比较。
- **用法：**
  ```dart
  return UnsavedChangesGuard(
    hasUnsavedChanges: _hasUnsavedChanges,
    builder: (context, guard) => Dialog(...),
  );
  ```
- **备注：** 作为撕离函数传入，因此每次弹出尝试都重新评估而不是缓存。

### `String _signature()` <a id="signature"></a>
- **种类：** `_CategoryDialogState` 的方法
- **来源：** `lib/features/finance/views/categories_page.dart`（第 707-712 行）
- **用途：** 产生一个当且仅当分类的名称、图标或 emoji 变化时变化的单字符串，用作脏检查基线/比较。
- **输入：** 无（只读实例状态）。
- **返回：** `String` — `formSignature`（`../../../shared/widgets/unsaved_changes_guard.md`）的连接签名。
- **副作用：** 无。
- **算法：** 委托给 `formSignature([_nameController.text.trim(), _selectedIcon.codePoint, _selectedIcon.fontFamily, _selectedEmoji])`。
- **用法：**
  ```dart
  _initialSignature = _signature();
  // ...
  bool _hasUnsavedChanges() => _signature() != _initialSignature;
  ```
- **备注：** 无。

### `void _submit(UnsavedChangesController guard)` <a id="submit"></a>
- **种类：** `_CategoryDialogState` 的方法
- **来源：** `lib/features/finance/views/categories_page.dart`（第 719-734 行）
- **用途：** 校验名称字段，非空时构造 [`Category`](../models/finance.md#category-new)（编辑时保留原始 id）并带它弹出对话框。
- **输入：** `guard` — `UnsavedChangesGuard.builder` 提供的 `UnsavedChangesController`。
- **返回：** 无。
- **副作用：** 只在名称非空时带结果弹出路由（经 `guard.pop`）。
- **算法：**
  1. 修剪名称字段；为空则静默返回。
  2. 构建 `Category`，传 `id: widget.category?.id`，使编辑既有分类保持其 id（添加时 `null` id 让 `Category` 的构造函数生成新的）；`icon` 是从 `_selectedIcon` 的码点和字体族（图标自己的 `fontFamily` 为 null 时默认 `'MaterialIcons'`）构建的新 `IconRef`；`emoji` 和 `type` 从 `_selectedEmoji`/`widget.type` 复制。
  3. 经 `guard.pop(category)` 带结果弹出。
- **用法：**
  ```dart
  FilledButton(
    onPressed: () => _submit(guard),
    child: Text(isEditing ? l10n.commonSave : l10n.commonAdd),
  ),
  ```
- **备注：** 校验只检查名称非空——对既有分类名没有唯一性检查，因此两个同名分类可以共存。

## 相关页面

- [财务](../../../../features/finance.md) — `Category`/`IconRef` 模型字段，以及这些动态重建图标施加的 `--no-tree-shake-icons` 发布构建要求。
- [`finance.md` 模型文档](../models/finance.md) — `Category`、`IconRef` 及其 `toJson`/`fromJson`/`toIconData` 方法。
- [`category_detail_page.dart`](category_detail_page.md) — `_openCategoryDetail` 压入的下钻页。
- [`unsaved_changes_guard.dart`](../../../shared/widgets/unsaved_changes_guard.md) — `_CategoryDialog` 使用的共享脏检查/丢弃确认模式。
