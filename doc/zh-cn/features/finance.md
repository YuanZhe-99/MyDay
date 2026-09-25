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

**内置银行标志（v1.4.5）。** 完整版构建在 `assets/bank_logos/` 下为 267 个唯一预设中的 219 个附带经过审核的标志（键为 `<country>/<id>`；`assets/banks.json` 有 269 行，因为 `gb/revolut` 和 `gb/wise` 各出现两次）：165 个 SVG 和 54 个 PNG，约 2.7 MB。选择这些预设不再需要网络；其余 48 个照旧使用网络链。

- **查找顺序：内置 → 网络。** 在账户对话框中选择预设时，`_fetchBankIcon` 先把该预设的内置标志复制进 `images/`（`ImageService.copyAssetImage`）；没有内置标志或加载失败时，照旧遍历 `BankPreset.logoUrls` 网络链。银行预设选择器通过 `BankLogoImage` 在每一行按同样顺序显示（内置标志 → Clearbit 预览 → 首字母）。
- **商店版构建不含任何标志。** 当 `bundledBankLogosEnabled` 为 false（`lib/app/build_flavor.dart`）时，`BankPreset.bundledLogoAsset` 返回 null；CI 在构建商店版 AAB 之前剥离标志文件、pubspec 资源行和清单条目。商店版构建只用网络链。见 [架构](../architecture.md) 和 [CI/CD](../ci-cd.md)。
- **清单键。** 生成的标志清单 `lib/features/finance/services/bank_logo_manifest.g.dart` 把 `BankPreset.key`（`<country>/<id>`）映射到 `assets/bank_logos/<country>_<id>.<svg|png>`。键带国家限定，因为预设 id 会在不同国家重复（`icbc`、`hsbc`、`vtb`……）。
- **SVG 渲染。** 内置标志可能是 SVG，因此存储的账户或订阅图像现在可能是 `images/<uuid>.svg`。财务模块的每个显示位置都通过 `StoredImage` / `StoredImageAvatar`（`lib/shared/widgets/stored_image.dart`）渲染存储图像，它们按扩展名选择 SVG 或位图解码器；SVG 标志总是以 `contain` 放在白色圆底上，使文字标志在深色模式下保持完整、清晰。亲密模块仍使用 `FileImage`——它的图像只来自文件选择器。
- **商标。** 这些标志是各机构自己的商标，内置它们只是为了让用户认出自己的账户。商店版构建不含任何标志。`tool/bank_logo_choices.json` 记录每一个审核决定（`"c0.svg"`、`"s1.png"`、`"c0.svg@png"` 或 `"reject"`），因此任何单个标志都可以被移除（设为 `"reject"`）并重建整套标志。没有条目的预设与被拒绝的预设一样，不会得到内置标志。

添加或替换标志：

1. **获取候选**到临时目录（从不写入 `assets/`）：`dart run tool/fetch_bank_logos.dart --out <scratch dir> [--only <country_id,...>] [--infobox]`。第 1 阶段从 Wikidata 解析 Commons 文件名——官方网站与预设域名匹配的实体的小标志/图标（P8972/P2910）和标志（P154），否则按名称逐个搜索实体——并缓存到 `<out>/plan.json`。第 2 阶段通过 Commons API 以每批 50 个解析直接文件 URL，并缓慢下载每个文件（间隔 900 ms，遇到 HTTP 429 时遵守 `Retry-After`）；它避开受限流的 `Special:FilePath` 重定向。两个阶段都能从缓存续跑。`--infobox` 为 Wikidata 中没有标志的预设读取英文和当地语言 Wikipedia 信息框中的标志（许多标志是本地的非 Commons 文件）。`--site --only <country_id,...>` 从银行自己的主页追加候选 `s0`、`s1`……（标志 `<img>`、SVG 图标、apple-touch-icon、`og:image`）。每个键可选的直接 URL 写在 `tool/bank_logo_overrides.json` 中。
2. **审核**：`dart run tool/bank_logo_sheet.dart --dir <scratch dir> [--only <country_id,...>]` 生成每页 12 个预设的 HTML 联系表（`sheet_<country>_<n>.html`），每个候选以文件名标注，并以头像尺寸和大尺寸在浅色和深色背景上显示。
3. **记录决定**到 `tool/bank_logo_choices.json`：候选文件名；对 flutter_svg 无法绘制的 SVG，在文件名后加 `@png`；或 `"reject"`。
4. **安装**：`dart run tool/apply_bank_logo_choices.dart --dir <scratch dir>` 从零重建 `assets/bank_logos/` 并重新生成清单。SVG 的 `<style>` 规则被内联进 `style` 属性（flutter_svg 忽略样式表，否则大多数 Illustrator 导出会渲染成黑色）。`@png` 改为安装 Wikimedia 对该 SVG 的 500 px PNG 渲染（Wikimedia 只提供标准缩略图宽度；512 会返回 HTTP 400）——用于内联后 flutter_svg 仍无法绘制的文件，如 `foreignObject` 或某些裁剪/渐变组合。位图（PNG、JPEG、WebP、GIF）居中放在带边距的白色正方形上，并缩放为正好 256 px。`dart run tool/gen_bank_logo_manifest.dart` 只根据 `assets/bank_logos/` 中现有的文件重新生成清单。
5. **在 flutter_svg 中验证，而不是在浏览器中。** 浏览器能渲染不代表 flutter_svg 能绘制，因此每个已安装的 SVG 都经 flutter_svg 本身（`vg.loadPicture`）渲染，并与浏览器渲染并排比较（`dart run tool/bank_logo_sheet.dart --final` 提供浏览器一侧）。然后运行 `flutter test test/bank_logo_manifest_test.dart`，它检查清单与目录完全一致、每个 SVG 都能被 flutter_svg 解析，以及每个 PNG 都是正方形且至少 128 px。

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
