# 设置

来源：`lib/features/settings/views/settings_page.dart`、`privacy_policy_page.dart`、`license_page.dart`。小节列表的主要来源：`AGENTS.md` 的"设置"小节。

`settings_page.dart` 提供：

- **常规**：语言、应用日历和周期分组的全局周起始日、主题。
- **隐私**：带隐藏确认的亲密模块开关（见 [亲密](intimacy.md#hidden-by-default)——隐藏绝不删除数据）。
- **桌面**：最小化到托盘、关闭到托盘、开机自启、本地 API 启用/状态/设置、自定义存储位置、打开数据文件夹（这些开关背后的本地 API 和托盘/启动机制见 [平台说明](../platform-notes.md)）。
- **数据**：WebDAV 同步、导入/导出、备份（见 [WebDAV 同步](../sync.md) 和 [备份与恢复](../backup-restore.md)）。
- **关于**：应用标题、来自 `package_info_plus` 的版本、GPL 许可证、开源许可证、隐私政策。
- **调试**：调试构建中的订阅处理器日期覆盖（用于无需等待真实时间流逝即可演练 [订阅计费](../algorithms/subscription-billing.md) 追赶逻辑）。

`privacy_policy_page.dart` 包含所有支持语言的应用内隐私政策，应与仓库根目录的 `PRIVACY_POLICY.md` 匹配。`license_page.dart` 显示 GPLv3 许可证信息。

## 相关页面

- [架构](../architecture.md) — 这些设置控制的本地化语言和主题体系。
- [平台说明](../platform-notes.md) — 仅桌面设置（托盘、启动、本地 API）。
- [WebDAV 同步](../sync.md) 和 [备份与恢复](../backup-restore.md) — 数据小节的底层行为。
