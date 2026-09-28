# 端侧 AI

自 1.5.0 起，MyDay!!!!! 可以使用设备自带的语言模型——通过 Android AICore 使用 Gemini Nano，或通过 Foundation
Models 框架使用 Apple Intelligence 的模型——在每个模块页面上写一张简短的**洞察卡片**：待办上是今天的计划、进展或
回顾；财务上是收入与支出趋势和订阅；体重上是趋势；亲密上是趋势和身体状况。本页记录其规则、代码的布局、每张卡片
获得的内容、结果如何缓存，以及仍需在设备上检查的内容。

模型层移植自 MyAnime!!!!!（1.6.x），而后者本身移植自 MyNihongo!!!!!；洞察卡片是 MyDay 自己的。

> **最后核实：** 2026-09-28，依据 MyAnime 已核实的移植版本和已发布的库。**尚未在设备上验证。** 带 AICore
> 的 Android 设备和带 Apple Intelligence 的 Apple 设备都还没有运行过这段代码；有设备时按
> [设备检查清单](#device-checklist) 操作。Android 桥接已在 MyNihongo 中于 Pixel 10 和 Galaxy Z Fold 8 上
> 运行过。

## 策略 <a id="policy"></a>

第 1–3、7 和 8 条在 `OnDeviceAiService` 中强制执行，并由 `test/on_device_ai_test.dart` 和
`test/ai_settings_tiles_ui_test.dart` 覆盖。第 4–6 和 9 条由洞察层强制执行，并由
`test/insight_service_test.dart`、`test/insight_facts_test.dart`、`test/ai_insights_cache_test.dart` 和
`test/ai_insight_card_ui_test.dart` 覆盖。

1. **默认关闭。** 在用户打开开关之前，`storage_config.json` 中没有 `onDeviceAiEnabled`。
2. **开关就是一道门。** 开关关闭时从不调用方法通道，连状态也不查询，每张卡片都不渲染任何内容。
3. **每次请求前都重新检查状态。** 系统可能在两次请求之间移除模型。
4. **生成的输出带标注**「在本设备上生成——可能有误」。
5. **页面优先。** 卡片只在页面已显示的数据下方添加文字；模型失败时页面保持不变。
6. **生成的内容不同步也不备份。** 结果存放在 `ai_insights.json` 中，该文件没有登记到
   `lib/app/data_modules.dart`。
7. **绝不替用户下载任何东西。** 在 Android 上，模型下载只从设置中的「下载」按钮开始，并由 AICore 执行；在
   Apple 平台上由系统管理模型。
8. **只在端侧。** 绝不使用 Apple 的 Private Cloud Compute，也绝不使用任何其他远程模型。
9. **只有计算出的事实会到达模型。** 卡片由应用计算的汇总数据构建；见
   [每张卡片获得的内容](#insight-cards)。自由文本备注绝不会到达模型。

两种 Android 风味都包含此功能：它自身不发起任何网络调用。在 Windows（以及其他任何没有端侧模型的平台）上，卡片
从不构建，设置分区只有一行「本平台不可用」。

## 布局 <a id="layout"></a>

| 路径 | 作用 |
|---|---|
| `lib/features/ai/services/genai_backend.dart` | Dart 接缝：`GenAiStatus`、`GenAiFailure`、`GenAiStatusReport`、`GenAiCoreInfo`、`GenAiBackend` 接口和 `MethodChannelGenAiBackend` |
| `lib/features/ai/services/on_device_ai_service.dart` | `OnDeviceAiService`：开关、每次使用前的状态检查、单请求优先级队列、45 秒超时、生命周期、忙碌退避和每日配额停止 |
| `lib/features/ai/services/output_validation.dart` | 去除 Markdown、文字系统检查、清理单句、解析选择应答 |
| `lib/features/ai/services/insight_language.dart` | `InsightLanguage`：根据界面语言区域确定请求语言，以及中文变体转换 |
| `lib/features/ai/services/insight_prompts.dart` | `InsightModule`、`InsightTimeBucket`、`InsightFacts`、带版本的指令与提示词，以及回复解析器 |
| `lib/features/ai/services/ai_insights_cache.dart` | `AiInsightsCache`：`ai_insights.json`，本设备的缓存 |
| `lib/features/ai/services/insight_service.dart` | `AiInsightStore`：指纹、缓存或生成、合并请求、失败处理 |
| `lib/features/ai/widgets/ai_insight_card.dart` | `AiInsightCard`：卡片及其全部状态 |
| `lib/features/ai/widgets/ai_settings_tiles.dart` | `AiSettingsTiles`：开关、状态行、尺寸偏好、说明、技术详情和*清除已生成的洞察* |
| `lib/features/todo/services/todo_insight_facts.dart` | 待办事实，按时段 |
| `lib/features/finance/services/finance_insight_facts.dart` | 财务事实 |
| `lib/features/weight/services/weight_insight_facts.dart` | 体重事实 |
| `lib/features/intimacy/services/intimacy_insight_facts.dart` | 亲密事实与身体状况 |
| `lib/shared/utils/chinese_convert.dart` | 简体 ↔ 繁体转换，复制自 MyAnime |
| `android/app/src/main/kotlin/com/yuanzhe/my_day/GenAiChannel.kt` | 通往 ML Kit GenAI 的 Android 桥接 |
| `packages/on_device_ai_apple/` | 一个本地 Flutter 插件，iOS 和 macOS 共用一份 Darwin 源码 |

设置中的*端侧 AI*分区位于*隐私*和*桌面*之间。开关以 `onDeviceAiEnabled` 和 `onDeviceAiPreferFast` 存放在
`storage_config.json` 中（见 [`data-formats.md`](data-formats.md)）；`AppSettingsNotifier` 在启动时把两者推入
`OnDeviceAiService`，`main()` 启动该服务的生命周期监听器。

三个平台上的通道都是 `com.yuanzhe.my_day/genai`。它的方法有 `status`（`force`、`preferFast`）、`info`
（`locale`）、`download`（仅 Android）、`generate`（`instructions`、`prompt`、`maxOutputTokens`、`temperature`、
`topK`）、`choose`（仅 Apple；MyDay 不使用，但保留以使插件与 MyAnime 一致）、`prewarm` 和 `cancel`。
`platformMayHaveOnDeviceModel` 在 Android、iOS 和 macOS 上为 true；在其他所有平台上，后端不触碰通道就回答
`unsupported`。iOS 或 macOS 上的 `MissingPluginException` 报告为 `unreachable`，detail 为「channel not
registered」，绝不报告为 `unsupported`，这样注册失败的插件才会被发现。

### 状态与失败 <a id="statuses-and-failures"></a>

| 状态 | 含义 |
|---|---|
| `unsupported` | 本平台没有端侧模型（Windows、Linux、26 之前的 iOS 或 macOS） |
| `unavailable` | 已询问系统，系统表示不行 |
| `unreachable` | 根本无法询问系统 |
| `notEnabled` | Apple Intelligence 在系统设置中已关闭 |
| `downloadable` | Android：模型可由 AICore 获取 |
| `downloading` | 模型正在获取或准备中（也包括 Apple 的 `modelNotReady`） |
| `available` | 就绪 |
| `unknown` | 本版本没有对应名称的状态 |

失败类型有 `unavailable`、`busy`、`failed`、`cancelled`、`tooLong`、`timeout`、`background`、`quota`、
`guardrail` 和 `unsupportedLanguage`。

### 队列 <a id="the-queue"></a>

一次只运行一个请求。因打开页面而生成的卡片是**后台**请求；卡片的刷新按钮是**交互**请求，排在前面。应用不处于
`AppLifecycleState.resumed` 时什么都不运行。遇到 `busy` 后，后台任务等待 5 秒，逐次翻倍，最长 5 分钟；遇到
`quota` 后，后台任务在当天剩余时间停止；遇到 `background` 后，队列等待下一次 resume。

## 洞察卡片 <a id="insight-cards"></a>

每张卡片是放在其页面上的一个 `AiInsightCard`。开关关闭时或在没有模型的平台上它不渲染任何内容，因此那时所有
现有布局都不变。模型尚未就绪时（需要下载、Apple Intelligence 已关闭……），它是一行带*设置*按钮的提示。否则它
显示带刷新按钮的标题、生成期间的一条细进度条、各行文字（生成新行期间旧行变暗），以及标注和时间。

| 页面 | 位置 | 槽位 |
|---|---|---|
| 待办 | 每日评分卡片之后；各小节并排时位于最后一列。只在选中今天时显示。 | 上午（12:00 之前）：`plan`、`first`、`tip`。下午（12:00–18:00）：`progress`、`remaining`、`tip`。晚上（18:00 起）：`summary`、`tomorrow`、`encouragement`。 |
| 财务 | 即将续费横条之后。在堆叠（手机）布局中折叠为一行预览；在分栏布局的左栏中完整显示。 | *收入与支出*下的 `flowSummary`、`flowAdvice`；*订阅*下的 `subSummary`、`subAdvice`。 |
| 体重 | 摘要卡片和图表之间。 | `trend`、`advice`。 |
| 亲密 | 趋势图之后，只在端侧 AI 开启时。 | *趋势*下的 `trend`、`advice`（有记录时）；*身体状况*下的 `body`（有身体事实时）。用户跟踪自己的周期时显示周期免责声明。 |

### 每张卡片获得的内容 <a id="what-each-card-is-given"></a>

事实是由纯函数构建器计算出的英文 `- key: value` 行，经过取整，使指纹不会随浮点噪声变化。模型被要求用界面语言、
以一句不超过 30 个词的话回答每个带编号的请求，只使用给出的事实，不给医疗、法律或投资建议，也不编造数字。

| 卡片 | 发送 | 绝不发送 |
|---|---|---|
| 待办 | 日期；今天的每日习惯和一次性任务的标题（截断到 40 个字符，每行至多 12 个）；各项是否完成、是否顺延、是否逾期及其提醒时间；计数；自评分数；晚上还有明天的任务 | 任务备注、子任务标题 |
| 财务 | 本月及之前三个月每月的收入和支出，以默认货币计；本月和上月支出最多的三个分类；所有账户的合计；订阅数量、费用和最贵的几项名称；未来 7 天内的续费 | 卡号、有效期、安全码、银行或账户名称、交易和订阅备注 |
| 体重 | 最新体重及日期、身高、BMI、7/30/90 天内的变化、近期范围、称重次数、体脂、向前继承的胸/腰/臀、腰臀比 | 记录备注 |
| 亲密 | 最近 30 天和之前 30 天的：次数（有伴侣 vs 独自）、平均评分、平均计时时长、高潮率、防护率；90 天次数；距最后一条记录的天数；用户的胸/腰/臀（来自体重）、下胸围和估算罩杯；用户跟踪自己的周期时：典型周期长度、上次开始日期、今天的估算阶段和生育窗口、距下次估算开始的天数 | 备注、地点、伴侣/玩具/姿势名称、抽插次数、色情标记、生殖器测量值、伴侣的周期 |

亲密的排除项既出于隐私，也是为了留在端侧模型的可接受使用规则之内；`guardrail` 拒绝会作为*跳过*缓存，在事实
变化之前不会重试。

### 语言 <a id="language"></a>

`InsightLanguage.forLocale` 根据界面语言区域选择请求语言：简体中文（转换为简体）、繁体中文（转换为繁体）、日语或
英语。Apple 的 `supportsLocale` 拒绝繁体中文时，改为请求简体再转换；拒绝其他任何界面语言时，卡片会说明模型无法
使用该语言写作。只有文字系统与界面语言匹配的回复行才会保留（中文和日语至少 60 % 为 CJK，其他语言为拉丁字母）；
作为*引用词*列出的用户输入词语（任务标题、分类和订阅名称）在检查前被移除，因此引用英文标题的中文句子会被保留。

## 缓存与指纹 <a id="cache-and-fingerprint"></a>

结果缓存在应用数据文件夹中的 `ai_insights.json` 里（见
[`data-formats.md`](data-formats.md#ai_insightsjson)）。卡片**只**在其指纹变化时重新生成。指纹是以下内容的
SHA-256：

- 模块，
- `insightPromptVersion`（每当提示词措辞或构建器的输出变化时就要升级它），
- 请求语言标签，
- 本地日期（因此仅凭时间，每张卡片每天至多刷新一次），
- 模型身份（`variant · baseModelName`，或 `apple`），
- 规范化的事实，其中包括待办的时段。

因此卡片在以下情况更新：其数据变化（勾选一项任务、添加一笔交易、一次称重）、日期变化、待办越过 12:00 或
18:00、模型更新之后，或界面语言变化——除此之外绝不更新。卡片会为下一个边界设定计时器，因此一直开着的页面也会
更新。

`AiInsightStore` 让每张卡片至多有一次生成在运行或等待：期间到达的请求替换等待中的那个，因此连续勾选几项任务至多
多花一次运行，而事实已不再是最新的结果会被丢弃。`failed`、`timeout` 或无法解析的回复不会缓存，只由刷新按钮或新
事实触发重试，因此不会循环；`busy`、`background`、`cancelled` 和 `unavailable` 在下次构建页面时重试。设置中的
*清除已生成的洞察*会删除该文件。

## Android：基于 AICore 的 ML Kit GenAI <a id="android-ml-kit-genai-over-aicore"></a>

- `com.google.mlkit:genai-prompt:1.0.0-beta4`，与 MyAnime 版本相同。**没有**使用 Structured Output API。
- 要求 API 26 或以上，因此自 1.5.0 起应用的 `minSdk` 为 26（放弃 Android 7.0 和 7.1）。这些 API 在已解锁
  bootloader 的设备上拒绝运行。输入必须保持在约 4,000 token 以下；每张卡片的提示词都远低于此。
- 只有应用是最前台应用时才允许推理；后台使用会以 `BACKGROUND_USE_BLOCKED`（→ `background`）失败。AICore
  实行按应用的配额：`BUSY`（→ `busy`）和 `PER_APP_BATTERY_USE_QUOTA_EXCEEDED`（→ `quota`）。
- `GenAiChannel.probePrompt` 尝试 `ModelReleaseStage`（STABLE、PREVIEW）与 `ModelPreference`（FULL、FAST）的
  全部四种组合，保留第一个能提供服务的组合。只有两种尺寸都有提供时，设置才提供「使用更快的模型」。
- 模型报告 `isSystemPromptAvailable` 时，instructions 作为 `SystemInstruction` 发送；否则拼接在 prompt 前面。
- `android/app/proguard-rules.pro` 带有 R8 为 ML Kit 所需的两条保留规则，release 构建类型通过
  `proguardFiles` 列出它。
- `AndroidManifest.xml` 为 `com.google.android.aicore` 加了 `<queries>` 条目，使 `info` 能读取 AICore 的版本。
- `MainActivity` 在 `configureFlutterEngine` 中挂接 `GenAiChannel`，并在 `onDestroy` 中解除。
- 工具链：AGP 9.1.1、Kotlin Gradle Plugin 2.2.20、`android.builtInKotlin=false`，与 MyAnime 相同。
- 日志标签：`MyDayGenAi`。记录异常，从不记录 prompt。

## Apple：Foundation Models 框架 <a id="apple-the-foundation-models-framework"></a>

- iOS、iPadOS 和 macOS 26.0 或以上。`SystemLanguageModel.default.availability` 为 `.available` 或
  `.unavailable(reason)`，原因是 `deviceNotEligible`、`appleIntelligenceNotEnabled` 或 `modelNotReady`；可用性
  还取决于地区。
- 每个请求新建一个 `LanguageModelSession(instructions:)`，使前面的对话轮次不会泄漏到后面的回答中。
- 列出的语言包括 en-US、ja-JP 和 zh-CN；繁体中文不在列表中，见 [语言](#language)。
- 上下文窗口为 4,096 token。后台调用会被限速。
- 错误：`rateLimited` → `quota`，`concurrentRequests` → `busy`，`guardrailViolation` 和 `refusal` →
  `guardrail`，`unsupportedLanguageOrLocale` → `unsupportedLanguage`，`exceededContextWindowSize` →
  `tooLong`，`assetsUnavailable` → `unavailable`，其他一律 → `failed`。
- CI 使用 `macos-latest` 镜像默认的 Xcode（26.x）构建。
- 不需要任何 entitlement、`Info.plist` 键或使用说明，并且刻意没有 Private Cloud Compute 的 entitlement。

### 弱链接 <a id="weak-linking"></a>

部署目标保持为 iOS 13.0 和 macOS 13.0。每处 FoundationModels 引用都位于 `#if canImport(FoundationModels)` 和
`@available(iOS 26.0, macOS 26.0, *)` 之后，podspec 声明了 `s.weak_frameworks = 'FoundationModels'`。强链接该
框架的应用无法在 iOS 18 或 macOS 15 及更早版本上启动，因此这一点**经过检查，而不是假设**：只要有任何链接
FoundationModels 的二进制没有使用 `LC_LOAD_WEAK_DYLIB`，`tool/check_weak_link.sh` 就让 CI 构建失败；没有任何
二进制链接它时（插件没有进入构建）也会失败。见 [`ci-cd.md`](ci-cd.md)。

## 商店政策 <a id="store-policy"></a>

Google Play 的 AI 生成内容政策把使用 AI 改进现有功能的效率类应用列为不在适用范围内；输出仍然带标注。Apple 对
Foundation Models 的可接受使用要求禁止生成成人内容；亲密卡片只发送中性的统计数据，并要求使用中性的措辞。

## 设备检查清单 <a id="device-checklist"></a>

有设备时执行以下步骤，并更新上文的**最后核实**。

1. 开关关闭时，确认没有任何东西触碰模型（logcat 标签 `MyDayGenAi` 保持安静），也没有出现任何卡片。
2. 打开开关；检查状态行、技术详情，以及 Android 上的 AICore 版本和已提供与被拒绝的变体。
3. Android：点「下载」，进度以 MB 显示；状态变为可用。
4. 打开每个模块页面；每张卡片生成一次，之后重新打开页面时显示缓存的文字，不出现进度条。
5. 勾选一项任务；待办卡片重新生成。在页面打开时越过 12:00 或 18:00；模式随之改变。
6. 检查全部四种界面语言；各行以正确的文字系统到达，模型用简体回答时繁体中文会被转换。
7. 亲密：确认模型给出回答而不是拒绝；如果拒绝，卡片只说明一次，不再重试。
8. 请求进行中把应用切到后台；恢复后正常继续。
9. 在 **release** 构建（R8）上重复第 2–8 步。
10. Apple：在系统设置中关闭 Apple Intelligence；卡片和状态行都如实说明。
11. Apple：在 iOS 18 或 macOS 15 设备上安装，或在模拟器中启动一台，确认应用能启动。

## 如何刷新本页 <a id="how-to-refresh-this-page"></a>

1. 对照 Google Maven 分组索引（`https://dl.google.com/android/maven2/com/google/mlkit/group-index.xml`）和
   ML Kit 发布说明检查 `genai-prompt`，并对照 MyAnime 的 `doc/en-us/on-device-ai.md`。
2. 针对当前 SDK 重读 Foundation Models 文档，并确认 runner 镜像的默认 Xcode。
3. 修改任何提示词措辞或事实构建器之后，升级 `insightPromptVersion`。
4. 在两种语言中更新**最后核实**和上面的事实。
