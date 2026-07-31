# lib/features/finance/services/bank_preset_service.dart

经 `rootBundle.loadString` 加载并缓存 `assets/banks.json` 中的 250+ 捆绑银行/金融科技预设，并提供国家分组、名称搜索、按国家默认币种查找，以及按优先级排序的 logo URL 来源列表供尝试（`BankPreset.logoUrls`），因为没有单个免费 logo API 能可靠覆盖每家银行。`BankPresetService` 是惰性实例化的单例（`BankPresetService.instance`），因此 JSON 资源每个应用会话最多解析一次。银行预设选择器如何使用它见 [财务](../../../../features/finance.md#bankpresetservice)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`BankPreset()`](#bankpreset-new) | const 构造函数（`BankPreset`） | A | 创建银行预设条目。 |
| [`BankPreset.fromJson`](#bankpreset-fromjson) | 工厂构造函数（`BankPreset`） | A | 从捆绑 `banks.json` 条目解析预设。 |
| [`logoUrls`](#logourls) | getter（`BankPreset`） | A | 返回按优先级顺序尝试的 logo URL。 |
| `logoUrl` | getter（`BankPreset`） | B | 用于快速预览的主（Clearbit）logo URL。 |
| `countryCurrency`（静态 const 映射） | 字段 | B | 国家代码 -> 默认币种映射——无 Purpose 块（见对账）。 |
| `defaultCurrency` | getter（`BankPreset`） | B | 经 `countryCurrency` 得到此银行国家的默认币种。 |
| `BankPresetService._()` | 私有构造函数（`BankPresetService`） | B | 阻止直接实例化单例。 |
| [`getAll`](#getall) | 方法（`BankPresetService`） | A | 加载（并缓存）完整银行预设列表。 |
| [`groupedByCountry`](#groupedbycountry) | 方法（`BankPresetService`） | A | 按国家代码分组并排序预设。 |
| [`search`](#search) | 方法（`BankPresetService`） | A | 对预设列表做不区分大小写的名称搜索。 |

**对账：** `grep -c 'Purpose:' lib/features/finance/services/bank_preset_service.dart` 返回 9，与上面 9 个文档化行精确匹配——每个块都恰好位于其真实声明（构造函数、工厂构造函数、getter 或方法）正上方；未发现错附在调用点语句上方。表格在那 9 行之外还有一行：普通 `static const countryCurrency = <String, String>{...}` 字段，不带 `/// Purpose:` 块，与本代码库记录可调用成员而非普通数据字段的约定一致——`shared/services/webdav_service.md` 的未文档化 `static const`/`static final` 字段也见同样模式。对照此列表交叉核对文件中的每个 `class`、`factory`、`get` 和方法声明，没有发现未文档化的可调用声明。`getAll`、`groupedByCountry`、`search` 和两个构造函数分类为 Tier A（真实 IO/缓存或循环逻辑）；`logoUrl`、`defaultCurrency` 和 `BankPresetService._()` 分类为 Tier B，作为平凡单行访问器/转发构造函数；`logoUrls` 尽管是 getter 仍分类为 Tier A，因为它构建 [财务](../../../../features/finance.md#bankpresetservice) 明确点出的多来源优先级 URL 列表。

## 文档

### `const BankPreset({required String id, required String country, required String localTitle, required String engTitle, required String color, required String domain})` <a id="bankpreset-new"></a>
- **种类：** `BankPreset` 的 const 构造函数
- **来源：** `lib/features/finance/services/bank_preset_service.dart`（第 19 行）
- **用途：** 保存一个银行/金融科技预设条目的 id、国家、本地化/英文标题、品牌色和 Web 域名（用于派生 logo URL）。
- **输入：** 全部六个字段必填。
- **返回：** 新的 `BankPreset`。
- **副作用：** 无。
- **算法：** 平凡 `const` 字段赋值构造函数。
- **用法：** 解析 `assets/banks.json` 时专门经 [`BankPreset.fromJson`](#bankpreset-fromjson) 构造——本文件之外没有直接 `BankPreset(...)` 调用点。
- **备注：** 无。

### `factory BankPreset.fromJson(Map<String, dynamic> json)` <a id="bankpreset-fromjson"></a>
- **种类：** `BankPreset` 的工厂构造函数
- **来源：** `lib/features/finance/services/bank_preset_service.dart`（第 33 行）
- **用途：** 解析捆绑 `assets/banks.json` 预设列表的一个条目。
- **输入：** `json` — 资源顶层数组的一个解码映射。
- **返回：** 新的 `BankPreset`。
- **副作用：** 无。
- **算法：** 把 `id`/`country`/`engTitle` 作为必填字符串转换；`localTitle` 缺失时回退 `engTitle`；`color` 默认 `'#888888'`；`domain` 默认 `''`（空域名意味着没有 logo URL，按 [`logoUrls`](#logourls)）。
- **用法：**
  ```dart
  final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  _cache = list.map(BankPreset.fromJson).toList();
  ```
  （`lib/features/finance/services/bank_preset_service.dart:114-115`，[`getAll`](#getall) 内。）
- **备注：** 资源中没有 `localTitle` 的预设条目静默为两个字段复用 `engTitle`——这不是数据错误，只是 JSON 格式对"两种语言同名"的简写。

### `List<String> get logoUrls` <a id="logourls"></a>
- **种类：** `BankPreset` 的 getter
- **来源：** `lib/features/finance/services/bank_preset_service.dart`（第 48 行）
- **用途：** 返回这家银行跨多个免费 logo/favicon 服务的候选 logo URL，按预期质量从高到低排序，使调用方能逐个尝试直到一个成功。
- **输入：** 无。
- **返回：** `List<String>` — `domain` 为空时为空（没有可派生 logo 的域名）。否则按顺序：Clearbit、logo.dev、Brandfetch、icon.horse、Favicone、Google 的 `s2/favicons`、DuckDuckGo 的 favicon 代理，以及最后手段 Google 的 `t3.gstatic` favicon CDN。
- **副作用：** 无。
- **算法：** 以 `domain.isNotEmpty` 为键的条件列表字面量，把 `domain` 插值进每个服务的 URL 模板。
- **用法：**
  ```dart
  if (bank == null || bank.logoUrls.isEmpty) return;
  ...
  for (final url in bank.logoUrls) {
    path = await ImageService.downloadAndSave(url);
    if (path != null) break;
  }
  ```
  （`lib/features/finance/views/accounts_page.dart:2000-2007`，`_fetchBankIcon`，按顺序尝试每个 URL 直到下载成功。）
- **备注：** 尽管是 getter 仍分类为 Tier A，因为它是 [财务](../../../../features/finance.md#bankpresetservice) 显式点出的多来源 logo 回退链——没有单个来源单独足够可靠。

### `static Future<List<BankPreset>> getAll()` <a id="getall"></a>
- **种类：** `BankPresetService` 的方法
- **来源：** `lib/features/finance/services/bank_preset_service.dart`（第 111 行）
- **用途：** 加载并解析完整捆绑银行预设列表，缓存结果使资源每个应用会话只读取解析一次。
- **输入：** 无。
- **返回：** `Future<List<BankPreset>>`。
- **副作用：** 缓存未命中时经 `rootBundle.loadString` 读取 `assets/banks.json`；填充实例级 `_cache` 字段。
- **算法：**
  1. `_cache` 已填充时立即返回。
  2. 否则加载并 `jsonDecode` `assets/banks.json`，转换为映射列表，逐个经 [`BankPreset.fromJson`](#bankpreset-fromjson) 映射，存储进 `_cache` 并返回。
- **用法：** 从 [`groupedByCountry`](#groupedbycountry) 和 [`search`](#search) 作为共享数据源调用；没有直接外部调用点——每个使用者都走两者之一。
- **备注：** 缓存从不在单例生命周期内失效——`assets/banks.json` 是构建期资源，因此只要应用不带着变更的资源包热重载就安全。

### `Future<Map<String, List<BankPreset>>> groupedByCountry()` <a id="groupedbycountry"></a>
- **种类：** `BankPresetService` 的方法
- **来源：** `lib/features/finance/services/bank_preset_service.dart`（第 125 行）
- **用途：** 按国家代码分组每个预设，每个国家的列表按 `localTitle` 字母排序，供银行选择器的分组显示。
- **输入：** 无。
- **返回：** `Future<Map<String, List<BankPreset>>>`。
- **副作用：** 可能经 [`getAll`](#getall) 触发一次性 `assets/banks.json` 加载。
- **算法：**
  1. 经 `getAll()` 取完整列表。
  2. 把每个预设分桶进 `map[b.country]`（用 `??=` 惰性创建列表）。
  3. 按 `localTitle` 排序每个国家的列表。
- **用法：**
  ```dart
  final grouped = await BankPresetService.instance.groupedByCountry();
  if (mounted) setState(() { _grouped = grouped; _loading = false; });
  ```
  （`lib/features/finance/widgets/bank_preset_picker.dart:106-107`，`_load`，银行选择器的初始分组视图。）
- **备注：** 无。

### `Future<List<BankPreset>> search(String query)` <a id="search"></a>
- **种类：** `BankPresetService` 的方法
- **来源：** `lib/features/finance/services/bank_preset_service.dart`（第 143 行）
- **用途：** 对 `localTitle` 和 `engTitle` 的不区分大小写子串搜索，供银行选择器的搜索框。
- **输入：** `query` — 自由文本搜索字符串。
- **返回：** `Future<List<BankPreset>>` — `query` 为空时是完整未排序列表（经 [`getAll`](#getall)），否则只有匹配预设。
- **副作用：** 可能经 [`getAll`](#getall) 触发一次性 `assets/banks.json` 加载。
- **算法：**
  1. `query` 为空时返回不过滤的 `getAll()`。
  2. 否则小写化 `query` 并过滤 `localTitle` 或 `engTitle`（小写后）包含它的预设。
- **用法：**
  ```dart
  final results = await BankPresetService.instance.search(query);
  if (mounted) {
    setState(() { ... });
  }
  ```
  （`lib/features/finance/widgets/bank_preset_picker.dart:120-122`，银行选择器的实时搜索处理器。）
- **备注：** 匹配未排序（按它们出现在缓存列表中的顺序），不同于 [`groupedByCountry`](#groupedbycountry) 的按字母分组。
