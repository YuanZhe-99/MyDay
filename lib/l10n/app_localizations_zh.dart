// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'MyDay!!!!!';

  @override
  String get navTodo => '待办';

  @override
  String get navFinance => '财务';

  @override
  String get navWeight => '体重';

  @override
  String get navIntimacy => '亲密';

  @override
  String get navSettings => '设置';

  @override
  String get todoSectionDaily => '每日';

  @override
  String get todoSectionRoutine => '日常';

  @override
  String get todoSectionWork => '工作';

  @override
  String get todoAddTask => '添加任务';

  @override
  String get todoEditTask => '编辑任务';

  @override
  String get todoTitle => '标题';

  @override
  String get todoSubtasks => '子任务';

  @override
  String get todoAddSubtask => '添加子任务';

  @override
  String get todoReminderTime => '提醒时间';

  @override
  String get todoNoTasks => '暂无任务';

  @override
  String get todoType => '类型';

  @override
  String get todoEmoji => '图标';

  @override
  String get todoDailyTask => '每日';

  @override
  String get todoRoutineTask => '日常一次';

  @override
  String get todoWorkTask => '工作一次';

  @override
  String todoCreatedDate(String date) {
    return '建立日期：$date';
  }

  @override
  String todoStartDate(String date) {
    return '开始日期：$date';
  }

  @override
  String todoDeletedDate(String date) {
    return '删除日期：$date';
  }

  @override
  String get todoPermanentDelete => '彻底删除';

  @override
  String get todoPermanentDeleteConfirm => '这将永久删除此任务及其所有历史记录。是否继续？';

  @override
  String get todoMorningReminder => '晨间计划提醒';

  @override
  String get todoCompletionReminder => '完成检查提醒';

  @override
  String get todoSetReminder => '设置提醒';

  @override
  String get todoClearReminder => '清除';

  @override
  String todoReminderSet(String time) {
    return '提醒已设置：$time';
  }

  @override
  String get todoCompleted => '已完成';

  @override
  String get todoDueDate => '截止日期';

  @override
  String get todoSetDueDate => '设置截止日期（可选）';

  @override
  String get todoCustomEmoji => '自定义图标';

  @override
  String get todoCustomEmojiHint => '输入一个 emoji';

  @override
  String get todoEditSubtask => '编辑子任务';

  @override
  String get financeTitle => '财务';

  @override
  String get financeMonthlyExpense => '月度支出';

  @override
  String get financeTotalAssets => '总资产';

  @override
  String get financeAccounts => '账户';

  @override
  String get financeCategories => '分类';

  @override
  String get financeTrends => '趋势';

  @override
  String get financeAnalysis => '分析';

  @override
  String get financeExchangeRates => '汇率';

  @override
  String get financeRefreshRates => '刷新汇率';

  @override
  String get financeAddTransaction => '添加交易';

  @override
  String get financeEditTransaction => '编辑交易';

  @override
  String get financeExpense => '支出';

  @override
  String get financeIncome => '收入';

  @override
  String get financeTransfer => '转账';

  @override
  String get financeAmount => '金额';

  @override
  String get financeNote => '备注';

  @override
  String get financeCategory => '分类';

  @override
  String get financeAccount => '账户';

  @override
  String get financeFromAccount => '转出账户';

  @override
  String get financeToAccount => '转入账户';

  @override
  String get financeCurrency => '币种';

  @override
  String get financeDate => '日期';

  @override
  String get financeNoTransactions => '暂无交易';

  @override
  String get financeForceBalance => '强制余额';

  @override
  String get financeCurrentBalance => '当前余额';

  @override
  String get financeAddAccount => '添加账户';

  @override
  String get financeEditAccount => '编辑账户';

  @override
  String get financeAddCategory => '添加分类';

  @override
  String get financeEditCategory => '编辑分类';

  @override
  String get financeName => '名称';

  @override
  String get financeBankApp => '银行 / 应用';

  @override
  String get financeCardNumber => '卡号（可选）';

  @override
  String get financeExpiry => '有效期';

  @override
  String get financeSecurityCode => '安全码';

  @override
  String get financeIcon => '图标';

  @override
  String get financeEmoji => '表情';

  @override
  String get financeCategoryHintExpense => '如 餐饮、交通';

  @override
  String get financeCategoryHintIncome => '如 薪资、投资';

  @override
  String get financeThisTransaction => '此流水';

  @override
  String get financeNoAccounts => '暂无账户';

  @override
  String get financeNoCategories => '暂无分类';

  @override
  String get financeByYear => '按年';

  @override
  String get financeByMonth => '按月';

  @override
  String get financeByDay => '按日';

  @override
  String get financeCustomRange => '自定义范围';

  @override
  String get financeExpenseTrend => '支出趋势';

  @override
  String get financeIncomeTrend => '收入趋势';

  @override
  String get financeAssetsTrend => '资产趋势';

  @override
  String get financeThisCategory => '此分类';

  @override
  String financeNoCategoriesOfType(String type) {
    return '暂无$type分类';
  }

  @override
  String get financeImportDefaults => '导入默认分类';

  @override
  String get financeCatFood => '餐饮';

  @override
  String get financeCatTransport => '交通';

  @override
  String get financeCatShopping => '购物';

  @override
  String get financeCatRent => '房租';

  @override
  String get financeCatDigital => '数码';

  @override
  String get financeCatEntertainment => '娱乐';

  @override
  String get financeCatHealthcare => '医疗';

  @override
  String get financeCatEducation => '教育';

  @override
  String get financeCatSalary => '工资';

  @override
  String get financeCatBonus => '奖金';

  @override
  String get financeCatInvestment => '投资';

  @override
  String get financeCatFreelance => '兼职';

  @override
  String get intimacyTitle => '亲密记录';

  @override
  String get intimacyNewRecord => '新记录';

  @override
  String get intimacyEditRecord => '编辑记录';

  @override
  String get intimacySolo => '独自';

  @override
  String get intimacyPartner => '伴侣';

  @override
  String get intimacyPartners => '伴侣';

  @override
  String get intimacyAddPartner => '添加伴侣';

  @override
  String get intimacyEditPartner => '编辑伴侣';

  @override
  String get intimacyToys => '玩具';

  @override
  String get intimacyAddToy => '添加玩具';

  @override
  String get intimacyEditToy => '编辑玩具';

  @override
  String get intimacyPleasure => '愉悦度';

  @override
  String get intimacyDuration => '持续时间';

  @override
  String get intimacyLocation => '地点（可选）';

  @override
  String get intimacyNotes => '备注（可选）';

  @override
  String get intimacyOrgasm => '是否高潮？';

  @override
  String get intimacyWatchedPorn => '是否观看色情片？';

  @override
  String get intimacyTimer => '计时器';

  @override
  String get intimacyNoRecords => '暂无记录';

  @override
  String get intimacyNoPartners => '暂无伴侣';

  @override
  String get intimacyNoToys => '暂无玩具';

  @override
  String get intimacyNoPartnersHint => '暂无伴侣——请在设置中添加';

  @override
  String get intimacyShowAll => '显示全部';

  @override
  String get intimacyAllRecords => '所有记录';

  @override
  String get intimacyStart => '开始';

  @override
  String get intimacyPause => '暂停';

  @override
  String get intimacyResume => '继续';

  @override
  String get intimacyStopSave => '停止并保存';

  @override
  String get intimacyReset => '重置';

  @override
  String get intimacyTimerStartedAt => '开始于';

  @override
  String get intimacyTimerHistory => '历史记录';

  @override
  String get intimacyTimerClearHistory => '清除';

  @override
  String get intimacyTimerRetention3d => '3 天';

  @override
  String get intimacyTimerRetention7d => '7 天';

  @override
  String get intimacyTimerRetention14d => '14 天';

  @override
  String get intimacyTimerRetentionForever => '永久';

  @override
  String get intimacyManage => '管理';

  @override
  String get intimacyModuleVisible => '已显示';

  @override
  String get intimacyModuleHidden => '已隐藏';

  @override
  String get intimacySortNewest => '最新优先';

  @override
  String get intimacySortOldest => '最早优先';

  @override
  String get intimacySortPleasure => '愉悦度最高';

  @override
  String get intimacySortDuration => '时长最长';

  @override
  String get intimacyFilterAll => '全部';

  @override
  String get intimacyFilterSolo => '独自';

  @override
  String get intimacyFilterPartnered => '与伴侣';

  @override
  String get intimacyFilterOrgasm => '有高潮';

  @override
  String get intimacyFilterNoOrgasm => '无高潮';

  @override
  String get intimacyExportCsv => '导出CSV';

  @override
  String get intimacyExportCsvSuccess => 'CSV导出成功';

  @override
  String get intimacyExportCsvEmpty => '没有记录可导出';

  @override
  String get intimacyStartDate => '交往开始';

  @override
  String get intimacyEndDate => '交往结束';

  @override
  String get intimacyPurchaseDate => '购买日期';

  @override
  String get intimacyRetiredDate => '退役日期';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsGeneral => '通用';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsPrivacy => '隐私';

  @override
  String get settingsIntimacyModule => '亲密模块';

  @override
  String get settingsData => '数据';

  @override
  String get settingsStorageLocation => '存储位置';

  @override
  String get settingsStoragePathHint => '输入数据存储目录路径。留空使用默认路径。';

  @override
  String get settingsDirectoryPath => '目录路径';

  @override
  String get settingsResetDefault => '恢复默认';

  @override
  String get settingsResetDefaultLocation => '已恢复默认存储位置';

  @override
  String get settingsStoragePathUpdated => '存储路径已更新';

  @override
  String get settingsOpenDataFolder => '打开数据目录';

  @override
  String get settingsOpenDataFolderDesc => '打开应用数据文件夹';

  @override
  String get settingsWebDAVSync => 'WebDAV 同步';

  @override
  String get settingsWebDAVNotConfigured => '未配置';

  @override
  String get settingsWebDAVConfigured => '已配置';

  @override
  String get settingsWebDAVServerURL => '服务器地址';

  @override
  String get settingsWebDAVUsername => '用户名';

  @override
  String get settingsWebDAVPassword => '密码';

  @override
  String get settingsWebDAVRemotePath => '远程路径';

  @override
  String get settingsWebDAVTestConnection => '测试连接';

  @override
  String get settingsWebDAVConnectionSuccess => '连接成功';

  @override
  String get settingsWebDAVConnectionFailed => '连接失败';

  @override
  String get settingsWebDAVSyncNow => '立即同步';

  @override
  String get settingsWebDAVAutoSync => '自动同步';

  @override
  String get settingsWebDAVAutoSyncDesc => '编辑后和应用恢复时自动同步';

  @override
  String get settingsWebDAVSyncing => '同步中...';

  @override
  String get settingsWebDAVSyncSuccess => '同步完成';

  @override
  String get settingsWebDAVSyncFailed => '同步失败';

  @override
  String get settingsWebDAVConflictTitle => '同步冲突';

  @override
  String get settingsWebDAVConflictDesc => '以下记录在本地和远端都有修改，请为每条记录选择要保留的版本：';

  @override
  String get settingsWebDAVKeepLocal => '保留本地';

  @override
  String get settingsWebDAVKeepRemote => '保留远端';

  @override
  String get settingsWebDAVConflictApply => '应用';

  @override
  String get settingsWebDAVNextcloud => 'Nextcloud 预设';

  @override
  String get settingsWebDAVCustom => '自定义服务器';

  @override
  String get settingsImportExport => '导入/导出';

  @override
  String get settingsExportJSON => '导出 ZIP';

  @override
  String get settingsExportCSV => '导出 CSV';

  @override
  String get csvExportFinance => '导出财务 CSV';

  @override
  String get csvExportFinanceDesc => '财务交易为纯文本';

  @override
  String get csvExportIntimacy => '导出亲密 CSV';

  @override
  String get csvExportIntimacyDesc => '亲密记录为纯文本';

  @override
  String get csvExportWeight => '导出体重 CSV';

  @override
  String get csvExportWeightDesc => '体重记录为纯文本';

  @override
  String get settingsImport => '从文件导入';

  @override
  String get settingsExportSuccess => '导出成功';

  @override
  String get settingsExportFailed => '导出失败';

  @override
  String get settingsImportSuccess => '导入成功';

  @override
  String get settingsImportFailed => '导入失败';

  @override
  String get settingsImportConfirm => '此操作将替换所有当前数据。是否继续？';

  @override
  String get settingsExportCSVWarning => 'CSV 数据将以明文导出。是否继续？';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsAboutTitle => '关于 MyDay!!!!!';

  @override
  String get commonSave => '保存';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDelete => '删除';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonAdd => '添加';

  @override
  String get commonConfirm => '确认';

  @override
  String get commonYes => '是';

  @override
  String get commonNo => '否';

  @override
  String get commonOk => '好';

  @override
  String get commonClose => '关闭';

  @override
  String get commonName => '名称';

  @override
  String get commonEmojiOptional => '图标（可选）';

  @override
  String get commonOptional => '可选';

  @override
  String commonDeleteConfirm(String item) {
    return '删除$item？';
  }

  @override
  String commonMinutes(int count) {
    return '$count分钟';
  }

  @override
  String get settingsExportSection => '导出';

  @override
  String get settingsImportSection => '导入';

  @override
  String get settingsExportFullBackup => '所有数据的完整备份';

  @override
  String get settingsExportJSONPlaintext => '所有数据将以 ZIP 压缩包导出';

  @override
  String get settingsExportCSVPlaintext => '财务交易为纯文本';

  @override
  String get settingsImportRestore => '从ZIP备份恢复';

  @override
  String get settingsImportData => '导入数据';

  @override
  String get csvImportFinance => '导入财务 CSV';

  @override
  String get csvImportFinanceDesc => '从 CSV 合并交易记录（不会覆盖现有数据）';

  @override
  String get csvImportIntimacy => '导入亲密 CSV';

  @override
  String get csvImportIntimacyDesc => '从 CSV 合并记录（不会覆盖现有数据）';

  @override
  String get csvImportConfirm => 'CSV 数据将合并到现有记录中，是否继续？';

  @override
  String csvImportSuccess(int count) {
    return '成功导入 $count 条记录';
  }

  @override
  String get csvImportFailed => 'CSV 导入失败';

  @override
  String get csvImportEmpty => 'CSV 中未找到有效记录';

  @override
  String get csvTemplate => 'CSV 模板';

  @override
  String get csvTemplateFinance => '下载财务模板';

  @override
  String get csvTemplateIntimacy => '下载亲密模板';

  @override
  String get csvTemplateSaved => '模板已保存';

  @override
  String get settingsWebDAVDisconnect => '断开连接';

  @override
  String get settingsWebDAVConfigSaved => '配置已保存';

  @override
  String get settingsWebDAVConfigRemoved => '配置已移除';

  @override
  String get commonDontAskMinutes => '5分钟内不再询问';

  @override
  String get intimacyHideConfirm => '关闭亲密模块不会删除数据，随时可以重新开启。';

  @override
  String get settingsLicense => '许可证 (GPLv3)';

  @override
  String get settingsLicenses => '开源许可证';

  @override
  String get settingsPrivacyPolicy => '隐私政策';

  @override
  String get settingsDesktop => '桌面';

  @override
  String get settingsMinimizeToTray => '最小化到托盘';

  @override
  String get settingsCloseToTray => '关闭到托盘';

  @override
  String get financeBankPresets => '银行预设';

  @override
  String get financeBankSearch => '搜索银行或应用...';

  @override
  String get financeBankNoResults => '未找到匹配的银行';

  @override
  String get financeSubscriptions => '订阅';

  @override
  String get financeSubscription => '订阅';

  @override
  String get financeAddSubscription => '添加订阅';

  @override
  String get financeEditSubscription => '编辑订阅';

  @override
  String get financeStartDate => '开始日期';

  @override
  String get financeTrialDays => '试用天数';

  @override
  String get financeBillingCycle => '付费周期';

  @override
  String get financeBillingCycleMonthly => '按月';

  @override
  String get financeBillingCycleYearly => '按年';

  @override
  String financeEveryXMonths(int count) {
    return '每 $count 个月';
  }

  @override
  String financeEveryXYears(int count) {
    return '每 $count 年';
  }

  @override
  String get financeBillingDay => '扣费日';

  @override
  String get financeBillingMonth => '扣费月份';

  @override
  String get financeMonthlyDue => '月应付';

  @override
  String get financeMonthlyAvg => '月均花费';

  @override
  String get financeYearlyAvg => '年均花费';

  @override
  String get financeNoSubscriptions => '暂无订阅';

  @override
  String get financeActiveSubscriptions => '进行中';

  @override
  String get financeHistoricalSubscriptions => '历史';

  @override
  String get financeCancelSubscription => '取消订阅';

  @override
  String get financeCancelImmediate => '立即取消';

  @override
  String get financeCancelAtExpiry => '到期取消';

  @override
  String get financeNextBilling => '下次扣费';

  @override
  String get financeExpiryDate => '到期日期';

  @override
  String get financeTotalSpent => '累计花费';

  @override
  String get financeImportHistory => '导入历史交易';

  @override
  String get financeImportHistoryDesc => '开始日期在今天之前，是否导入历史交易？';

  @override
  String get financeThisSubscription => '此订阅';

  @override
  String financeCancelledOn(String date) {
    return '已于 $date 取消';
  }

  @override
  String get financeInterval => '间隔';

  @override
  String get financeImage => '图片';

  @override
  String get financePickImage => '选择图片';

  @override
  String get financeChangeImage => '更换';

  @override
  String get financeUpcomingRenewals => '即将续费';

  @override
  String get financeSubscriptionReminder => '订阅提醒';

  @override
  String get financeReminderTime => '通知时间';

  @override
  String get financeReminderEnabled => '提醒即将续费的服务';

  @override
  String financeSubscriptionDueSoon(String name, int days) {
    return '$name 将在 $days 天后续费';
  }

  @override
  String financeSubscriptionDueToday(String name) {
    return '$name 今天续费';
  }

  @override
  String get financeSortBy => '排序';

  @override
  String get financeSortByRenewal => '按续费日期';

  @override
  String get financeSortByName => '按名称';

  @override
  String get financeSortCustom => '自定义';

  @override
  String get financeSortReorder => '调整顺序';

  @override
  String get financeSortDone => '完成';

  @override
  String get financeRestoreSubscription => '恢复订阅';

  @override
  String get backupTitle => '备份';

  @override
  String get backupLocalOnlyNote => '备份仅保存在本机，如需云端同步请使用 WebDAV 同步。';

  @override
  String get backupSettings => '设置';

  @override
  String get backupAutoDaily => '每日自动备份';

  @override
  String get backupAutoDailyDesc => '每天自动创建一次备份';

  @override
  String get backupRetention => '保留备份';

  @override
  String get backupRetentionForever => '永久保存';

  @override
  String backupRetentionDays(int count) {
    return '$count 天';
  }

  @override
  String get backupManual => '手动备份';

  @override
  String get backupCreateNow => '立即创建备份';

  @override
  String backupHistory(int count) {
    return '备份历史 ($count)';
  }

  @override
  String get backupEmpty => '暂无备份';

  @override
  String get backupCreated => '备份创建成功';

  @override
  String get backupFailed => '备份失败';

  @override
  String get backupRestore => '还原';

  @override
  String get backupRestoreConfirmTitle => '确认还原';

  @override
  String get backupRestoreConfirmDesc => '这将替换所选模块的数据，是否继续？';

  @override
  String get backupRestoreSelectModules => '选择要还原的模块';

  @override
  String get backupRestoreAll => '全部模块';

  @override
  String get backupRestoreSuccess => '还原成功，请重启应用。';

  @override
  String get backupRestoreFailed => '还原失败';

  @override
  String get backupDeleteConfirmTitle => '删除备份';

  @override
  String get backupDeleteConfirmDesc => '该备份将被永久删除。';

  @override
  String get backupModuleTodo => '待办事项';

  @override
  String get backupModuleFinance => '财务';

  @override
  String get backupModuleRates => '汇率';

  @override
  String get backupModuleIntimacy => '亲密';

  @override
  String intimacyRecordCount(int count) {
    return '$count 条记录';
  }

  @override
  String get weightTitle => '体重';

  @override
  String get weightSetHeight => '设置身高';

  @override
  String get weightNoRecords => '暂无体重记录';

  @override
  String get weightAddRecord => '添加记录';

  @override
  String get weightKg => '体重（kg）';

  @override
  String get weightHeightCm => '身高（cm）';

  @override
  String get weightNote => '备注';

  @override
  String get weightNoteHint => '可选备注';

  @override
  String get weightChart => '趋势';

  @override
  String get weightAll => '全部';

  @override
  String get weightHistory => '历史';

  @override
  String get weightShowAll => '查看全部记录';

  @override
  String get weightDays => '天';

  @override
  String get weightDaysAgo => '天前';

  @override
  String get weightWeeksAgo => '周前';

  @override
  String get weightToday => '今天';

  @override
  String get weightYesterday => '昨天';

  @override
  String get weightRecent => '近期';

  @override
  String get weightExportCsv => '导出CSV';

  @override
  String get weightExportCsvSuccess => '体重数据导出成功';

  @override
  String get weightExportCsvEmpty => '没有体重记录可导出';

  @override
  String get csvImportWeight => '导入体重 CSV';

  @override
  String get csvImportWeightDesc => '从 CSV 合并体重记录（日期、时间、体重）';

  @override
  String get csvTemplateWeight => '下载体重模板';

  @override
  String get financeSubscriptionPresets => '快速填入';

  @override
  String get intimacyPurchaseLink => '购买链接';

  @override
  String get intimacyPrice => '价格';

  @override
  String get intimacyPositions => '体位';

  @override
  String get intimacyAddPosition => '添加体位';

  @override
  String get intimacyEditPosition => '编辑体位';

  @override
  String get intimacyNoPositions => '暂无体位';

  @override
  String get intimacyImportDefaults => '导入默认';

  @override
  String get intimacyTrend => '趋势';

  @override
  String get intimacyFrequency => '频率';

  @override
  String get intimacyChartNoData => '数据不足';

  @override
  String get weightTrend => '趋势';

  @override
  String get weightRaw => '实际';

  @override
  String get commonChange => '更换';

  @override
  String get commonPickImage => '选择图片';

  @override
  String get commonRemoveIcon => '移除图标';

  @override
  String get commonPickIcon => '选择图标';

  @override
  String get commonNoData => '暂无数据';

  @override
  String get todoDailyReminders => '每日提醒';

  @override
  String get todoRemindReviewHint => '提醒查看今天的待办事项';

  @override
  String get todoRemindUndoneHint => '提醒未完成的任务';

  @override
  String get todoTapReturnToday => '点击返回今天';

  @override
  String get todoCalendar => '日历';

  @override
  String get todoWeekMon => '周一';

  @override
  String get todoWeekTue => '周二';

  @override
  String get todoWeekWed => '周三';

  @override
  String get todoWeekThu => '周四';

  @override
  String get todoWeekFri => '周五';

  @override
  String get todoWeekSat => '周六';

  @override
  String get todoWeekSun => '周日';

  @override
  String get todoCalendarSomeDaily => '部分完成';

  @override
  String get todoCalendarAllDaily => '日常全完成';

  @override
  String get todoCalendarAllDone => '全部完成';

  @override
  String get todoWhatNeedsDone => '需要做什么？';

  @override
  String todoReminderAt(String time) {
    return '提醒：$time';
  }

  @override
  String get todoAddReminder => '添加提醒（可选）';

  @override
  String todoScheduledAt(String date) {
    return '计划：$date';
  }

  @override
  String get todoSetScheduledDate => '设定计划日期';

  @override
  String todoCompletedAt(String date) {
    return '完成：$date';
  }

  @override
  String get todoSetCompletedDate => '设定完成日期';

  @override
  String get weightUnitKg => 'kg';

  @override
  String weightValueKg(String value) {
    return '$value kg';
  }

  @override
  String get positionMissionary => '传教士式';

  @override
  String get positionCowgirl => '骑乘式';

  @override
  String get positionDoggyStyle => '后入式';

  @override
  String get positionReverseCowgirl => '反骑乘式';

  @override
  String get positionSpooning => '侧入式';

  @override
  String get positionStanding => '站立式';

  @override
  String get position69 => '69式';

  @override
  String get positionLotus => '莲花式';

  @override
  String get positionProneBone => '趴伏式';

  @override
  String get notifTodoMorning => '早上好！是时候查看和更新您的待办事项了 📝';

  @override
  String get notifTodoCompletion => '别忘了完成今天剩余的任务！';

  @override
  String notifTodoUncompleted(int count) {
    return '今天还有 $count 项任务未完成！';
  }

  @override
  String notifUpcomingRenewals(String list) {
    return '即将续费：$list';
  }

  @override
  String notifSubscriptionToday(String name) {
    return '$name（今天）';
  }

  @override
  String notifSubscriptionDays(String name, int days) {
    return '$name（$days天后）';
  }

  @override
  String get trayShow => '显示';

  @override
  String get trayQuit => '退出';

  @override
  String get filePickerExportLocation => '选择导出位置';

  @override
  String get filePickerBackupFile => '选择备份文件';

  @override
  String get filePickerCsvFile => '选择 CSV 文件';

  @override
  String get filePickerSaveTemplate => '保存模板到';

  @override
  String get financeBalance => '余额';

  @override
  String get financeNewAccount => '新建账户';

  @override
  String get financeAccountTypeFund => '储蓄';

  @override
  String get financeAccountTypeCredit => '信用';

  @override
  String get financeAccountTypeRecharge => '充值';

  @override
  String get financeAccountTypeFinancial => '理财';

  @override
  String get financeAccountName => '账户名称';

  @override
  String get financeBankAppHint => '例如工行、支付宝';

  @override
  String get financeCardNumberHint => '后四位';

  @override
  String get financeCurrentBalanceHint => '留空则根据交易计算';

  @override
  String get financeAsOfToday => '截止今天';

  @override
  String get financeBalanceEffectiveDate => '余额生效日期';

  @override
  String get financeFetchIcon => '获取图标';

  @override
  String get financeAccountsCategories => '账户与分类';

  @override
  String get financeEditRate => '编辑汇率';

  @override
  String get financeNewRate => '新建汇率';

  @override
  String get financeFrom => '从';

  @override
  String get financeTo => '到';

  @override
  String get financeRate => '汇率';

  @override
  String financeRateHint(String from, String to) {
    return '1 $from = ? $to';
  }

  @override
  String get financeNoRates => '未配置汇率';

  @override
  String get financeNoExpenseData => '该时段无支出数据';

  @override
  String get financeUncategorized => '未分类';

  @override
  String get financeTotal => '合计';

  @override
  String get financeSelectDateRange => '选择日期范围';

  @override
  String get financeNoTransactionData => '该时段无交易数据';

  @override
  String financeReceivedAmount(String currency) {
    return '到账金额 ($currency)';
  }

  @override
  String get financeReceivedAmountHelper => '目标账户币种的到账金额';

  @override
  String get financeNoteHint => '这笔钱用于？';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => 'MyDay!!!!!';

  @override
  String get navTodo => '待辦';

  @override
  String get navFinance => '財務';

  @override
  String get navWeight => '體重';

  @override
  String get navIntimacy => '親密';

  @override
  String get navSettings => '設定';

  @override
  String get todoSectionDaily => '每日';

  @override
  String get todoSectionRoutine => '日常';

  @override
  String get todoSectionWork => '工作';

  @override
  String get todoAddTask => '新增任務';

  @override
  String get todoEditTask => '編輯任務';

  @override
  String get todoTitle => '標題';

  @override
  String get todoSubtasks => '子任務';

  @override
  String get todoAddSubtask => '新增子任務';

  @override
  String get todoReminderTime => '提醒時間';

  @override
  String get todoNoTasks => '暫無任務';

  @override
  String get todoType => '類型';

  @override
  String get todoEmoji => '圖示';

  @override
  String get todoDailyTask => '每日';

  @override
  String get todoRoutineTask => '日常一次';

  @override
  String get todoWorkTask => '工作一次';

  @override
  String todoCreatedDate(String date) {
    return '建立日期：$date';
  }

  @override
  String todoStartDate(String date) {
    return '開始日期：$date';
  }

  @override
  String todoDeletedDate(String date) {
    return '刪除日期：$date';
  }

  @override
  String get todoPermanentDelete => '徹底刪除';

  @override
  String get todoPermanentDeleteConfirm => '這將永久刪除此任務及其所有歷史記錄。是否繼續？';

  @override
  String get todoMorningReminder => '晨間計畫提醒';

  @override
  String get todoCompletionReminder => '完成檢查提醒';

  @override
  String get todoSetReminder => '設定提醒';

  @override
  String get todoClearReminder => '清除';

  @override
  String todoReminderSet(String time) {
    return '提醒已設定：$time';
  }

  @override
  String get todoCompleted => '已完成';

  @override
  String get todoDueDate => '截止日期';

  @override
  String get todoSetDueDate => '設定截止日期（可選）';

  @override
  String get todoCustomEmoji => '自訂圖示';

  @override
  String get todoCustomEmojiHint => '輸入一個 emoji';

  @override
  String get todoEditSubtask => '編輯子任務';

  @override
  String get financeTitle => '財務';

  @override
  String get financeMonthlyExpense => '月度支出';

  @override
  String get financeTotalAssets => '總資產';

  @override
  String get financeAccounts => '帳戶';

  @override
  String get financeCategories => '分類';

  @override
  String get financeTrends => '趨勢';

  @override
  String get financeAnalysis => '分析';

  @override
  String get financeExchangeRates => '匯率';

  @override
  String get financeRefreshRates => '刷新匯率';

  @override
  String get financeAddTransaction => '新增交易';

  @override
  String get financeEditTransaction => '編輯交易';

  @override
  String get financeExpense => '支出';

  @override
  String get financeIncome => '收入';

  @override
  String get financeTransfer => '轉帳';

  @override
  String get financeAmount => '金額';

  @override
  String get financeNote => '備註';

  @override
  String get financeCategory => '分類';

  @override
  String get financeAccount => '帳戶';

  @override
  String get financeFromAccount => '轉出帳戶';

  @override
  String get financeToAccount => '轉入帳戶';

  @override
  String get financeCurrency => '幣種';

  @override
  String get financeDate => '日期';

  @override
  String get financeNoTransactions => '暫無交易';

  @override
  String get financeForceBalance => '強制餘額';

  @override
  String get financeCurrentBalance => '目前餘額';

  @override
  String get financeAddAccount => '新增帳戶';

  @override
  String get financeEditAccount => '編輯帳戶';

  @override
  String get financeAddCategory => '新增分類';

  @override
  String get financeEditCategory => '編輯分類';

  @override
  String get financeName => '名稱';

  @override
  String get financeBankApp => '銀行 / App';

  @override
  String get financeCardNumber => '卡號（選填）';

  @override
  String get financeExpiry => '有效期';

  @override
  String get financeSecurityCode => '安全碼';

  @override
  String get financeIcon => '圖示';

  @override
  String get financeEmoji => '表情';

  @override
  String get financeCategoryHintExpense => '例如 餐飲、交通';

  @override
  String get financeCategoryHintIncome => '例如 薪資、投資';

  @override
  String get financeThisTransaction => '此流水';

  @override
  String get financeNoAccounts => '暫無帳戶';

  @override
  String get financeNoCategories => '暫無分類';

  @override
  String get financeByYear => '按年';

  @override
  String get financeByMonth => '按月';

  @override
  String get financeByDay => '按日';

  @override
  String get financeCustomRange => '自訂範圍';

  @override
  String get financeExpenseTrend => '支出趨勢';

  @override
  String get financeIncomeTrend => '收入趨勢';

  @override
  String get financeAssetsTrend => '資產趨勢';

  @override
  String get financeThisCategory => '此分類';

  @override
  String financeNoCategoriesOfType(String type) {
    return '暫無$type分類';
  }

  @override
  String get financeImportDefaults => '匯入預設分類';

  @override
  String get financeCatFood => '餐飲';

  @override
  String get financeCatTransport => '交通';

  @override
  String get financeCatShopping => '購物';

  @override
  String get financeCatRent => '房租';

  @override
  String get financeCatDigital => '數位';

  @override
  String get financeCatEntertainment => '娛樂';

  @override
  String get financeCatHealthcare => '醫療';

  @override
  String get financeCatEducation => '教育';

  @override
  String get financeCatSalary => '薪資';

  @override
  String get financeCatBonus => '獎金';

  @override
  String get financeCatInvestment => '投資';

  @override
  String get financeCatFreelance => '兼職';

  @override
  String get intimacyTitle => '親密記錄';

  @override
  String get intimacyNewRecord => '新記錄';

  @override
  String get intimacyEditRecord => '編輯記錄';

  @override
  String get intimacySolo => '獨自';

  @override
  String get intimacyPartner => '伴侶';

  @override
  String get intimacyPartners => '伴侶';

  @override
  String get intimacyAddPartner => '新增伴侶';

  @override
  String get intimacyEditPartner => '編輯伴侶';

  @override
  String get intimacyToys => '玩具';

  @override
  String get intimacyAddToy => '新增玩具';

  @override
  String get intimacyEditToy => '編輯玩具';

  @override
  String get intimacyPleasure => '愉悅度';

  @override
  String get intimacyDuration => '持續時間';

  @override
  String get intimacyLocation => '地點（可選）';

  @override
  String get intimacyNotes => '備註（可選）';

  @override
  String get intimacyOrgasm => '是否高潮？';

  @override
  String get intimacyWatchedPorn => '是否觀看色情片？';

  @override
  String get intimacyTimer => '計時器';

  @override
  String get intimacyNoRecords => '暫無記錄';

  @override
  String get intimacyNoPartners => '暫無伴侶';

  @override
  String get intimacyNoToys => '暫無玩具';

  @override
  String get intimacyNoPartnersHint => '暫無伴侶——請在設定中新增';

  @override
  String get intimacyShowAll => '顯示全部';

  @override
  String get intimacyAllRecords => '所有記錄';

  @override
  String get intimacyStart => '開始';

  @override
  String get intimacyPause => '暫停';

  @override
  String get intimacyResume => '繼續';

  @override
  String get intimacyStopSave => '停止並儲存';

  @override
  String get intimacyReset => '重置';

  @override
  String get intimacyTimerStartedAt => '開始於';

  @override
  String get intimacyTimerHistory => '歷史記錄';

  @override
  String get intimacyTimerClearHistory => '清除';

  @override
  String get intimacyTimerRetention3d => '3 天';

  @override
  String get intimacyTimerRetention7d => '7 天';

  @override
  String get intimacyTimerRetention14d => '14 天';

  @override
  String get intimacyTimerRetentionForever => '永久';

  @override
  String get intimacyManage => '管理';

  @override
  String get intimacyModuleVisible => '已顯示';

  @override
  String get intimacyModuleHidden => '已隱藏';

  @override
  String get intimacySortNewest => '最新優先';

  @override
  String get intimacySortOldest => '最早優先';

  @override
  String get intimacySortPleasure => '愉悅度最高';

  @override
  String get intimacySortDuration => '時長最長';

  @override
  String get intimacyFilterAll => '全部';

  @override
  String get intimacyFilterSolo => '獨自';

  @override
  String get intimacyFilterPartnered => '與伴侶';

  @override
  String get intimacyFilterOrgasm => '有高潮';

  @override
  String get intimacyFilterNoOrgasm => '無高潮';

  @override
  String get intimacyExportCsv => '匯出CSV';

  @override
  String get intimacyExportCsvSuccess => 'CSV匯出成功';

  @override
  String get intimacyExportCsvEmpty => '沒有記錄可匯出';

  @override
  String get intimacyStartDate => '交往開始';

  @override
  String get intimacyEndDate => '交往結束';

  @override
  String get intimacyPurchaseDate => '購買日期';

  @override
  String get intimacyRetiredDate => '退役日期';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsGeneral => '一般';

  @override
  String get settingsLanguage => '語言';

  @override
  String get settingsTheme => '主題';

  @override
  String get settingsThemeSystem => '跟隨系統';

  @override
  String get settingsThemeLight => '淺色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsPrivacy => '隱私';

  @override
  String get settingsIntimacyModule => '親密模組';

  @override
  String get settingsData => '資料';

  @override
  String get settingsStorageLocation => '儲存位置';

  @override
  String get settingsStoragePathHint => '輸入資料儲存目錄路徑。留空使用預設路徑。';

  @override
  String get settingsDirectoryPath => '目錄路徑';

  @override
  String get settingsResetDefault => '恢復預設';

  @override
  String get settingsResetDefaultLocation => '已恢復預設儲存位置';

  @override
  String get settingsStoragePathUpdated => '儲存路徑已更新';

  @override
  String get settingsOpenDataFolder => '開啟資料目錄';

  @override
  String get settingsOpenDataFolderDesc => '開啟應用程式資料夾';

  @override
  String get settingsWebDAVSync => 'WebDAV 同步';

  @override
  String get settingsWebDAVNotConfigured => '未設定';

  @override
  String get settingsWebDAVConfigured => '已設定';

  @override
  String get settingsWebDAVServerURL => '伺服器位址';

  @override
  String get settingsWebDAVUsername => '使用者名稱';

  @override
  String get settingsWebDAVPassword => '密碼';

  @override
  String get settingsWebDAVRemotePath => '遠端路徑';

  @override
  String get settingsWebDAVTestConnection => '測試連線';

  @override
  String get settingsWebDAVConnectionSuccess => '連線成功';

  @override
  String get settingsWebDAVConnectionFailed => '連線失敗';

  @override
  String get settingsWebDAVSyncNow => '立即同步';

  @override
  String get settingsWebDAVAutoSync => '自動同步';

  @override
  String get settingsWebDAVAutoSyncDesc => '編輯後和應用程式恢復時自動同步';

  @override
  String get settingsWebDAVSyncing => '同步中...';

  @override
  String get settingsWebDAVSyncSuccess => '同步完成';

  @override
  String get settingsWebDAVSyncFailed => '同步失敗';

  @override
  String get settingsWebDAVConflictTitle => '同步衝突';

  @override
  String get settingsWebDAVConflictDesc => '以下紀錄在本機和遠端都有修改，請為每筆紀錄選擇要保留的版本：';

  @override
  String get settingsWebDAVKeepLocal => '保留本機';

  @override
  String get settingsWebDAVKeepRemote => '保留遠端';

  @override
  String get settingsWebDAVConflictApply => '套用';

  @override
  String get settingsWebDAVNextcloud => 'Nextcloud 預設';

  @override
  String get settingsWebDAVCustom => '自訂伺服器';

  @override
  String get settingsImportExport => '匯入/匯出';

  @override
  String get settingsExportJSON => '匯出 ZIP';

  @override
  String get settingsExportCSV => '匯出 CSV';

  @override
  String get csvExportFinance => '匯出財務 CSV';

  @override
  String get csvExportFinanceDesc => '財務交易為純文字';

  @override
  String get csvExportIntimacy => '匯出親密 CSV';

  @override
  String get csvExportIntimacyDesc => '親密記錄為純文字';

  @override
  String get csvExportWeight => '匯出體重 CSV';

  @override
  String get csvExportWeightDesc => '體重記錄為純文字';

  @override
  String get settingsImport => '從檔案匯入';

  @override
  String get settingsExportSuccess => '匯出成功';

  @override
  String get settingsExportFailed => '匯出失敗';

  @override
  String get settingsImportSuccess => '匯入成功';

  @override
  String get settingsImportFailed => '匯入失敗';

  @override
  String get settingsImportConfirm => '此操作將取代所有目前資料。是否繼續？';

  @override
  String get settingsExportCSVWarning => 'CSV 資料將以明文匯出。是否繼續？';

  @override
  String get settingsAbout => '關於';

  @override
  String get settingsAboutTitle => '關於 MyDay!!!!!';

  @override
  String get commonSave => '儲存';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDelete => '刪除';

  @override
  String get commonEdit => '編輯';

  @override
  String get commonAdd => '新增';

  @override
  String get commonConfirm => '確認';

  @override
  String get commonYes => '是';

  @override
  String get commonNo => '否';

  @override
  String get commonOk => '好';

  @override
  String get commonClose => '關閉';

  @override
  String get commonName => '名稱';

  @override
  String get commonEmojiOptional => '圖示（可選）';

  @override
  String get commonOptional => '可選';

  @override
  String commonDeleteConfirm(String item) {
    return '刪除$item？';
  }

  @override
  String commonMinutes(int count) {
    return '$count分鐘';
  }

  @override
  String get settingsExportSection => '匯出';

  @override
  String get settingsImportSection => '匯入';

  @override
  String get settingsExportFullBackup => '所有資料的完整備份';

  @override
  String get settingsExportJSONPlaintext => '所有資料將以 ZIP 壓縮檔匯出';

  @override
  String get settingsExportCSVPlaintext => '財務交易為純文字';

  @override
  String get settingsImportRestore => '從ZIP備份還原';

  @override
  String get settingsImportData => '匯入資料';

  @override
  String get csvImportFinance => '匯入財務 CSV';

  @override
  String get csvImportFinanceDesc => '從 CSV 合併交易記錄（不會覆蓋現有資料）';

  @override
  String get csvImportIntimacy => '匯入親密 CSV';

  @override
  String get csvImportIntimacyDesc => '從 CSV 合併記錄（不會覆蓋現有資料）';

  @override
  String get csvImportConfirm => 'CSV 資料將合併到現有記錄中，是否繼續？';

  @override
  String csvImportSuccess(int count) {
    return '成功匯入 $count 筆記錄';
  }

  @override
  String get csvImportFailed => 'CSV 匯入失敗';

  @override
  String get csvImportEmpty => 'CSV 中未找到有效記錄';

  @override
  String get csvTemplate => 'CSV 模板';

  @override
  String get csvTemplateFinance => '下載財務模板';

  @override
  String get csvTemplateIntimacy => '下載親密模板';

  @override
  String get csvTemplateSaved => '模板已儲存';

  @override
  String get settingsWebDAVDisconnect => '中斷連線';

  @override
  String get settingsWebDAVConfigSaved => '設定已儲存';

  @override
  String get settingsWebDAVConfigRemoved => '設定已移除';

  @override
  String get commonDontAskMinutes => '5分鐘內不再詢問';

  @override
  String get intimacyHideConfirm => '關閉親密模組不會刪除資料，隨時可以重新開啟。';

  @override
  String get settingsLicense => '授權條款 (GPLv3)';

  @override
  String get settingsLicenses => '開源授權條款';

  @override
  String get settingsPrivacyPolicy => '隱私政策';

  @override
  String get settingsDesktop => '桌面';

  @override
  String get settingsMinimizeToTray => '最小化至系統匙';

  @override
  String get settingsCloseToTray => '關閉至系統匙';

  @override
  String get financeBankPresets => '銀行預設';

  @override
  String get financeBankSearch => '搜尋銀行或應用...';

  @override
  String get financeBankNoResults => '未找到符合的銀行';

  @override
  String get financeSubscriptions => '訂閱';

  @override
  String get financeSubscription => '訂閱';

  @override
  String get financeAddSubscription => '新增訂閱';

  @override
  String get financeEditSubscription => '編輯訂閱';

  @override
  String get financeStartDate => '開始日期';

  @override
  String get financeTrialDays => '試用天數';

  @override
  String get financeBillingCycle => '付費週期';

  @override
  String get financeBillingCycleMonthly => '按月';

  @override
  String get financeBillingCycleYearly => '按年';

  @override
  String financeEveryXMonths(int count) {
    return '每 $count 個月';
  }

  @override
  String financeEveryXYears(int count) {
    return '每 $count 年';
  }

  @override
  String get financeBillingDay => '扣費日';

  @override
  String get financeBillingMonth => '扣費月份';

  @override
  String get financeMonthlyDue => '月應付';

  @override
  String get financeMonthlyAvg => '月均花費';

  @override
  String get financeYearlyAvg => '年均花費';

  @override
  String get financeNoSubscriptions => '暫無訂閱';

  @override
  String get financeActiveSubscriptions => '進行中';

  @override
  String get financeHistoricalSubscriptions => '歷史';

  @override
  String get financeCancelSubscription => '取消訂閱';

  @override
  String get financeCancelImmediate => '立即取消';

  @override
  String get financeCancelAtExpiry => '到期取消';

  @override
  String get financeNextBilling => '下次扣費';

  @override
  String get financeExpiryDate => '到期日期';

  @override
  String get financeTotalSpent => '累計花費';

  @override
  String get financeImportHistory => '匯入歷史交易';

  @override
  String get financeImportHistoryDesc => '開始日期在今天之前，是否匯入歷史交易？';

  @override
  String get financeThisSubscription => '此訂閱';

  @override
  String financeCancelledOn(String date) {
    return '已於 $date 取消';
  }

  @override
  String get financeInterval => '間隔';

  @override
  String get financeImage => '圖片';

  @override
  String get financePickImage => '選擇圖片';

  @override
  String get financeChangeImage => '更換';

  @override
  String get financeUpcomingRenewals => '即將續費';

  @override
  String get financeSubscriptionReminder => '訂閱提醒';

  @override
  String get financeReminderTime => '通知時間';

  @override
  String get financeReminderEnabled => '提醒即將續費的服務';

  @override
  String financeSubscriptionDueSoon(String name, int days) {
    return '$name 將在 $days 天後續費';
  }

  @override
  String financeSubscriptionDueToday(String name) {
    return '$name 今天續費';
  }

  @override
  String get financeSortBy => '排序';

  @override
  String get financeSortByRenewal => '按續費日期';

  @override
  String get financeSortByName => '按名稱';

  @override
  String get financeSortCustom => '自訂';

  @override
  String get financeSortReorder => '調整順序';

  @override
  String get financeSortDone => '完成';

  @override
  String get financeRestoreSubscription => '恢復訂閱';

  @override
  String get backupTitle => '備份';

  @override
  String get backupLocalOnlyNote => '備份僅儲存在本機，如需雲端同步請使用 WebDAV 同步。';

  @override
  String get backupSettings => '設定';

  @override
  String get backupAutoDaily => '每日自動備份';

  @override
  String get backupAutoDailyDesc => '每天自動建立一次備份';

  @override
  String get backupRetention => '保留備份';

  @override
  String get backupRetentionForever => '永久保存';

  @override
  String backupRetentionDays(int count) {
    return '$count 天';
  }

  @override
  String get backupManual => '手動備份';

  @override
  String get backupCreateNow => '立即建立備份';

  @override
  String backupHistory(int count) {
    return '備份歷史 ($count)';
  }

  @override
  String get backupEmpty => '尚無備份';

  @override
  String get backupCreated => '備份建立成功';

  @override
  String get backupFailed => '備份失敗';

  @override
  String get backupRestore => '還原';

  @override
  String get backupRestoreConfirmTitle => '確認還原';

  @override
  String get backupRestoreConfirmDesc => '這將替換所選模組的資料，是否繼續？';

  @override
  String get backupRestoreSelectModules => '選擇要還原的模組';

  @override
  String get backupRestoreAll => '全部模組';

  @override
  String get backupRestoreSuccess => '還原成功，請重啟應用。';

  @override
  String get backupRestoreFailed => '還原失敗';

  @override
  String get backupDeleteConfirmTitle => '刪除備份';

  @override
  String get backupDeleteConfirmDesc => '該備份將被永久刪除。';

  @override
  String get backupModuleTodo => '待辦事項';

  @override
  String get backupModuleFinance => '財務';

  @override
  String get backupModuleRates => '匯率';

  @override
  String get backupModuleIntimacy => '親密';

  @override
  String intimacyRecordCount(int count) {
    return '$count 條記錄';
  }

  @override
  String get weightTitle => '體重';

  @override
  String get weightSetHeight => '設定身高';

  @override
  String get weightNoRecords => '暫無體重記錄';

  @override
  String get weightAddRecord => '新增記錄';

  @override
  String get weightKg => '體重（kg）';

  @override
  String get weightHeightCm => '身高（cm）';

  @override
  String get weightNote => '備註';

  @override
  String get weightNoteHint => '可選備註';

  @override
  String get weightChart => '趨勢';

  @override
  String get weightAll => '全部';

  @override
  String get weightHistory => '歷史';

  @override
  String get weightShowAll => '查看全部記錄';

  @override
  String get weightDays => '天';

  @override
  String get weightDaysAgo => '天前';

  @override
  String get weightWeeksAgo => '週前';

  @override
  String get weightToday => '今天';

  @override
  String get weightYesterday => '昨天';

  @override
  String get weightRecent => '近期';

  @override
  String get weightExportCsv => '匯出CSV';

  @override
  String get weightExportCsvSuccess => '體重資料匯出成功';

  @override
  String get weightExportCsvEmpty => '沒有體重記錄可匯出';

  @override
  String get csvImportWeight => '匯入體重 CSV';

  @override
  String get csvImportWeightDesc => '從 CSV 合併體重記錄（日期、時間、體重）';

  @override
  String get csvTemplateWeight => '下載體重模板';

  @override
  String get financeSubscriptionPresets => '快速填入';

  @override
  String get intimacyPurchaseLink => '購買連結';

  @override
  String get intimacyPrice => '價格';

  @override
  String get intimacyPositions => '體位';

  @override
  String get intimacyAddPosition => '新增體位';

  @override
  String get intimacyEditPosition => '編輯體位';

  @override
  String get intimacyNoPositions => '尚無體位';

  @override
  String get intimacyImportDefaults => '匯入預設';

  @override
  String get intimacyTrend => '趨勢';

  @override
  String get intimacyFrequency => '頻率';

  @override
  String get intimacyChartNoData => '資料不足';

  @override
  String get weightTrend => '趨勢';

  @override
  String get weightRaw => '實際';

  @override
  String get commonChange => '更換';

  @override
  String get commonPickImage => '選擇圖片';

  @override
  String get commonRemoveIcon => '移除圖示';

  @override
  String get commonPickIcon => '選擇圖示';

  @override
  String get commonNoData => '無資料';

  @override
  String get todoDailyReminders => '每日提醒';

  @override
  String get todoRemindReviewHint => '提醒查看今日待辦事項';

  @override
  String get todoRemindUndoneHint => '提醒未完成的任務';

  @override
  String get todoTapReturnToday => '點擊返回今天';

  @override
  String get todoCalendar => '日曆';

  @override
  String get todoWeekMon => '一';

  @override
  String get todoWeekTue => '二';

  @override
  String get todoWeekWed => '三';

  @override
  String get todoWeekThu => '四';

  @override
  String get todoWeekFri => '五';

  @override
  String get todoWeekSat => '六';

  @override
  String get todoWeekSun => '日';

  @override
  String get todoCalendarSomeDaily => '部分完成';

  @override
  String get todoCalendarAllDaily => '日常全完成';

  @override
  String get todoCalendarAllDone => '全部完成';

  @override
  String get todoWhatNeedsDone => '需要做什麼？';

  @override
  String todoReminderAt(String time) {
    return '提醒: $time';
  }

  @override
  String get todoAddReminder => '新增提醒（選填）';

  @override
  String todoScheduledAt(String date) {
    return '排程: $date';
  }

  @override
  String get todoSetScheduledDate => '設定排程日期';

  @override
  String todoCompletedAt(String date) {
    return '完成: $date';
  }

  @override
  String get todoSetCompletedDate => '設定完成日期';

  @override
  String get weightUnitKg => 'kg';

  @override
  String weightValueKg(String value) {
    return '$value kg';
  }

  @override
  String get positionMissionary => '傳教士式';

  @override
  String get positionCowgirl => '騎乘式';

  @override
  String get positionDoggyStyle => '後入式';

  @override
  String get positionReverseCowgirl => '反騎乘式';

  @override
  String get positionSpooning => '側入式';

  @override
  String get positionStanding => '站立式';

  @override
  String get position69 => '69式';

  @override
  String get positionLotus => '蓮花式';

  @override
  String get positionProneBone => '趴伏式';

  @override
  String get notifTodoMorning => '早安！是時候查看和更新您的待辦事項了 📝';

  @override
  String get notifTodoCompletion => '別忘了完成今天剩餘的任務！';

  @override
  String notifTodoUncompleted(int count) {
    return '今天還有 $count 個任務未完成！';
  }

  @override
  String notifUpcomingRenewals(String list) {
    return '即將續費: $list';
  }

  @override
  String notifSubscriptionToday(String name) {
    return '$name（今天）';
  }

  @override
  String notifSubscriptionDays(String name, int days) {
    return '$name（$days天後）';
  }

  @override
  String get trayShow => '顯示';

  @override
  String get trayQuit => '退出';

  @override
  String get filePickerExportLocation => '選擇匯出位置';

  @override
  String get filePickerBackupFile => '選擇備份檔案';

  @override
  String get filePickerCsvFile => '選擇CSV檔案';

  @override
  String get filePickerSaveTemplate => '儲存範本到';

  @override
  String get financeBalance => '餘額';

  @override
  String get financeNewAccount => '新增帳戶';

  @override
  String get financeAccountTypeFund => '活存';

  @override
  String get financeAccountTypeCredit => '信用卡';

  @override
  String get financeAccountTypeRecharge => '儲值';

  @override
  String get financeAccountTypeFinancial => '理財';

  @override
  String get financeAccountName => '帳戶名稱';

  @override
  String get financeBankAppHint => '例如：玉山銀行、街口支付';

  @override
  String get financeCardNumberHint => '末4碼';

  @override
  String get financeCurrentBalanceHint => '留空則從交易記錄計算';

  @override
  String get financeAsOfToday => '截至今日';

  @override
  String get financeBalanceEffectiveDate => '餘額生效日期';

  @override
  String get financeFetchIcon => '取得圖示';

  @override
  String get financeAccountsCategories => '帳戶與分類';

  @override
  String get financeEditRate => '編輯匯率';

  @override
  String get financeNewRate => '新增匯率';

  @override
  String get financeFrom => '從';

  @override
  String get financeTo => '到';

  @override
  String get financeRate => '匯率';

  @override
  String financeRateHint(String from, String to) {
    return '1 $from = ? $to';
  }

  @override
  String get financeNoRates => '尚未設定匯率';

  @override
  String get financeNoExpenseData => '此期間無支出資料';

  @override
  String get financeUncategorized => '未分類';

  @override
  String get financeTotal => '合計';

  @override
  String get financeSelectDateRange => '選擇日期範圍';

  @override
  String get financeNoTransactionData => '此期間無交易資料';

  @override
  String financeReceivedAmount(String currency) {
    return '入帳金額 ($currency)';
  }

  @override
  String get financeReceivedAmountHelper => '對方帳戶幣別的入帳金額';

  @override
  String get financeNoteHint => '這筆是為了什麼？';
}
