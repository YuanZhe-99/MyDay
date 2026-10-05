# 共享界面基础

MyApps-UI `v0.1.0` 作为子模块放在 `packages/myapps_ui`，相对地址为
`../MyApps-UI.git`。克隆后递归初始化子模块。
两个路径依赖位于子模块的 `packages/` 目录。

`lib/app/theme.dart` 保留公开包装接口和靛蓝品牌色，调用
`MyAppsTheme`。公共风格和导航枚举保持原有存储名称。
动态配色的平台策略仍由应用根组件负责。

`lib/shared/utils/adaptive_layout.dart` 重新导出 `myapps_adaptive` 的
分屏、导航和列表常量及四个纯函数：`canSplitLayout`、
`useNavigationRail`、`columnCapacity`、`listRowCount`。待办分组分配，
财务、体重和亲密关系布局尺寸，以及导航避让仍由应用负责。
本次有意保留原有仅按宽度预测内容空间的行为。

设置、资料、同步和备份格式不变。公共导航组件和实际导航空间测量
安排在下一阶段。

## 升级

先将共享库发布到两个远程，再提交应用子模块指针更新。
固定到带标签的提交并运行静态分析及完整测试。公共实现文档
放在库中；应用文档描述接入和差异。
