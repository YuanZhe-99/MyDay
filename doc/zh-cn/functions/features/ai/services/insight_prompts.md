# lib/features/ai/services/insight_prompts.dart

洞察卡片的词汇与措辞：哪张卡片（`InsightModule`）、Todo 的时段、纯事实构建器产出的 `InsightFacts`、带版本的系统指令与提示、把模型的 `<number>: <sentence>` 回复转为已校验行的解析器，以及事实构建器使用的小型格式化函数（使指纹不随浮点噪声变化）。事实构建器为 [`todo_insight_facts.md`](../../todo/services/todo_insight_facts.md)、[`finance_insight_facts.md`](../../finance/services/finance_insight_facts.md)、[`weight_insight_facts.md`](../../weight/services/weight_insight_facts.md) 和 [`intimacy_insight_facts.md`](../../intimacy/services/intimacy_insight_facts.md)；消费方为 [`insight_service.md`](insight_service.md)；行校验来自 [`output_validation.md`](output_validation.md)。见 [端侧 AI — 每张卡片获得什么](../../../../on-device-ai.md#what-each-card-is-given) 和 [缓存与指纹](../../../../on-device-ai.md#cache-and-fingerprint)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `insightPromptVersion` | 顶层常量（`int`） | B | 提示版本 `1`，属于每个指纹；措辞或构建器输出改变时递增。 |
| `insightLineMaxLength` | 顶层常量（`int`） | B | `160`：保留行的最大长度（字符）；更长的行被丢弃。 |
| `insightMaxOutputTokens` | 顶层常量（`int`） | B | `320`：一张卡片的输出预算。 |
| `InsightModule`（枚举） | 枚举 | B | `todo` / `finance` / `weight` / `intimacy`；名称即 `ai_insights.json` 中的键。 |
| `InsightTimeBucket`（枚举） | 枚举 | B | `none` / `morning` / `afternoon` / `evening`；只有 Todo 使用 `none` 以外的值。 |
| [`todoBucketFor`](#todobucketfor) | 顶层函数 | A | 为本地时间选择 Todo 卡片的时段。 |
| [`InsightSlot`（构造函数）](#insightslot-new) | const 构造函数（`InsightSlot`） | A | 创建一个编号请求。 |
| [`InsightFacts`（构造函数）](#insightfacts-new) | const 构造函数（`InsightFacts`） | A | 创建卡片的事实与所请求的答案。 |
| [`canonical`](#canonical) | 方法（`InsightFacts`） | A | 为计算指纹序列化事实。 |
| [`insightInstructions`](#insightinstructions) | 顶层函数 | A | 构建一张卡片的系统指令。 |
| [`insightPrompt`](#insightprompt) | 顶层函数 | A | 构建提示：先事实，后编号请求。 |
| `_answerLine` | 私有顶层变量（`RegExp`） | B | 匹配 `<number><sep><sentence>`，分隔符为 `:` `：` `.` `)` `、`。 |
| [`parseInsightReply`](#parseinsightreply) | 顶层函数 | A | 读取并校验模型的编号行。 |
| [`clipTitle`](#cliptitle) | 顶层函数 | A | 为事实行缩短用户输入的标题。 |
| [`factNumber`](#factnumber) | 顶层函数 | A | 格式化数字并去掉末尾零。 |
| [`factDate`](#factdate) | 顶层函数 | A | 把日期格式化为 `yyyy-MM-dd`。 |
| [`factWeekday`](#factweekday) | 顶层函数 | A | 以英文命名星期几。 |

`grep -c 'Purpose:' lib/features/ai/services/insight_prompts.dart` 报告 11，与上面十一个 Tier A 行匹配。

**对账：** 表格有 17 行，对应 11 个 `Purpose:` 块。多出的六行是不带 `Purpose:` 块的真实顶层声明：三个常量 `insightPromptVersion`、`insightLineMaxLength` 和 `insightMaxOutputTokens` 与两个枚举 `InsightModule` 和 `InsightTimeBucket`（各自只带普通文档注释），以及私有正则表达式 `_answerLine`（完全没有文档注释）。六个均为 Tier B。`InsightSlot` 和 `InsightFacts` 的字段不列为行。

## 文档

### `InsightTimeBucket todoBucketFor(DateTime now)` <a id="todobucketfor"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/ai/services/insight_prompts.dart`（第 29 行）
- **用途：** 为本地时间选择 Todo 卡片的模式。
- **输入：** `now`——本地时间。
- **返回：** `now.hour < 12` 时为 `InsightTimeBucket.morning`，`< 18` 时为 `afternoon`，否则为 `evening`。
- **副作用：** 无。
- **算法：** 两次小时比较。
- **用法：** `final bucket = todoBucketFor(now);`（`lib/features/todo/services/todo_insight_facts.dart`，`buildTodoInsightFacts`）。
- **备注：** 从不返回 `none`。时段属于 `InsightFacts.canonical()`，因而属于 Todo 指纹：跨过 12:00 或 18:00 会在下次页面构建时重新生成卡片。

### `const InsightSlot(this.id, this.ask)` <a id="insightslot-new"></a>
- **种类：** `InsightSlot` 的 const 构造函数
- **来源：** `lib/features/ai/services/insight_prompts.dart`（第 48 行）
- **用途：** 创建向模型请求的一个编号答案。
- **输入：** `id`——稳定标识符（如 `plan`、`flowSummary`），属于规范形式，并按行存入缓存；`ask`——展示给模型的英文请求。
- **返回：** 新 `InsightSlot`。
- **副作用：** 无。
- **算法：** 普通字段初始化 const 构造函数。
- **用法：** `InsightSlot('plan', "Sum up today's plan in one sentence."),`（`lib/features/todo/services/todo_insight_facts.dart`，`buildTodoInsightFacts`）。
- **备注：** 只有 `id` 进入指纹，`ask` 文本不进入；修改 `ask` 措辞必须递增 `insightPromptVersion` 才能替换已缓存的卡片。

### `const InsightFacts({required this.module, required this.bucket, required this.lines, required this.slots, this.quotedTerms = const []})` <a id="insightfacts-new"></a>
- **种类：** `InsightFacts` 的 const 构造函数
- **来源：** `lib/features/ai/services/insight_prompts.dart`（第 78 行）
- **用途：** 创建一张卡片由应用计算的事实与所请求的答案。
- **输入：** `module`；`bucket`（Todo 的模式，否则为 `none`）；`lines`——英文 `- key: value` 事实行，已取整并限量；`slots`——按顺序的编号请求；`quotedTerms`——可能出现在答案中的用户输入词（任务标题、分类与订阅名称），默认为空。
- **返回：** 新 `InsightFacts`。
- **副作用：** 无。
- **算法：** 普通字段初始化 const 构造函数。
- **用法：** 每个构建器末尾的 `return InsightFacts(`，如 `lib/features/todo/services/todo_insight_facts.dart`（`buildTodoInsightFacts`）。
- **备注：** 只由纯 `*_insight_facts.dart` 构建器构建，它们从不把自由文本备注或识别性细节放入 `lines`。`quotedTerms` 不属于规范形式。

### `String canonical()` <a id="canonical"></a>
- **种类：** `InsightFacts` 的方法
- **来源：** `lib/features/ai/services/insight_prompts.dart`（第 91 行）
- **用途：** 为计算指纹序列化事实。
- **输入：** 无。
- **返回：** `String`——相同事实得到相同结果。
- **副作用：** 无。
- **算法：** 以 `\n` 连接：`module.name`、`bucket.name`、每条事实行，然后是以 `|` 连接的槽位 id。
- **用法：** `request.facts.canonical(),`（`lib/features/ai/services/insight_service.dart`，`insightFingerprint`）。
- **备注：** 改变任一行、时段或槽位列表都会改变指纹；`ask` 文本和 `quotedTerms` 不会。

### `String insightInstructions(InsightLanguage language)` <a id="insightinstructions"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/ai/services/insight_prompts.dart`（第 105 行）
- **用途：** 构建一张卡片的系统指令。
- **输入：** `language`——见 [`insight_language.md`](insight_language.md)。
- **返回：** `String`——一段英文。
- **副作用：** 无。
- **算法：** 固定模板：声明 "The person's locale is `<localeTag>`"，把模型设定为日常生活应用中的私人助手，要求只用给定事实、以 `<name>` 用一句 30 词以内的短句回答每个编号请求，格式为 `"<number>: <sentence>"` 且不含其他内容，要具体、平和、友善，并禁止医疗、法律或投资建议、诊断和捏造数字。
- **用法：** `instructions: insightInstructions(request.language),`（`lib/features/ai/services/insight_service.dart`，`AiInsightStore._run`）。
- **备注：** 所有模块共用一个模板。区域设置句采用 Apple 文档中的形式；回复语言也被显式点名。任何措辞修改都需要递增 `insightPromptVersion`。

### `String insightPrompt(InsightFacts facts)` <a id="insightprompt"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/ai/services/insight_prompts.dart`（第 119 行）
- **用途：** 构建一张卡片的用户提示。
- **输入：** `facts`。
- **返回：** `String`。
- **副作用：** 无。
- **算法：** 第一行为 `Facts:`，随后每条事实行、`Answer:`，再每个槽位一行 `"<i+1>. <ask>"`；每行以 `\n` 结尾。
- **用法：** `prompt: insightPrompt(request.facts),`（`lib/features/ai/services/insight_service.dart`，`AiInsightStore._run`）。
- **备注：** 请求编号从 1 开始，与 [`parseInsightReply`](#parseinsightreply) 期望收到的编号一致。

### `Map<int, String> parseInsightReply(String reply, int slotCount, String languageCode, {List<String> quotedTerms = const []})` <a id="parseinsightreply"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/ai/services/insight_prompts.dart`（第 140 行）
- **用途：** 把模型的 `<number>: <sentence>` 行读为已校验的句子。
- **输入：** `reply`——模型原始输出；`slotCount`；`languageCode`——`en`、`ja` 或 `zh`；`quotedTerms`——文字系统检查前移除的用户输入词。
- **返回：** `Map<int, String>`——从 1 开始的槽位编号到清理后句子的映射；未找到有效内容时为空。
- **副作用：** 无。
- **算法：**
  1. `stripMarkdown(reply)`，按 `\n` 拆分。
  2. 用 `_answerLine`（`^\s*(\d+)\s*[:：.)、]\s*(.+?)\s*$`）匹配每行；不匹配则跳过。
  3. 跳过 `1..slotCount` 以外的编号和已出现过的编号（首次出现者胜出）。
  4. `cleanSentence(text, maxLength: insightLineMaxLength)`；为 `null`（空或超过 160 字符）时跳过。
  5. 在句子副本中把每个非空引用词替换为空格，除非 `matchesScript(copy, languageCode)` 成立，否则跳过该行。
  6. 以编号存储清理后（未替换）的句子。
- **用法：**
  ```dart
  final parsed = parseInsightReply(
    reply,
    request.facts.slots.length,
    request.language.code,
    quotedTerms: request.facts.quotedTerms,
  );
  ```
  （`lib/features/ai/services/insight_service.dart`，`AiInsightStore._run`。）
- **备注：** 过长的行被丢弃，从不截断。只由引用标题和数字组成的句子在文字系统检查时没有剩余正文，会被丢弃。允许缺少槽位；调用方把空映射视为失败。`stripMarkdown`、`cleanSentence` 和 `matchesScript` 见 [`output_validation.md`](output_validation.md)。

### `String clipTitle(String title, int maxRunes)` <a id="cliptitle"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/ai/services/insight_prompts.dart`（第 171 行）
- **用途：** 为事实行缩短用户输入的标题。
- **输入：** `title`；`maxRunes`——省略号前结果的最大长度，以 Unicode 码点计。
- **返回：** `String`——单行且已去除首尾空白；超过 `maxRunes` 时为前 `maxRunes` 个码点加 `…`。
- **副作用：** 无。
- **算法：** 把每段连续空白折叠为一个空格并去除首尾空白；比较码点数；需要时按码点截断并追加 `…`。
- **用法：** `String title(Task t) => clipTitle(t.title, maxTitleRunes);`（`lib/features/todo/services/todo_insight_facts.dart`，`buildTodoInsightFacts`）；Finance 把分类和订阅名称截到 30。
- **备注：** 截断后的结果长 `maxRunes + 1` 个码点。按码点截断能保持代理对完整，但仍可能拆开由多个码点组成的表情序列。

### `String factNumber(double value, [int digits = 1])` <a id="factnumber"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/ai/services/insight_prompts.dart`（第 183 行）
- **用途：** 为事实行格式化数字。
- **输入：** `value`；`digits`——小数位数，默认 1。
- **返回：** 不带末尾零（也不带末尾 `.`）的 `String`。
- **副作用：** 无。
- **算法：** `value.toStringAsFixed(digits)`；若含 `.`，移除正则 `\.?0+$` 的匹配。
- **用法：** `'- Latest weight: ${factNumber(latest.weight)} kg on '`（`lib/features/weight/services/weight_insight_facts.dart`，`buildWeightInsightFacts`）。
- **备注：** 取整到固定精度使指纹不随浮点噪声变化。极小的负值可能被格式化为 `-0`。

### `String factDate(DateTime d)` <a id="factdate"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/ai/services/insight_prompts.dart`（第 194 行）
- **用途：** 为事实行或指纹把日期格式化为 `yyyy-MM-dd`。
- **输入：** `d`。
- **返回：** `String`——补零的年（4 位）、月（2 位）、日（2 位）。
- **副作用：** 无。
- **算法：** 用 `padLeft` 的字符串插值。
- **用法：** `'date:${factDate(request.now)}',`（`lib/features/ai/services/insight_service.dart`，`insightFingerprint`）；也用于每个事实构建器的 `- Today:` 行。
- **备注：** 按原样使用 `d` 的日历字段，因此本地 `DateTime` 得到本地日期。

### `String factWeekday(DateTime d)` <a id="factweekday"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/ai/services/insight_prompts.dart`（第 204 行）
- **用途：** 为事实行以英文命名星期几。
- **输入：** `d`。
- **返回：** `String`——`Monday` … `Sunday`。
- **副作用：** 无。
- **算法：** 以 `d.weekday - 1` 索引常量列表。
- **用法：** `'- Today: ${factDate(today)} (${factWeekday(today)})',`（`lib/features/todo/services/todo_insight_facts.dart`，`buildTodoInsightFacts`）。
- **备注：** 无。
