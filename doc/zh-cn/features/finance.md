# 财务

模型来源：`lib/features/finance/models/finance.dart`。服务：`lib/features/finance/services/{balance_util,bank_preset_service,exchange_rate_api,exchange_rate_storage,finance_storage,subscription_processor}.dart`。完整字段列表见 [数据格式](../data-formats.md#finance--finance_datajson)，月末钳制深入探讨见 [订阅计费](../algorithms/subscription-billing.md)。

## 模型

- **`AccountType`**：`fund`、`credit`、`recharge`、`financial`。
- **`Account`**：银行/应用、账户名、币种、可选卡元数据、emoji/图像、可选月费豁免金额——`feeWaiverMinimumBalance` 和 `feeWaiverMonthlyDeposit` 两者都出现时被当作**替代**标准（满足任一即免手续费）、旧强制余额哨兵字段、`modifiedAt`。
- **`Transaction`**：金额/币种、历史汇率快照 id、账户 id、转账目标字段、分类/订阅 id、备注、日期、`modifiedAt`。
- **`Category`**：名称、`IconRef`、emoji、交易类型、`modifiedAt`。支持转账分类（不只是支出/收入）。
- **`Subscription`**：试用、计费周期/间隔、金额/币种、账户/分类、取消模式、持久化 `nextBillingDate`、`modifiedAt`。
- **`IconRef`** 存储 Material 图标码点和字体族。因为图标数据从这两个字段动态重建，发布构建需要 `--no-tree-shake-icons`。

## 强制余额迁移为调整交易

新版账户余额**只从交易计算**——没有交易只是调整的存储"当前余额"字段。在 UI 中设置当前余额改为：

1. 为达到输入余额所需的差额创建一笔收入或支出**调整交易**。
2. 在账户上存储旧哨兵 `forcedBalance: 0` 和 `forcedBalanceDate: 1970-01-01T00:00:00.000Z`，纯粹为**旧版兼容**（使读取该账户的旧应用构建仍看到它理解的强制余额值，只是解析为"无覆盖"）。

`balance_util.dart` 仍知道如何为早于此次迁移的账户在强制余额锚点周围重建历史余额。

## 汇率

- **`ExchangeRateStorage`**：基于快照的历史——去重的 `RateSnapshot` 加 `currentSnapshotId`，从旧的平铺 currency→rate 映射格式向前迁移。
- **`ExchangeRateApi`**：从 `https://open.er-api.com/v6/latest/{base}` 获取，无需 API 密钥，只更新配置的币种对，并且**每天最多获取一次**。
- **`balance_util.dart` 转换逻辑**：币种符号（`'CNY' => '¥'`、`'USD' => '\$'`、`'EUR' => '€'`……），`convertCurrency(rates, amount, from, to, {onMissingRate})` 按顺序尝试：**直接**汇率、**反向**汇率，然后经**中间**币种的路径——`for (final via in ['CNY', 'USD', 'EUR'])`。完全不存在直接/反向/中间路径时，金额回退为 **1:1** 转换，可选的 `onMissingRate(from, to)` 回调触发，使静默失真能被浮出。财务主页摘要在该次渲染期间任何转换以这种方式回退时显示列出受影响币种对的警告。

## `BankPresetService`

从 `assets/banks.json` 加载 250+ 银行预设（`rootBundle.loadString('assets/banks.json')`）、国家币种默认值、搜索/分组和多个 logo URL 来源。

## 订阅处理

**`SubscriptionProcessor`**（完整算法见 [订阅计费](../algorithms/subscription-billing.md)）提供：

- **每小时续费追赶**，由每个订阅上持久化的 `nextBillingDate` 字段驱动，而不是每次都从 `startDate` 重新计算。
- **多周期追赶**：应用几个计费周期未打开时，全部在一个趟生成。
- **幂等的计费日生成**：既有随机 id（较旧、历史）或稳定 id（较新）交易都被识别，因此重新运行处理器绝不会给一天计两次费。
- **到期时取消处理**：`atExpiry` 取消的订阅计费到其 `cancelledAt` 截止，然后停止并把 `isActive` 翻转为 `false`。
- **经 `Subscription.nextBillingCursor` 的月末钳制**：每个计费日期推进（模型自己的辅助和 `SubscriptionProcessor`）都经这一个游标函数路由，它把月末锚点日钳制到目标月的实际长度，而不是让 `DateTime` 日溢出跳过或漂移月份——如 1 月 31 日的月订阅计费 2 月 28/29 日、3 月 31 日、4 月 30 日……绝不跳过月份。这是财务模块中突出的算法；见 [订阅计费](../algorithms/subscription-billing.md) 和 [订阅计费演练](../examples/subscription-billing-walkthrough.md) 中的具体演练日期。

## 视图和分析页

财务视图覆盖可选月主页摘要和分组月度交易、带可选月费豁免标准的账户、带直接添加交易支持的账户交易页、来自账户页的交易账户选择器排序/分组/"更多"设置、分类、分类详情、汇率、订阅、订阅详情和分析图表。订阅可以立即或到期时取消；待定的到期时取消可以在原地恢复，而已过期或完全取消的订阅通过把其设置复制进一个带今天日期和新 id 的**新**激活订阅来恢复。

**分析页**包括：可点击的支出/收入分类明细（含未分类流）、带增/删/改支持的分类交易下钻、支出/收入趋势、可编辑的自定义日期范围和重建采样点账户余额的总资产趋势。

## 相关页面

- [数据格式](../data-formats.md) — 上面每个模型的精确 JSON 形态。
- [订阅计费](../algorithms/subscription-billing.md) — 完整细节的月末钳制算法。
- [订阅计费演练](../examples/subscription-billing-walkthrough.md) — 具体的 1 月→4 月日期。
- [三方合并](../algorithms/three-way-merge.md) — 账户/分类/交易/订阅如何跨设备合并。
