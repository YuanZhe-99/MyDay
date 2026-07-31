# lib/features/settings/views/privacy_policy_page.dart

显示 MyDay 应用内隐私政策的单个静态页，翻译为英语、简体中文、繁体中文和日语，由活动应用语言区域而非页面自己的语言选择器选择。按 [设置](../../../../features/settings.md)，它应与仓库根 `PRIVACY_POLICY.md` 匹配。像 [`license_page.dart`](license_page.md) 一样，它没有服务或外部状态——唯一"逻辑"是挑选渲染哪个预制字符串。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `PrivacyPolicyPage({super.key})` | 构造函数（`PrivacyPolicyPage`） | B | 创建隐私政策页实例。 |
| `build` | 方法（`PrivacyPolicyPage`） | B | 构建可滚动、可选择的隐私政策文本视图。 |
| `_getText` | 方法（`PrivacyPolicyPage`） | B | 挑选匹配当前语言区域的隐私政策文本块。 |

**对账：** `grep -c 'Purpose:' lib/features/settings/views/privacy_policy_page.dart` 返回 3。三个块都文档化真实声明（构造函数、`build` 和 `_getText`）——无错附块、无未文档化声明。四个静态字符串字段（`_en`、`_zh`、`_zhTW`、`_ja`）无 `Purpose:` 块，与它们是数据而非函数一致。

## 文档

三个声明都是 Tier B。`_getText` 是普通语言区域到字符串分发器——像 [`webdav_config_page.dart`](../../../shared/views/webdav_config_page.md#progresstext) 的 `_progressText` 或 [`backup_page.dart`](../../../shared/views/backup_page.md#localizedmodulename) 的 `_localizedModuleName`，它只在固定预制值集合中选择且无外部效应，因此尽管有 `if`/`switch` 分支仍是 Tier B：它把 `zh`+`TW`（繁体中文）特判在普通 `zh` case 之前，然后对 `zh`/`ja` 按 `languageCode` 切换，否则默认英语。每个声明单行用途见上面表格；本文件无 Tier A 条目。

## 相关页面

- [设置](../../../../features/settings.md) — 链接到本页、以及此文本应跟随 `PRIVACY_POLICY.md` 的说明。
