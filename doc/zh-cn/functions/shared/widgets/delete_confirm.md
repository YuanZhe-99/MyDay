# lib/shared/widgets/delete_confirm.dart

带"5 分钟不再询问"退出选项的单个可复用删除确认流程（`confirmDelete`），被每个功能的删除操作使用（Todo 任务、财务账户/类别、亲密伴侣/玩具、体重记录等）。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`confirmDelete`](#confirmdelete) | 顶层函数 | A | 经对话框确认删除，尊重临时"不再询问"抑制。 |

`grep -c 'Purpose:' lib/shared/services/delete_confirm.dart` 报告 1，与本文件单个真实声明匹配。模块级 `_suppressUntil` 变量是普通可变字段（非函数/方法/构造函数/getter/setter），不单独计数；它以定义上方散文（`/// Global "don't ask" state...`）而非 `Purpose:` 块文档化。

## 文档

### `Future<bool> confirmDelete(BuildContext context, String itemLabel)` <a id="confirmdelete"></a>
- **种类：** 顶层 async 函数
- **来源：** `lib/shared/widgets/delete_confirm.dart`（第 16 行）
- **用途：** 显示删除确认对话框（带可选"5 分钟不再询问"复选框）并返回调用方是否应继续删除。
- **输入：** `context`（供对话框和本地化）；`itemLabel` — 描述项、插值进确认消息的纯文本。
- **返回：** `Future<bool>` — 应继续删除 `true`，取消 `false`。
- **副作用：** 抑制未激活时显示带 `StatefulBuilder` 管理复选框的模态 `AlertDialog`（`showDialog<bool>`）。用户勾选复选框确认时把模块级 `_suppressUntil` 设为 `DateTime.now() + 5 minutes`。
- **算法：**
  1. `_suppressUntil` 已设且仍在将来时不做任何显示 UI 地立即返回 `true`。
  2. 否则显示带标题（`commonDelete` 或回退 `'Confirm Delete'`）、由 `commonDeleteConfirm(itemLabel)`（或回退 `'Delete $itemLabel?'`）构建的消息和经 `StatefulBuilder` 绑定本地 `dontAsk` 状态的复选框行的 `AlertDialog`。
  3. "取消"弹出 `false`；填充"删除"按钮（用主题 error 色样式）弹出 `true`。
  4. 对话框结果是 `true` 且勾选了 `dontAsk` 时把 `_suppressUntil` 设为距现在 5 分钟。
  5. 返回对话框结果，对话框被（如返回按钮/屏障点击）无显式选择地关闭时默认 `false`。
- **用法：**
  ```dart
  confirmDismiss: (direction) async {
    if (direction == DismissDirection.startToEnd) {
      widget.onEdit?.call();
      return false;
    }
    return confirmDelete(context, AppLocalizations.of(context)!.todoThisTask);
  },
  ```
  （`lib/features/todo/widgets/task_section.dart`，任务块滑动删除。）
- **备注：** `_suppressUntil` 是单个进程范围（非逐项）抑制窗口——勾选一次"不再询问"抑制应用中*每个*后续 `confirmDelete` 调用 5 分钟，不只是同项类型。除等窗口过去或重启应用外无法提前重新武装。
