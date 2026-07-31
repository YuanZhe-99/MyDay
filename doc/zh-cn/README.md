# MyDay!!!!! 文档

MyDay!!!!! 是一款隐私优先的 Flutter 日常生活伴侣应用，覆盖待办管理、个人财务（含订阅和多币种汇率）、可选亲密模块（含周期跟踪和身体指标）和体重跟踪。它通过用户控制的 WebDAV 跨设备同步数据、保留本地备份、支持 ZIP 导入/导出，并提供桌面托盘行为、开机自启和本地 HTTP API。

- **Dart 包：** `my_day`
- **许可证：** GPL-3.0
- **主要平台：** Windows（x64/ARM64）、Android（APK/AAB）、iOS（侧载 IPA）、macOS（DMG）。Linux 项目为桌面运行时功能存在，但不是主要发布工件。
- **框架：** Flutter，Dart SDK `^3.11.3`

本树（`doc/en-us/`）是英文"概念"文档：应用如何组装、数据格式和算法长什么样、功能如何行为。它与 [`functions/`](functions/) 下的逐源文件函数索引（逐声明参考）以及任何未来的 `doc/zh-cn/` 翻译分开。

**这些文档是代码的权威描述。** 仓库的 `AGENTS.md` 刻意只保留给代理的指令——工作流、编写规则、行为契约和发布流程——并在这里指向其余一切。代码变更时，这些页面先行更新；当文档与代码不一致时，以代码核实后修正页面。

共享的 WebDAV 同步、备份和 ZIP 引擎不在此仓库。它们位于嵌入在 `packages/myapps_data` 的 `myapps_data` 包中，文档在 `packages/myapps_data/doc/en-us/`。

## 目录

### 核心概念

- [架构](architecture.md) — 应用外壳/启动、状态管理、导航、主题、本地化、仓库布局，以及核心存储/并发规则。
- [数据格式](data-formats.md) — 每个持久化模型的字段、`storage_config.json` 和完整持久化数据清单。
- [WebDAV 同步](sync.md) — 十步逐记录三方同步流程、重试/心跳/锁行为、同步数据参考表和自动同步触发。
- [备份与恢复](backup-restore.md) — 备份格式 v2、blob 垃圾回收、恢复校验与安全，以及仅 ZIP 的导入/导出。
- [平台说明](platform-notes.md) — Android/iOS/macOS/Windows 注意事项、本地 HTTP API、托盘行为和启动。
- [CI/CD](ci-cd.md) — CI 任务和工作流注意事项、构建/校验命令集和全新克隆（子模块）步骤。
- [版本历史](version-history.md) — 逐版本摘要。在改动一个看起来奇怪的行为前值得先查；多条记录是刻意的安全修复。

### 功能

- [待办](features/todo.md)
- [财务](features/finance.md)
- [亲密](features/intimacy.md)
- [体重](features/weight.md)
- [设置](features/settings.md)

### 算法（深入探讨）

- [三方合并](algorithms/three-way-merge.md) — 泛型 `mergeRecords` 引擎和每个数据文件的合并策略。
- [订阅计费](algorithms/subscription-billing.md) — 月末钳制和幂等的计费日生成。
- [身体指标](algorithms/body-metrics.md) — 跨六种地区标准的罩杯估算、PSI 公式和基于中位数的周期预测。

### 实例演练

- [同步演练](examples/sync-walkthrough.md) — 两台设备、一次跨模块冲突，以及混合解决映射安全规则。
- [订阅计费演练](examples/subscription-billing-walkthrough.md) — 一月份订阅每月计费日推进 2 月/3 月/4 月，带具体日期。

## 来源

本树中的一切均源自仓库自己的 `AGENTS.md`（受维护的架构/行为指南），并对照 `lib/` 下当前 Dart 源码交叉核对。本文档与源码不一致时，源码胜出——每页都列出它被核对的具体文件。
