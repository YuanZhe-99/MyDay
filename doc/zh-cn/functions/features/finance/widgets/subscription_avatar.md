# lib/features/finance/widgets/subscription_avatar.dart

订阅的前导头像，由订阅页的图块和财务主页的订阅概览共享，使一个订阅无论列在哪里看起来都一样。在 v1.4.3 之前这是 `subscriptions_page.dart` 内的 `_SubscriptionTile._buildLeading`；主页获得第二份订阅列表时原样移到这里。见 [财务](../../../../features/finance.md#views-and-analysis-page)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `SubscriptionAvatar({...})` | 构造函数（`SubscriptionAvatar`） | B | 创建订阅头像。 |
| [`build`](#build) | 方法（`SubscriptionAvatar`） | A | 经图像 / emoji / 账户图像 / 分类 emoji 回退链解析头像。 |
| `emojiAvatar` | 本地函数（嵌套于 `build`） | B | 构建圆形 emoji 头像。 |
| `defaultIcon` | 本地函数（嵌套于 `build`） | B | 构建默认重复图标头像。 |

**对账：** `grep -c 'Purpose:' lib/features/finance/widgets/subscription_avatar.dart` 报告 4，与上面 4 行精确匹配（1 个 Tier A，3 个 Tier B）。

## 文档

### `Widget build(BuildContext context)` <a id="build"></a>
- **种类：** `SubscriptionAvatar` 的方法
- **来源：** `lib/features/finance/widgets/subscription_avatar.dart`（第 39 行）
- **用途：** 经四层回退链解析头像：订阅自己的图像，然后是它自己的 emoji，然后是关联账户的图像，然后是关联分类的 emoji，最后是通用的重复图标。
- **输入：** `context`；组件的 `subscription`、`account`、`category` 字段。
- **返回：** `Widget`。
- **副作用：** `FutureBuilder` 分支在返回组件自己的构建中经 `ImageService.resolve` 解析图像文件。
- **算法：**
  1. 两个嵌套本地辅助：`emojiAvatar(String emoji)`（以 emoji 为文本的着色 `CircleAvatar`）和 `defaultIcon()`（带 `Icons.repeat` 的着色 `CircleAvatar`）；着色为 10% 透明度的 `theme.colorScheme.error`。
  2. `subscription.imagePath != null` → `FutureBuilder<File>`；解析出的文件存在时作为 [`StoredImageAvatar`](../../../shared/widgets/stored_image.md#storedimageavatar-build) 显示（位图或 SVG）；否则落到订阅的 emoji 或 `defaultIcon()`。
  3. 否则 `subscription.emoji != null` → `emojiAvatar`。
  4. 否则 `account?.imagePath != null` → 同样的 `FutureBuilder` 模式，回退到分类的 emoji 或 `defaultIcon()`。
  5. 否则 `category?.emoji != null` → `emojiAvatar`；再否则 `defaultIcon()`。
- **用法：** `_SubscriptionTile.build` 和 `_SubscriptionOverviewTile.build` 中的 `leading: SubscriptionAvatar(subscription: sub, account: account, category: cat)`。
- **备注：** 顺序严格优先订阅自己的标识而非账户或分类的；磁盘上已不存在的图像会落到下一层而不是渲染成空白。

## 相关页面

- [`subscriptions_page.md`](../views/subscriptions_page.md) — `_SubscriptionTile`。
- [`finance_page.md`](../views/finance_page.md) — `_SubscriptionOverviewTile`。
- [`image_service.md`](../../../shared/services/image_service.md) — `resolve`。
- [`stored_image.md`](../../../shared/widgets/stored_image.md) — `StoredImageAvatar`。
