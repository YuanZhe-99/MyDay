// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  /// Purpose: Return the localized string for `appTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get appTitle => 'MyDay!!!!!';

  /// Purpose: Return the localized string for `navTodo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get navTodo => '待办';

  /// Purpose: Return the localized string for `navFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get navFinance => '财务';

  /// Purpose: Return the localized string for `navWeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get navWeight => '体重';

  /// Purpose: Return the localized string for `navIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get navIntimacy => '亲密';

  /// Purpose: Return the localized string for `navSettings`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get navSettings => '设置';

  /// Purpose: Return the localized string for `todoSectionDaily`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSectionDaily => '每日';

  /// Purpose: Return the localized string for `todoSectionRoutine`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSectionRoutine => '日常';

  /// Purpose: Return the localized string for `todoSectionWork`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSectionWork => '工作';

  /// Purpose: Return the localized string for `todoAddTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoAddTask => '添加任务';

  /// Purpose: Return the localized string for `todoEditTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoEditTask => '编辑任务';

  /// Purpose: Return the localized string for `todoTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoTitle => '标题';

  /// Purpose: Return the localized string for `todoNote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoNote => '备注';

  /// Purpose: Return the localized string for `todoNoteHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoNoteHint => '添加可选备注';

  /// Purpose: Return the localized string for `todoSubtasks`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSubtasks => '子任务';

  /// Purpose: Return the localized string for `todoAddSubtask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoAddSubtask => '添加子任务';

  /// Purpose: Return the localized string for `todoReminderTime`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoReminderTime => '提醒时间';

  /// Purpose: Return the localized string for `todoNoTasks`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoNoTasks => '暂无任务';

  /// Purpose: Return the localized string for `todoType`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoType => '类型';

  /// Purpose: Return the localized string for `todoEmoji`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoEmoji => '图标';

  /// Purpose: Return the localized string for `todoDailyTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoDailyTask => '每日';

  /// Purpose: Return the localized string for `todoRoutineTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoRoutineTask => '日常一次';

  /// Purpose: Return the localized string for `todoWorkTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWorkTask => '工作一次';

  /// Purpose: Implement the todo created date behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoCreatedDate(String date) {
    return '建立日期：$date';
  }

  /// Purpose: Implement the todo start date behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoStartDate(String date) {
    return '开始日期：$date';
  }

  /// Purpose: Implement the todo deleted date behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoDeletedDate(String date) {
    return '删除日期：$date';
  }

  /// Purpose: Return the localized string for `todoPermanentDelete`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoPermanentDelete => '彻底删除';

  /// Purpose: Return the localized string for `todoPermanentDeleteConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoPermanentDeleteConfirm => '这将永久删除此任务及其所有历史记录。是否继续？';

  /// Purpose: Return the localized string for `todoMorningReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoMorningReminder => '晨间计划提醒';

  /// Purpose: Return the localized string for `todoCompletionReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCompletionReminder => '完成检查提醒';

  /// Purpose: Return the localized string for `todoSetReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSetReminder => '设置提醒';

  /// Purpose: Return the localized string for `todoClearReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoClearReminder => '清除';

  /// Purpose: Implement the todo reminder set behavior for this file.
  /// Inputs: `time`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoReminderSet(String time) {
    return '提醒已设置：$time';
  }

  /// Purpose: Return the localized string for `todoCompleted`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCompleted => '已完成';

  /// Purpose: Return the localized string for `todoDueDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoDueDate => '截止日期';

  /// Purpose: Return the localized string for `todoSetDueDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSetDueDate => '设置截止日期（可选）';

  /// Purpose: Return the localized string for `todoCustomEmoji`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCustomEmoji => '自定义图标';

  /// Purpose: Return the localized string for `todoCustomEmojiHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCustomEmojiHint => '输入一个 emoji';

  /// Purpose: Return the localized string for `todoEditSubtask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoEditSubtask => '编辑子任务';

  /// Purpose: Implement the todo subtasks progress behavior for this file.
  /// Inputs: `done`, `total`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoSubtasksProgress(int done, int total) {
    return '子任务：$done/$total';
  }

  /// Purpose: Implement the todo task due behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoTaskDue(String date) {
    return '截止：$date';
  }

  /// Purpose: Implement the todo task note behavior for this file.
  /// Inputs: `note`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoTaskNote(String note) {
    return '备注：$note';
  }

  /// Purpose: Return the localized string for `todoThisTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoThisTask => '此任务';

  /// Purpose: Return the localized string for `financeTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTitle => '财务';

  /// Purpose: Return the localized string for `financeMonthlyExpense`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeMonthlyExpense => '月度支出';

  /// Purpose: Return the localized string for `financeTotalAssets`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTotalAssets => '总资产';

  /// Purpose: Return the localized string for `financeAccounts`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccounts => '账户';

  /// Purpose: Return the localized string for `financeCategories`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCategories => '分类';

  /// Purpose: Return the localized string for `financeTrends`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTrends => '趋势';

  /// Purpose: Return the localized string for `financeAnalysis`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAnalysis => '分析';

  /// Purpose: Return the localized string for `financeExchangeRates`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeExchangeRates => '汇率';

  /// Purpose: Return the localized string for `financeRefreshRates`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeRefreshRates => '刷新汇率';

  /// Purpose: Return the localized string for `financeAddTransaction`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAddTransaction => '添加交易';

  /// Purpose: Return the localized string for `financeEditTransaction`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEditTransaction => '编辑交易';

  /// Purpose: Return the localized string for `financeExpense`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeExpense => '支出';

  /// Purpose: Return the localized string for `financeIncome`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeIncome => '收入';

  /// Purpose: Return the localized string for `financeTransfer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTransfer => '转账';

  /// Purpose: Return the localized string for `financeAmount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAmount => '金额';

  /// Purpose: Return the localized string for `financeNote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNote => '备注';

  /// Purpose: Return the localized string for `financeCategory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCategory => '分类';

  /// Purpose: Return the localized string for `financeAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccount => '账户';

  /// Purpose: Return the localized string for `financeFromAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFromAccount => '转出账户';

  /// Purpose: Return the localized string for `financeToAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeToAccount => '转入账户';

  /// Purpose: Return the localized string for `financeCurrency`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCurrency => '币种';

  /// Purpose: Return the localized string for `financeDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeDate => '日期';

  /// Purpose: Return the localized string for `financeNoTransactions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoTransactions => '暂无交易';

  /// Purpose: Return the localized string for `financeForceBalance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeForceBalance => '强制余额';

  /// Purpose: Return the localized string for `financeCurrentBalance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCurrentBalance => '当前余额';

  /// Purpose: Return the localized string for `financeAddAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAddAccount => '添加账户';

  /// Purpose: Return the localized string for `financeEditAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEditAccount => '编辑账户';

  /// Purpose: Return the localized string for `financeAddCategory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAddCategory => '添加分类';

  /// Purpose: Return the localized string for `financeEditCategory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEditCategory => '编辑分类';

  /// Purpose: Return the localized string for `financeName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeName => '名称';

  /// Purpose: Return the localized string for `financeBankApp`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBankApp => '银行 / 应用';

  /// Purpose: Return the localized string for `financeCardNumber`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCardNumber => '卡号（可选）';

  /// Purpose: Return the localized string for `financeExpiry`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeExpiry => '有效期';

  /// Purpose: Return the localized string for `financeSecurityCode`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSecurityCode => '安全码';

  /// Purpose: Return the localized string for `financeIcon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeIcon => '图标';

  /// Purpose: Return the localized string for `financeEmoji`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEmoji => '表情';

  /// Purpose: Return the localized string for `financeCategoryHintExpense`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCategoryHintExpense => '如 餐饮、交通';

  /// Purpose: Return the localized string for `financeCategoryHintIncome`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCategoryHintIncome => '如 薪资、投资';

  /// Purpose: Return the localized string for `financeThisTransaction`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeThisTransaction => '此流水';

  /// Purpose: Return the localized string for `financeNoAccounts`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoAccounts => '暂无账户';

  /// Purpose: Return the localized string for `financeNoCategories`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoCategories => '暂无分类';

  /// Purpose: Return the localized string for `financeByYear`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeByYear => '按年';

  /// Purpose: Return the localized string for `financeByMonth`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeByMonth => '按月';

  /// Purpose: Return the localized string for `financeByDay`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeByDay => '按日';

  /// Purpose: Return the localized string for `financeCustomRange`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCustomRange => '自定义范围';

  /// Purpose: Return the localized string for `financeExpenseTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeExpenseTrend => '支出趋势';

  /// Purpose: Return the localized string for `financeIncomeTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeIncomeTrend => '收入趋势';

  /// Purpose: Return the localized string for `financeAssetsTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAssetsTrend => '资产趋势';

  /// Purpose: Return the localized string for `financeThisCategory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeThisCategory => '此分类';

  /// Purpose: Implement the finance no categories of type behavior for this file.
  /// Inputs: `type`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeNoCategoriesOfType(String type) {
    return '暂无$type分类';
  }

  /// Purpose: Return the localized string for `financeImportDefaults`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeImportDefaults => '导入默认分类';

  /// Purpose: Return the localized string for `financeCatFood`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatFood => '餐饮';

  /// Purpose: Return the localized string for `financeCatTransport`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatTransport => '交通';

  /// Purpose: Return the localized string for `financeCatShopping`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatShopping => '购物';

  /// Purpose: Return the localized string for `financeCatRent`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatRent => '房租';

  /// Purpose: Return the localized string for `financeCatDigital`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatDigital => '数码';

  /// Purpose: Return the localized string for `financeCatEntertainment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatEntertainment => '娱乐';

  /// Purpose: Return the localized string for `financeCatHealthcare`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatHealthcare => '医疗';

  /// Purpose: Return the localized string for `financeCatEducation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatEducation => '教育';

  /// Purpose: Return the localized string for `financeCatSalary`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatSalary => '工资';

  /// Purpose: Return the localized string for `financeCatBonus`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatBonus => '奖金';

  /// Purpose: Return the localized string for `financeCatInvestment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatInvestment => '投资';

  /// Purpose: Return the localized string for `financeCatFreelance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatFreelance => '兼职';

  /// Purpose: Return the localized string for `intimacyTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTitle => '亲密记录';

  /// Purpose: Return the localized string for `intimacyNewRecord`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNewRecord => '新记录';

  /// Purpose: Return the localized string for `intimacyEditRecord`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyEditRecord => '编辑记录';

  /// Purpose: Return the localized string for `intimacySolo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySolo => '独自';

  /// Purpose: Return the localized string for `intimacyPartner`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPartner => '伴侣';

  /// Purpose: Return the localized string for `intimacyPartners`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPartners => '伴侣';

  /// Purpose: Return the localized string for `intimacyAddPartner`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyAddPartner => '添加伴侣';

  /// Purpose: Return the localized string for `intimacyEditPartner`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyEditPartner => '编辑伴侣';

  /// Purpose: Return the localized string for `intimacyToys`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyToys => '玩具';

  /// Purpose: Return the localized string for `intimacyAddToy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyAddToy => '添加玩具';

  /// Purpose: Return the localized string for `intimacyEditToy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyEditToy => '编辑玩具';

  /// Purpose: Return the localized string for `intimacyPleasure`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPleasure => '愉悦度';

  /// Purpose: Return the localized string for `intimacyDuration`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyDuration => '持续时间';

  /// Purpose: Return the localized string for `intimacyLocation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyLocation => '地点（可选）';

  /// Purpose: Return the localized string for `intimacyNotes`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNotes => '备注（可选）';

  /// Purpose: Return the localized string for `intimacyOrgasm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyOrgasm => '是否高潮？';

  /// Purpose: Return the localized string for `intimacyWatchedPorn`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyWatchedPorn => '是否观看色情片？';

  /// Purpose: Return the localized string for `intimacyTimer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimer => '计时器';

  /// Purpose: Return the localized string for `intimacyNoRecords`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNoRecords => '暂无记录';

  /// Purpose: Return the localized string for `intimacyNoPartners`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNoPartners => '暂无伴侣';

  /// Purpose: Return the localized string for `intimacyNoToys`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNoToys => '暂无玩具';

  /// Purpose: Return the localized string for `intimacyNoPartnersHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNoPartnersHint => '暂无伴侣——请在设置中添加';

  /// Purpose: Return the localized string for `intimacyShowAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyShowAll => '显示全部';

  /// Purpose: Return the localized string for `intimacyShowAllRecords`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyShowAllRecords => '查看全部记录';

  /// Purpose: Return the localized string for `intimacyAllRecords`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyAllRecords => '所有记录';

  /// Purpose: Return the localized string for `intimacyStart`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyStart => '开始';

  /// Purpose: Return the localized string for `intimacyPause`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPause => '暂停';

  /// Purpose: Return the localized string for `intimacyResume`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyResume => '继续';

  /// Purpose: Return the localized string for `intimacyStopSave`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyStopSave => '停止并保存';

  /// Purpose: Return the localized string for `intimacyReset`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyReset => '重置';

  /// Purpose: Return the localized string for `intimacyTimerStartedAt`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerStartedAt => '开始于';

  /// Purpose: Return the localized string for `intimacyTimerHistory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerHistory => '历史记录';

  /// Purpose: Return the localized string for `intimacyTimerClearHistory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerClearHistory => '清除';

  /// Purpose: Return the localized string for `intimacyTimerRetention3d`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerRetention3d => '3 天';

  /// Purpose: Return the localized string for `intimacyTimerRetention7d`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerRetention7d => '7 天';

  /// Purpose: Return the localized string for `intimacyTimerRetention14d`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerRetention14d => '14 天';

  /// Purpose: Return the localized string for `intimacyTimerRetentionForever`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerRetentionForever => '永久';

  /// Purpose: Return the localized string for `intimacyManage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyManage => '管理';

  /// Purpose: Return the localized string for `intimacyModuleVisible`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyModuleVisible => '已显示';

  /// Purpose: Return the localized string for `intimacyModuleHidden`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyModuleHidden => '已隐藏';

  /// Purpose: Return the localized string for `intimacySortNewest`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortNewest => '最新优先';

  /// Purpose: Return the localized string for `intimacySortOldest`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortOldest => '最早优先';

  /// Purpose: Return the localized string for `intimacySortPleasure`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortPleasure => '愉悦度最高';

  /// Purpose: Return the localized string for `intimacySortDuration`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortDuration => '时长最长';

  /// Purpose: Return the localized string for `intimacyFilterAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFilterAll => '全部';

  /// Purpose: Return the localized string for `intimacyFilterSolo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFilterSolo => '独自';

  /// Purpose: Return the localized string for `intimacyFilterPartnered`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFilterPartnered => '与伴侣';

  /// Purpose: Return the localized string for `intimacyFilterOrgasm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFilterOrgasm => '有高潮';

  /// Purpose: Return the localized string for `intimacyFilterNoOrgasm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFilterNoOrgasm => '无高潮';

  /// Purpose: Return the localized string for `intimacyExportCsv`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyExportCsv => '导出CSV';

  /// Purpose: Return the localized string for `intimacyExportCsvSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyExportCsvSuccess => 'CSV导出成功';

  /// Purpose: Return the localized string for `intimacyExportCsvEmpty`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyExportCsvEmpty => '没有记录可导出';

  /// Purpose: Return the localized string for `intimacyStartDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyStartDate => '交往开始';

  /// Purpose: Return the localized string for `intimacyEndDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyEndDate => '交往结束';

  /// Purpose: Return the localized string for `intimacyPurchaseDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPurchaseDate => '购买日期';

  /// Purpose: Return the localized string for `intimacyRetiredDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyRetiredDate => '退役日期';

  /// Purpose: Return the localized string for `intimacyBreakUp`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyBreakUp => '分手';

  /// Purpose: Return the localized string for `intimacyRetire`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyRetire => '退役';

  /// Purpose: Return the localized string for `settingsTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsTitle => '设置';

  /// Purpose: Return the localized string for `settingsGeneral`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsGeneral => '通用';

  /// Purpose: Return the localized string for `settingsLanguage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsLanguage => '语言';

  /// Purpose: Return the localized string for `settingsTheme`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsTheme => '主题';

  /// Purpose: Return the localized string for `settingsThemeSystem`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsThemeSystem => '跟随系统';

  /// Purpose: Return the localized string for `settingsThemeLight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsThemeLight => '浅色';

  /// Purpose: Return the localized string for `settingsThemeDark`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsThemeDark => '深色';

  /// Purpose: Return the localized string for `settingsPrivacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsPrivacy => '隐私';

  /// Purpose: Return the localized string for `settingsIntimacyModule`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsIntimacyModule => '亲密模块';

  /// Purpose: Return the localized string for `settingsData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsData => '数据';

  /// Purpose: Return the localized string for `settingsStorageLocation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsStorageLocation => '存储位置';

  /// Purpose: Return the localized string for `settingsStoragePathHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsStoragePathHint => '输入数据存储目录路径。留空使用默认路径。';

  /// Purpose: Return the localized string for `settingsDirectoryPath`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsDirectoryPath => '目录路径';

  /// Purpose: Return the localized string for `settingsResetDefault`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsResetDefault => '恢复默认';

  /// Purpose: Return the localized string for `settingsResetDefaultLocation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsResetDefaultLocation => '已恢复默认存储位置';

  /// Purpose: Return the localized string for `settingsStoragePathUpdated`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsStoragePathUpdated => '存储路径已更新';

  /// Purpose: Return the localized string for `settingsOpenDataFolder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsOpenDataFolder => '打开数据目录';

  /// Purpose: Return the localized string for `settingsOpenDataFolderDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsOpenDataFolderDesc => '打开应用数据文件夹';

  /// Purpose: Return the localized string for `settingsWebDAVSync`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVSync => 'WebDAV 同步';

  /// Purpose: Return the localized string for `settingsWebDAVNotConfigured`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVNotConfigured => '未配置';

  /// Purpose: Return the localized string for `settingsWebDAVConfigured`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConfigured => '已配置';

  /// Purpose: Return the localized string for `settingsWebDAVServerURL`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVServerURL => '服务器地址';

  /// Purpose: Return the localized string for `settingsWebDAVUsername`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVUsername => '用户名';

  /// Purpose: Return the localized string for `settingsWebDAVPassword`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVPassword => '密码';

  /// Purpose: Return the localized string for `settingsWebDAVRemotePath`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVRemotePath => '远程路径';

  /// Purpose: Return the localized string for `settingsWebDAVTestConnection`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVTestConnection => '测试连接';

  /// Purpose: Return the localized string for `settingsWebDAVConnectionSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConnectionSuccess => '连接成功';

  /// Purpose: Return the localized string for `settingsWebDAVConnectionFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConnectionFailed => '连接失败';

  /// Purpose: Return the localized string for `settingsWebDAVSyncNow`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVSyncNow => '立即同步';

  /// Purpose: Return the localized string for `settingsWebDAVAutoSync`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVAutoSync => '自动同步';

  /// Purpose: Return the localized string for `settingsWebDAVAutoSyncDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVAutoSyncDesc => '编辑后和应用恢复时自动同步';

  /// Purpose: Return the localized string for `settingsWebDAVSyncing`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVSyncing => '同步中...';

  /// Purpose: Return the localized string for `settingsWebDAVSyncSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVSyncSuccess => '同步完成';

  /// Purpose: Return the localized string for `settingsWebDAVSyncFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVSyncFailed => '同步失败';

  /// Purpose: Return the localized string for `settingsWebDAVConflictTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConflictTitle => '同步冲突';

  /// Purpose: Return the localized string for `settingsWebDAVConflictDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConflictDesc => '以下记录在本地和远端都有修改，请为每条记录选择要保留的版本：';

  /// Purpose: Return the localized string for `settingsWebDAVKeepLocal`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVKeepLocal => '保留本地';

  /// Purpose: Return the localized string for `settingsWebDAVKeepRemote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVKeepRemote => '保留远端';

  /// Purpose: Return the localized string for `settingsWebDAVConflictApply`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConflictApply => '应用';

  /// Purpose: Return the localized string for `settingsWebDAVNextcloud`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVNextcloud => 'Nextcloud 预设';

  /// Purpose: Return the localized string for `settingsWebDAVCustom`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVCustom => '自定义服务器';

  /// Purpose: Return the localized string for `settingsImportExport`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportExport => '导入/导出';

  /// Purpose: Return the localized string for `settingsExportJSON`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportJSON => '导出 ZIP';

  /// Purpose: Return the localized string for `settingsExportCSV`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportCSV => '导出 CSV';

  /// Purpose: Return the localized string for `csvExportFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportFinance => '导出财务 CSV';

  /// Purpose: Return the localized string for `csvExportFinanceDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportFinanceDesc => '财务交易为纯文本';

  /// Purpose: Return the localized string for `csvExportIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportIntimacy => '导出亲密 CSV';

  /// Purpose: Return the localized string for `csvExportIntimacyDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportIntimacyDesc => '亲密记录为纯文本';

  /// Purpose: Return the localized string for `csvExportWeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportWeight => '导出体重 CSV';

  /// Purpose: Return the localized string for `csvExportWeightDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportWeightDesc => '体重记录为纯文本';

  /// Purpose: Return the localized string for `settingsImport`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImport => '从文件导入';

  /// Purpose: Return the localized string for `settingsExportSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportSuccess => '导出成功';

  /// Purpose: Return the localized string for `settingsExportFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportFailed => '导出失败';

  /// Purpose: Return the localized string for `settingsImportSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportSuccess => '导入成功';

  /// Purpose: Return the localized string for `settingsImportFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportFailed => '导入失败';

  /// Purpose: Return the localized string for `settingsImportConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportConfirm => '此操作将替换所有当前数据。是否继续？';

  /// Purpose: Return the localized string for `settingsExportCSVWarning`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportCSVWarning => 'CSV 数据将以明文导出。是否继续？';

  /// Purpose: Return the localized string for `settingsAbout`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsAbout => '关于';

  /// Purpose: Return the localized string for `settingsAboutTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsAboutTitle => '关于 MyDay!!!!!';

  /// Purpose: Return the localized string for `commonSave`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonSave => '保存';

  /// Purpose: Return the localized string for `commonDiscard`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonDiscard => '舍弃';

  /// Purpose: Return the localized string for `commonDiscardChangesTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonDiscardChangesTitle => '舍弃修改？';

  /// Purpose: Return the localized string for `commonDiscardChangesMessage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonDiscardChangesMessage => '当前更改尚未保存，确定要舍弃并关闭吗？';

  /// Purpose: Return the localized string for `commonCancel`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonCancel => '取消';

  /// Purpose: Return the localized string for `commonDelete`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonDelete => '删除';

  /// Purpose: Return the localized string for `commonEdit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonEdit => '编辑';

  /// Purpose: Return the localized string for `commonAdd`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonAdd => '添加';

  /// Purpose: Return the localized string for `commonConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonConfirm => '确认';

  /// Purpose: Return the localized string for `commonYes`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonYes => '是';

  /// Purpose: Return the localized string for `commonNo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonNo => '否';

  /// Purpose: Return the localized string for `commonOk`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonOk => '好';

  /// Purpose: Return the localized string for `commonClose`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonClose => '关闭';

  /// Purpose: Return the localized string for `commonName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonName => '名称';

  /// Purpose: Return the localized string for `commonEmojiOptional`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonEmojiOptional => '图标（可选）';

  /// Purpose: Return the localized string for `commonOptional`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonOptional => '可选';

  /// Purpose: Implement the common delete confirm behavior for this file.
  /// Inputs: `item`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String commonDeleteConfirm(String item) {
    return '删除$item？';
  }

  /// Purpose: Implement the common minutes behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String commonMinutes(int count) {
    return '$count分钟';
  }

  /// Purpose: Return the localized string for `settingsExportSection`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportSection => '导出';

  /// Purpose: Return the localized string for `settingsImportSection`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportSection => '导入';

  /// Purpose: Return the localized string for `settingsExportFullBackup`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportFullBackup => '所有数据的完整备份';

  /// Purpose: Return the localized string for `settingsExportJSONPlaintext`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportJSONPlaintext => '所有数据将以 ZIP 压缩包导出';

  /// Purpose: Return the localized string for `settingsExportCSVPlaintext`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportCSVPlaintext => '财务交易为纯文本';

  /// Purpose: Return the localized string for `settingsImportRestore`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportRestore => '从ZIP备份恢复';

  /// Purpose: Return the localized string for `settingsImportData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportData => '导入数据';

  /// Purpose: Return the localized string for `csvImportFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportFinance => '导入财务 CSV';

  /// Purpose: Return the localized string for `csvImportFinanceDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportFinanceDesc => '从 CSV 合并交易记录（不会覆盖现有数据）';

  /// Purpose: Return the localized string for `csvImportIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportIntimacy => '导入亲密 CSV';

  /// Purpose: Return the localized string for `csvImportIntimacyDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportIntimacyDesc => '从 CSV 合并记录（不会覆盖现有数据）';

  /// Purpose: Return the localized string for `csvImportConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportConfirm => 'CSV 数据将合并到现有记录中，是否继续？';

  /// Purpose: Implement the csv import success behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String csvImportSuccess(int count) {
    return '成功导入 $count 条记录';
  }

  /// Purpose: Return the localized string for `csvImportFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportFailed => 'CSV 导入失败';

  /// Purpose: Return the localized string for `csvImportEmpty`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportEmpty => 'CSV 中未找到有效记录';

  /// Purpose: Return the localized string for `csvTemplate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvTemplate => 'CSV 模板';

  /// Purpose: Return the localized string for `csvTemplateFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvTemplateFinance => '下载财务模板';

  /// Purpose: Return the localized string for `csvTemplateIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvTemplateIntimacy => '下载亲密模板';

  /// Purpose: Return the localized string for `csvTemplateSaved`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvTemplateSaved => '模板已保存';

  /// Purpose: Return the localized string for `settingsWebDAVDisconnect`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVDisconnect => '断开连接';

  /// Purpose: Return the localized string for `settingsWebDAVConfigSaved`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConfigSaved => '配置已保存';

  /// Purpose: Return the localized string for `settingsWebDAVConfigRemoved`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConfigRemoved => '配置已移除';

  /// Purpose: Return the localized string for `commonDontAskMinutes`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonDontAskMinutes => '5分钟内不再询问';

  /// Purpose: Return the localized string for `intimacyHideConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyHideConfirm => '关闭亲密模块不会删除数据，随时可以重新开启。';

  /// Purpose: Return the localized string for `settingsLicense`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsLicense => '许可证 (GPLv3)';

  /// Purpose: Return the localized string for `settingsLicenses`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsLicenses => '开源许可证';

  /// Purpose: Return the localized string for `settingsPrivacyPolicy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsPrivacyPolicy => '隐私政策';

  /// Purpose: Return the localized string for `settingsDesktop`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsDesktop => '桌面';

  /// Purpose: Return the localized string for `settingsMinimizeToTray`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsMinimizeToTray => '最小化到托盘';

  /// Purpose: Return the localized string for `settingsCloseToTray`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsCloseToTray => '关闭到托盘';

  /// Purpose: Return the localized string for `financeBankPresets`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBankPresets => '银行预设';

  /// Purpose: Return the localized string for `financeBankSearch`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBankSearch => '搜索银行或应用...';

  /// Purpose: Return the localized string for `financeBankNoResults`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBankNoResults => '未找到匹配的银行';

  /// Purpose: Return the localized string for `financeSubscriptions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSubscriptions => '订阅';

  /// Purpose: Return the localized string for `financeSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSubscription => '订阅';

  /// Purpose: Return the localized string for `financeAddSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAddSubscription => '添加订阅';

  /// Purpose: Return the localized string for `financeEditSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEditSubscription => '编辑订阅';

  /// Purpose: Return the localized string for `financeStartDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeStartDate => '开始日期';

  /// Purpose: Return the localized string for `financeTrialDays`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTrialDays => '试用天数';

  /// Purpose: Return the localized string for `financeBillingCycle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBillingCycle => '付费周期';

  /// Purpose: Return the localized string for `financeBillingCycleMonthly`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBillingCycleMonthly => '按月';

  /// Purpose: Return the localized string for `financeBillingCycleYearly`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBillingCycleYearly => '按年';

  /// Purpose: Implement the finance every x months behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeEveryXMonths(int count) {
    return '每 $count 个月';
  }

  /// Purpose: Implement the finance every x years behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeEveryXYears(int count) {
    return '每 $count 年';
  }

  /// Purpose: Return the localized string for `financeBillingDay`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBillingDay => '扣费日';

  /// Purpose: Return the localized string for `financeBillingMonth`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBillingMonth => '扣费月份';

  /// Purpose: Return the localized string for `financeMonthlyDue`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeMonthlyDue => '月应付';

  /// Purpose: Return the localized string for `financeMonthlyAvg`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeMonthlyAvg => '月均花费';

  /// Purpose: Return the localized string for `financeYearlyAvg`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeYearlyAvg => '年均花费';

  /// Purpose: Return the localized string for `financeNoSubscriptions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoSubscriptions => '暂无订阅';

  /// Purpose: Return the localized string for `financeActiveSubscriptions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeActiveSubscriptions => '进行中';

  /// Purpose: Return the localized string for `financeHistoricalSubscriptions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeHistoricalSubscriptions => '历史';

  /// Purpose: Return the localized string for `financeCancelSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCancelSubscription => '取消订阅';

  /// Purpose: Return the localized string for `financeCancelImmediate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCancelImmediate => '立即取消';

  /// Purpose: Return the localized string for `financeCancelAtExpiry`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCancelAtExpiry => '到期取消';

  /// Purpose: Return the localized string for `financeNextBilling`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNextBilling => '下次扣费';

  /// Purpose: Return the localized string for `financeExpiryDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeExpiryDate => '到期日期';

  /// Purpose: Return the localized string for `financeTotalSpent`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTotalSpent => '累计花费';

  /// Purpose: Return the localized string for `financeImportHistory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeImportHistory => '导入历史交易';

  /// Purpose: Return the localized string for `financeImportHistoryDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeImportHistoryDesc => '开始日期在今天之前，是否导入历史交易？';

  /// Purpose: Return the localized string for `financeThisSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeThisSubscription => '此订阅';

  /// Purpose: Implement the finance cancelled on behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeCancelledOn(String date) {
    return '已于 $date 取消';
  }

  /// Purpose: Return the localized string for `financeInterval`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeInterval => '间隔';

  /// Purpose: Return the localized string for `financeImage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeImage => '图片';

  /// Purpose: Return the localized string for `financePickImage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financePickImage => '选择图片';

  /// Purpose: Return the localized string for `financeChangeImage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeChangeImage => '更换';

  /// Purpose: Return the localized string for `financeUpcomingRenewals`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeUpcomingRenewals => '即将续费';

  /// Purpose: Return the localized string for `financeSubscriptionReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSubscriptionReminder => '订阅提醒';

  /// Purpose: Return the localized string for `financeReminderTime`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeReminderTime => '通知时间';

  /// Purpose: Return the localized string for `financeReminderEnabled`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeReminderEnabled => '提醒即将续费的服务';

  /// Purpose: Implement the finance subscription due soon behavior for this file.
  /// Inputs: `name`, `days`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeSubscriptionDueSoon(String name, int days) {
    return '$name 将在 $days 天后续费';
  }

  /// Purpose: Implement the finance subscription due today behavior for this file.
  /// Inputs: `name`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeSubscriptionDueToday(String name) {
    return '$name 今天续费';
  }

  /// Purpose: Return the localized string for `financeSortBy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortBy => '排序';

  /// Purpose: Return the localized string for `financeSortByRenewal`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortByRenewal => '按续费日期';

  /// Purpose: Return the localized string for `financeSortByName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortByName => '按名称';

  /// Purpose: Return the localized string for `financeSortByBank`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortByBank => '按银行 / 应用';

  /// Purpose: Return the localized string for `financeSortCustom`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortCustom => '自定义';

  /// Purpose: Return the localized string for `financeSortReorder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortReorder => '调整顺序';

  /// Purpose: Return the localized string for `financeSortDone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortDone => '完成';

  /// Purpose: Return the localized string for `financeRestoreSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeRestoreSubscription => '恢复订阅';

  /// Purpose: Return the localized string for `backupTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupTitle => '备份';

  /// Purpose: Return the localized string for `backupLocalOnlyNote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupLocalOnlyNote => '备份仅保存在本机，如需云端同步请使用 WebDAV 同步。';

  /// Purpose: Return the localized string for `backupSettings`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupSettings => '设置';

  /// Purpose: Return the localized string for `backupAutoDaily`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupAutoDaily => '每日自动备份';

  /// Purpose: Return the localized string for `backupAutoDailyDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupAutoDailyDesc => '每天自动创建一次备份';

  /// Purpose: Return the localized string for `backupRetention`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRetention => '保留备份';

  /// Purpose: Return the localized string for `backupRetentionForever`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRetentionForever => '永久保存';

  /// Purpose: Implement the backup retention days behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String backupRetentionDays(int count) {
    return '$count 天';
  }

  /// Purpose: Return the localized string for `backupManual`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupManual => '手动备份';

  /// Purpose: Return the localized string for `backupCreateNow`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupCreateNow => '立即创建备份';

  /// Purpose: Implement the backup history behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String backupHistory(int count) {
    return '备份历史 ($count)';
  }

  /// Purpose: Return the localized string for `backupEmpty`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupEmpty => '暂无备份';

  /// Purpose: Return the localized string for `backupCreated`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupCreated => '备份创建成功';

  /// Purpose: Return the localized string for `backupFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupFailed => '备份失败';

  /// Purpose: Return the localized string for `backupRestore`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestore => '还原';

  /// Purpose: Return the localized string for `backupRestoreConfirmTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreConfirmTitle => '确认还原';

  /// Purpose: Return the localized string for `backupRestoreConfirmDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreConfirmDesc => '这将替换所选模块的数据，是否继续？';

  /// Purpose: Return the localized string for `backupRestoreSelectModules`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreSelectModules => '选择要还原的模块';

  /// Purpose: Return the localized string for `backupRestoreAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreAll => '全部模块';

  /// Purpose: Return the localized string for `backupRestoreSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreSuccess => '还原成功，请重启应用。';

  /// Purpose: Return the localized string for `backupRestoreFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreFailed => '还原失败';

  /// Purpose: Return the localized string for `backupDeleteConfirmTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupDeleteConfirmTitle => '删除备份';

  /// Purpose: Return the localized string for `backupDeleteConfirmDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupDeleteConfirmDesc => '该备份将被永久删除。';

  /// Purpose: Return the localized string for `backupModuleTodo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupModuleTodo => '待办事项';

  /// Purpose: Return the localized string for `backupModuleFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupModuleFinance => '财务';

  /// Purpose: Return the localized string for `backupModuleRates`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupModuleRates => '汇率';

  /// Purpose: Return the localized string for `backupModuleIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupModuleIntimacy => '亲密';

  /// Purpose: Implement the intimacy record count behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String intimacyRecordCount(int count) {
    return '$count 条记录';
  }

  /// Purpose: Return the localized string for `weightTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightTitle => '体重';

  /// Purpose: Return the localized string for `weightSetHeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightSetHeight => '设置身高';

  /// Purpose: Return the localized string for `weightNoRecords`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightNoRecords => '暂无体重记录';

  /// Purpose: Return the localized string for `weightAddRecord`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightAddRecord => '添加记录';

  /// Purpose: Return the localized string for `weightKg`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightKg => '体重（kg）';

  /// Purpose: Return the localized string for `weightHeightCm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightHeightCm => '身高（cm）';

  /// Purpose: Return the localized string for `weightNote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightNote => '备注';

  /// Purpose: Return the localized string for `weightNoteHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightNoteHint => '可选备注';

  /// Purpose: Return the localized string for `weightChart`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightChart => '趋势';

  /// Purpose: Return the localized string for `weightAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightAll => '全部';

  /// Purpose: Return the localized string for `weightHistory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightHistory => '历史';

  /// Purpose: Return the localized string for `weightShowAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightShowAll => '查看全部记录';

  /// Purpose: Return the localized string for `weightDays`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightDays => '天';

  /// Purpose: Return the localized string for `weightDaysAgo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightDaysAgo => '天前';

  /// Purpose: Return the localized string for `weightWeeksAgo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightWeeksAgo => '周前';

  /// Purpose: Return the localized string for `weightToday`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightToday => '今天';

  /// Purpose: Return the localized string for `weightYesterday`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightYesterday => '昨天';

  /// Purpose: Return the localized string for `weightRecent`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightRecent => '近期';

  /// Purpose: Return the localized string for `weightExportCsv`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightExportCsv => '导出CSV';

  /// Purpose: Return the localized string for `weightExportCsvSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightExportCsvSuccess => '体重数据导出成功';

  /// Purpose: Return the localized string for `weightExportCsvEmpty`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightExportCsvEmpty => '没有体重记录可导出';

  /// Purpose: Return the localized string for `csvImportWeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportWeight => '导入体重 CSV';

  /// Purpose: Return the localized string for `csvImportWeightDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportWeightDesc => '从 CSV 合并体重记录（日期、时间、体重）';

  /// Purpose: Return the localized string for `csvTemplateWeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvTemplateWeight => '下载体重模板';

  /// Purpose: Return the localized string for `financeSubscriptionPresets`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSubscriptionPresets => '快速填入';

  /// Purpose: Return the localized string for `intimacyPurchaseLink`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPurchaseLink => '购买链接';

  /// Purpose: Return the localized string for `intimacyPrice`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPrice => '价格';

  /// Purpose: Return the localized string for `intimacyPositions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPositions => '体位';

  /// Purpose: Return the localized string for `intimacyAddPosition`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyAddPosition => '添加体位';

  /// Purpose: Return the localized string for `intimacyEditPosition`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyEditPosition => '编辑体位';

  /// Purpose: Return the localized string for `intimacyNoPositions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNoPositions => '暂无体位';

  /// Purpose: Return the localized string for `intimacyImportDefaults`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyImportDefaults => '导入默认';

  /// Purpose: Return the localized string for `intimacyTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTrend => '趋势';

  /// Purpose: Return the localized string for `intimacyFrequency`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFrequency => '频率';

  /// Purpose: Return the localized string for `intimacyChartNoData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyChartNoData => '数据不足';

  /// Purpose: Return the localized string for `weightTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightTrend => '趋势';

  /// Purpose: Return the localized string for `weightRaw`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightRaw => '实际';

  /// Purpose: Return the localized string for `weightReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminder => '体重提醒';

  /// Purpose: Return the localized string for `weightReminderNone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderNone => '不提醒';

  /// Purpose: Return the localized string for `weightReminderOnce`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderOnce => '每天一次';

  /// Purpose: Return the localized string for `weightReminderTwice`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderTwice => '每天两次（早晚）';

  /// Purpose: Return the localized string for `weightReminderMorning`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderMorning => '早晨';

  /// Purpose: Return the localized string for `weightReminderEvening`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderEvening => '晚间';

  /// Purpose: Return the localized string for `weightReminderSkipWindow`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderSkipWindow => '已有记录则跳过';

  /// Purpose: Implement the weight reminder skip window value behavior for this file.
  /// Inputs: `hours`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String weightReminderSkipWindowValue(String hours) {
    return '提醒前 $hours 小时内';
  }

  /// Purpose: Return the localized string for `weightReminderSkipWindowHours`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderSkipWindowHours => '提醒前小时数';

  /// Purpose: Return the localized string for `commonChange`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonChange => '更换';

  /// Purpose: Return the localized string for `commonPickImage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonPickImage => '选择图片';

  /// Purpose: Return the localized string for `commonRemoveIcon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonRemoveIcon => '移除图标';

  /// Purpose: Return the localized string for `commonPickIcon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonPickIcon => '选择图标';

  /// Purpose: Return the localized string for `commonNoData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonNoData => '暂无数据';

  /// Purpose: Implement the common week group behavior for this file.
  /// Inputs: `year`, `week`, `range`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String commonWeekGroup(int year, int week, String range) {
    return '$year 第$week周（$range）';
  }

  /// Purpose: Return the localized string for `todoDailyReminders`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoDailyReminders => '每日提醒';

  /// Purpose: Return the localized string for `todoRemindReviewHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoRemindReviewHint => '提醒查看今天的待办事项';

  /// Purpose: Return the localized string for `todoRemindUndoneHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoRemindUndoneHint => '提醒未完成的任务';

  /// Purpose: Return the localized string for `todoTapReturnToday`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoTapReturnToday => '点击返回今天';

  /// Purpose: Return the localized string for `todoCalendar`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCalendar => '日历';

  /// Purpose: Return the localized string for `todoWeekMon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekMon => '周一';

  /// Purpose: Return the localized string for `todoWeekTue`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekTue => '周二';

  /// Purpose: Return the localized string for `todoWeekWed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekWed => '周三';

  /// Purpose: Return the localized string for `todoWeekThu`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekThu => '周四';

  /// Purpose: Return the localized string for `todoWeekFri`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekFri => '周五';

  /// Purpose: Return the localized string for `todoWeekSat`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekSat => '周六';

  /// Purpose: Return the localized string for `todoWeekSun`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekSun => '周日';

  /// Purpose: Return the localized string for `todoCalendarSomeDaily`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCalendarSomeDaily => '部分完成';

  /// Purpose: Return the localized string for `todoCalendarAllDaily`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCalendarAllDaily => '日常全完成';

  /// Purpose: Return the localized string for `todoCalendarAllDone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCalendarAllDone => '全部完成';

  /// Purpose: Return the localized string for `todoWhatNeedsDone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWhatNeedsDone => '需要做什么？';

  /// Purpose: Implement the todo reminder at behavior for this file.
  /// Inputs: `time`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoReminderAt(String time) {
    return '提醒：$time';
  }

  /// Purpose: Return the localized string for `todoAddReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoAddReminder => '添加提醒（可选）';

  /// Purpose: Implement the todo scheduled at behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoScheduledAt(String date) {
    return '计划：$date';
  }

  /// Purpose: Return the localized string for `todoSetScheduledDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSetScheduledDate => '设定计划日期';

  /// Purpose: Implement the todo completed at behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoCompletedAt(String date) {
    return '完成：$date';
  }

  /// Purpose: Return the localized string for `todoSetCompletedDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSetCompletedDate => '设定完成日期';

  /// Purpose: Return the localized string for `todoSortBy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSortBy => '排序';

  /// Purpose: Return the localized string for `todoSortByAdded`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSortByAdded => '按添加时间';

  /// Purpose: Return the localized string for `todoSortByDueDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSortByDueDate => '按截止日期';

  /// Purpose: Return the localized string for `todoSortByName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSortByName => '按名称';

  /// Purpose: Return the localized string for `todoSortCustom`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSortCustom => '自定义';

  /// Purpose: Return the localized string for `weightUnitKg`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightUnitKg => 'kg';

  /// Purpose: Implement the weight value kg behavior for this file.
  /// Inputs: `value`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String weightValueKg(String value) {
    return '$value kg';
  }

  /// Purpose: Return the localized string for `positionMissionary`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionMissionary => '传教士式';

  /// Purpose: Return the localized string for `positionCowgirl`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionCowgirl => '骑乘式';

  /// Purpose: Return the localized string for `positionDoggyStyle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionDoggyStyle => '后入式';

  /// Purpose: Return the localized string for `positionReverseCowgirl`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionReverseCowgirl => '反骑乘式';

  /// Purpose: Return the localized string for `positionSpooning`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionSpooning => '侧入式';

  /// Purpose: Return the localized string for `positionStanding`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionStanding => '站立式';

  /// Purpose: Return the localized string for `position69`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get position69 => '69式';

  /// Purpose: Return the localized string for `positionLotus`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionLotus => '莲花式';

  /// Purpose: Return the localized string for `positionProneBone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionProneBone => '趴伏式';

  /// Purpose: Return the localized string for `notifTodoMorning`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get notifTodoMorning => '早上好！是时候查看和更新您的待办事项了 📝';

  /// Purpose: Return the localized string for `notifTodoCompletion`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get notifTodoCompletion => '别忘了完成今天剩余的任务！';

  /// Purpose: Implement the notif todo uncompleted behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String notifTodoUncompleted(int count) {
    return '今天还有 $count 项任务未完成！';
  }

  /// Purpose: Return the localized string for `notifWeightReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get notifWeightReminder => '该记录体重了！⚖️';

  /// Purpose: Implement the notif upcoming renewals behavior for this file.
  /// Inputs: `list`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String notifUpcomingRenewals(String list) {
    return '即将续费：$list';
  }

  /// Purpose: Implement the notif subscription today behavior for this file.
  /// Inputs: `name`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String notifSubscriptionToday(String name) {
    return '$name（今天）';
  }

  /// Purpose: Implement the notif subscription days behavior for this file.
  /// Inputs: `name`, `days`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String notifSubscriptionDays(String name, int days) {
    return '$name（$days天后）';
  }

  /// Purpose: Return the localized string for `trayShow`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get trayShow => '显示';

  /// Purpose: Return the localized string for `trayQuit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get trayQuit => '退出';

  /// Purpose: Return the localized string for `filePickerExportLocation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get filePickerExportLocation => '选择导出位置';

  /// Purpose: Return the localized string for `filePickerBackupFile`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get filePickerBackupFile => '选择备份文件';

  /// Purpose: Return the localized string for `filePickerCsvFile`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get filePickerCsvFile => '选择 CSV 文件';

  /// Purpose: Return the localized string for `filePickerSaveTemplate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get filePickerSaveTemplate => '保存模板到';

  /// Purpose: Return the localized string for `financeBalance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBalance => '余额';

  /// Purpose: Return the localized string for `financeNewAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNewAccount => '新建账户';

  /// Purpose: Return the localized string for `financeAccountTypeFund`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountTypeFund => '储蓄';

  /// Purpose: Return the localized string for `financeAccountTypeCredit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountTypeCredit => '信用';

  /// Purpose: Return the localized string for `financeAccountTypeRecharge`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountTypeRecharge => '充值';

  /// Purpose: Return the localized string for `financeAccountTypeFinancial`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountTypeFinancial => '理财';

  /// Purpose: Return the localized string for `financeAccountName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountName => '账户名称';

  /// Purpose: Return the localized string for `financeBankAppHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBankAppHint => '例如工行、支付宝';

  /// Purpose: Return the localized string for `financeCardNumberHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCardNumberHint => '后四位';

  /// Purpose: Return the localized string for `financeFeeWaiverConditions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverConditions => '免月管理费条件';

  /// Purpose: Return the localized string for `financeFeeWaiverConditionsHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverConditionsHint => '可选记录银行免收月管理费的条件。';

  /// Purpose: Return the localized string for `financeFeeWaiverMinimumBalance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverMinimumBalance => '最低余额';

  /// Purpose: Return the localized string for `financeFeeWaiverMinimumBalanceHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverMinimumBalanceHint => '例如 1500';

  /// Purpose: Return the localized string for `financeFeeWaiverMonthlyDeposit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverMonthlyDeposit => '每月转入额';

  /// Purpose: Return the localized string for `financeFeeWaiverMonthlyDepositHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverMonthlyDepositHint => '例如 500';

  /// Purpose: Return the localized string for `financeFeeWaiverSeparator`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverSeparator => ' 或 ';

  /// Purpose: Return the localized string for `financeCurrentBalanceHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCurrentBalanceHint => '留空则根据交易计算';

  /// Purpose: Return the localized string for `financeAsOfToday`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAsOfToday => '截止今天';

  /// Purpose: Return the localized string for `financeBalanceEffectiveDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBalanceEffectiveDate => '余额生效日期';

  /// Purpose: Return the localized string for `financeFetchIcon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFetchIcon => '获取图标';

  /// Purpose: Return the localized string for `financeAccountsCategories`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountsCategories => '账户与分类';

  /// Purpose: Return the localized string for `financeEditRate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEditRate => '编辑汇率';

  /// Purpose: Return the localized string for `financeNewRate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNewRate => '新建汇率';

  /// Purpose: Return the localized string for `financeFrom`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFrom => '从';

  /// Purpose: Return the localized string for `financeTo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTo => '到';

  /// Purpose: Return the localized string for `financeRate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeRate => '汇率';

  /// Purpose: Implement the finance rate hint behavior for this file.
  /// Inputs: `from`, `to`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeRateHint(String from, String to) {
    return '1 $from = ? $to';
  }

  /// Purpose: Return the localized string for `financeNoRates`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoRates => '未配置汇率';

  /// Purpose: Return the localized string for `financeNoExpenseData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoExpenseData => '该时段无支出数据';

  /// Purpose: Return the localized string for `financeUncategorized`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeUncategorized => '未分类';

  /// Purpose: Return the localized string for `financeTotal`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTotal => '合计';

  /// Purpose: Return the localized string for `financeSelectDateRange`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSelectDateRange => '选择日期范围';

  /// Purpose: Return the localized string for `financeNoTransactionData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoTransactionData => '该时段无交易数据';

  /// Purpose: Implement the finance received amount behavior for this file.
  /// Inputs: `currency`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeReceivedAmount(String currency) {
    return '到账金额 ($currency)';
  }

  /// Purpose: Return the localized string for `financeReceivedAmountHelper`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeReceivedAmountHelper => '目标账户币种的到账金额';

  /// Purpose: Return the localized string for `financeNoteHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoteHint => '这笔钱用于？';

  /// Purpose: Return the localized string for `financeThisAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeThisAccount => '此账户';

  /// Purpose: Return the localized string for `commonThisRecord`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonThisRecord => '此记录';

  /// Purpose: Return the localized string for `financeBalanceAdjustment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBalanceAdjustment => '余额调整';

  /// Purpose: Return the localized string for `financeCatCreditCardPayment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatCreditCardPayment => '还信用卡';

  /// Purpose: Return the localized string for `financeCatFixedDeposit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatFixedDeposit => '定存到期';

  /// Purpose: Return the localized string for `financeCatInternalTransfer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatInternalTransfer => '内部转账';

  /// Purpose: Return the localized string for `financeCatLoanRepayment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatLoanRepayment => '还贷';

  /// Purpose: Return the localized string for `financeCatInvestmentTransfer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatInvestmentTransfer => '投资转入';

  /// Purpose: Return the localized string for `financeCatReimburse`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatReimburse => '报销';

  /// Purpose: Return the localized string for `settingsAutoStart`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsAutoStart => '开机自启动';

  /// Purpose: Return the localized string for `settingsApiEnabled`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiEnabled => '本地 API 服务器';

  /// Purpose: Return the localized string for `settingsApiServer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiServer => 'API 服务器设置';

  /// Purpose: Implement the settings api running behavior for this file.
  /// Inputs: `port`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String settingsApiRunning(int port) {
    return '运行中，端口 $port';
  }

  /// Purpose: Return the localized string for `settingsApiStopped`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiStopped => '已停止';

  /// Purpose: Return the localized string for `settingsApiNeedCredentials`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiNeedCredentials => '非本地访问需设置凭据';

  /// Purpose: Implement the settings api restarted behavior for this file.
  /// Inputs: `port`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String settingsApiRestarted(int port) {
    return 'API 服务器已重启，端口 $port';
  }

  /// Purpose: Return the localized string for `settingsApiListenAddress`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiListenAddress => '监听地址';

  /// Purpose: Return the localized string for `settingsApiPort`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiPort => '端口';

  /// Purpose: Return the localized string for `settingsApiUsername`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiUsername => '用户名';

  /// Purpose: Return the localized string for `settingsApiPassword`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiPassword => '密码';

  /// Purpose: Return the localized string for `todoRecurrence`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoRecurrence => '重复';

  /// Purpose: Return the localized string for `todoRecurrenceNone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoRecurrenceNone => '无';

  /// Purpose: Implement the todo recurrence every n days behavior for this file.
  /// Inputs: `n`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoRecurrenceEveryNDays(int n) {
    return '每隔 $n 天';
  }

  /// Purpose: Implement the todo recurrence monthly on day behavior for this file.
  /// Inputs: `n`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoRecurrenceMonthlyOnDay(int n) {
    return '每月 $n 日';
  }

  /// Purpose: Implement the todo recurrence yearly on date behavior for this file.
  /// Inputs: `month`, `day`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoRecurrenceYearlyOnDate(int month, int day) {
    return '每年 $month/$day';
  }

  /// Purpose: Return the localized string for `todoNextOccurrence`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoNextOccurrence => '安排下次任务';

  /// Purpose: Return the localized string for `intimacyActivePartners`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyActivePartners => '现役伴侣';

  /// Purpose: Return the localized string for `intimacyPastPartners`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPastPartners => '已分手伴侣';

  /// Purpose: Return the localized string for `intimacyActiveToys`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyActiveToys => '现役玩具';

  /// Purpose: Return the localized string for `intimacyRetiredToys`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyRetiredToys => '退役玩具';

  /// Purpose: Return the localized string for `intimacySortByRelationshipDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortByRelationshipDate => '按交往时间';

  /// Purpose: Return the localized string for `intimacySortByPurchaseDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortByPurchaseDate => '按购买时间';

  /// Purpose: Return the localized string for `intimacySortByUseCount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortByUseCount => '按使用次数';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  /// Purpose: Return the localized string for `appTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get appTitle => 'MyDay!!!!!';

  /// Purpose: Return the localized string for `navTodo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get navTodo => '待辦';

  /// Purpose: Return the localized string for `navFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get navFinance => '財務';

  /// Purpose: Return the localized string for `navWeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get navWeight => '體重';

  /// Purpose: Return the localized string for `navIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get navIntimacy => '親密';

  /// Purpose: Return the localized string for `navSettings`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get navSettings => '設定';

  /// Purpose: Return the localized string for `todoSectionDaily`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSectionDaily => '每日';

  /// Purpose: Return the localized string for `todoSectionRoutine`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSectionRoutine => '日常';

  /// Purpose: Return the localized string for `todoSectionWork`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSectionWork => '工作';

  /// Purpose: Return the localized string for `todoAddTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoAddTask => '新增任務';

  /// Purpose: Return the localized string for `todoEditTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoEditTask => '編輯任務';

  /// Purpose: Return the localized string for `todoTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoTitle => '標題';

  /// Purpose: Return the localized string for `todoNote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoNote => '備註';

  /// Purpose: Return the localized string for `todoNoteHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoNoteHint => '新增選填備註';

  /// Purpose: Return the localized string for `todoSubtasks`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSubtasks => '子任務';

  /// Purpose: Return the localized string for `todoAddSubtask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoAddSubtask => '新增子任務';

  /// Purpose: Return the localized string for `todoReminderTime`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoReminderTime => '提醒時間';

  /// Purpose: Return the localized string for `todoNoTasks`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoNoTasks => '暫無任務';

  /// Purpose: Return the localized string for `todoType`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoType => '類型';

  /// Purpose: Return the localized string for `todoEmoji`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoEmoji => '圖示';

  /// Purpose: Return the localized string for `todoDailyTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoDailyTask => '每日';

  /// Purpose: Return the localized string for `todoRoutineTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoRoutineTask => '日常一次';

  /// Purpose: Return the localized string for `todoWorkTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWorkTask => '工作一次';

  /// Purpose: Implement the todo created date behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoCreatedDate(String date) {
    return '建立日期：$date';
  }

  /// Purpose: Implement the todo start date behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoStartDate(String date) {
    return '開始日期：$date';
  }

  /// Purpose: Implement the todo deleted date behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoDeletedDate(String date) {
    return '刪除日期：$date';
  }

  /// Purpose: Return the localized string for `todoPermanentDelete`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoPermanentDelete => '徹底刪除';

  /// Purpose: Return the localized string for `todoPermanentDeleteConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoPermanentDeleteConfirm => '這將永久刪除此任務及其所有歷史記錄。是否繼續？';

  /// Purpose: Return the localized string for `todoMorningReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoMorningReminder => '晨間計畫提醒';

  /// Purpose: Return the localized string for `todoCompletionReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCompletionReminder => '完成檢查提醒';

  /// Purpose: Return the localized string for `todoSetReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSetReminder => '設定提醒';

  /// Purpose: Return the localized string for `todoClearReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoClearReminder => '清除';

  /// Purpose: Implement the todo reminder set behavior for this file.
  /// Inputs: `time`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoReminderSet(String time) {
    return '提醒已設定：$time';
  }

  /// Purpose: Return the localized string for `todoCompleted`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCompleted => '已完成';

  /// Purpose: Return the localized string for `todoDueDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoDueDate => '截止日期';

  /// Purpose: Return the localized string for `todoSetDueDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSetDueDate => '設定截止日期（可選）';

  /// Purpose: Return the localized string for `todoCustomEmoji`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCustomEmoji => '自訂圖示';

  /// Purpose: Return the localized string for `todoCustomEmojiHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCustomEmojiHint => '輸入一個 emoji';

  /// Purpose: Return the localized string for `todoEditSubtask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoEditSubtask => '編輯子任務';

  /// Purpose: Implement the todo subtasks progress behavior for this file.
  /// Inputs: `done`, `total`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoSubtasksProgress(int done, int total) {
    return '子任务：$done/$total';
  }

  /// Purpose: Implement the todo task due behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoTaskDue(String date) {
    return '截止：$date';
  }

  /// Purpose: Implement the todo task note behavior for this file.
  /// Inputs: `note`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoTaskNote(String note) {
    return '備註：$note';
  }

  /// Purpose: Return the localized string for `todoThisTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoThisTask => '此任务';

  /// Purpose: Return the localized string for `financeTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTitle => '財務';

  /// Purpose: Return the localized string for `financeMonthlyExpense`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeMonthlyExpense => '月度支出';

  /// Purpose: Return the localized string for `financeTotalAssets`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTotalAssets => '總資產';

  /// Purpose: Return the localized string for `financeAccounts`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccounts => '帳戶';

  /// Purpose: Return the localized string for `financeCategories`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCategories => '分類';

  /// Purpose: Return the localized string for `financeTrends`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTrends => '趨勢';

  /// Purpose: Return the localized string for `financeAnalysis`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAnalysis => '分析';

  /// Purpose: Return the localized string for `financeExchangeRates`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeExchangeRates => '匯率';

  /// Purpose: Return the localized string for `financeRefreshRates`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeRefreshRates => '刷新匯率';

  /// Purpose: Return the localized string for `financeAddTransaction`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAddTransaction => '新增交易';

  /// Purpose: Return the localized string for `financeEditTransaction`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEditTransaction => '編輯交易';

  /// Purpose: Return the localized string for `financeExpense`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeExpense => '支出';

  /// Purpose: Return the localized string for `financeIncome`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeIncome => '收入';

  /// Purpose: Return the localized string for `financeTransfer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTransfer => '轉帳';

  /// Purpose: Return the localized string for `financeAmount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAmount => '金額';

  /// Purpose: Return the localized string for `financeNote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNote => '備註';

  /// Purpose: Return the localized string for `financeCategory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCategory => '分類';

  /// Purpose: Return the localized string for `financeAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccount => '帳戶';

  /// Purpose: Return the localized string for `financeFromAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFromAccount => '轉出帳戶';

  /// Purpose: Return the localized string for `financeToAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeToAccount => '轉入帳戶';

  /// Purpose: Return the localized string for `financeCurrency`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCurrency => '幣種';

  /// Purpose: Return the localized string for `financeDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeDate => '日期';

  /// Purpose: Return the localized string for `financeNoTransactions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoTransactions => '暫無交易';

  /// Purpose: Return the localized string for `financeForceBalance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeForceBalance => '強制餘額';

  /// Purpose: Return the localized string for `financeCurrentBalance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCurrentBalance => '目前餘額';

  /// Purpose: Return the localized string for `financeAddAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAddAccount => '新增帳戶';

  /// Purpose: Return the localized string for `financeEditAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEditAccount => '編輯帳戶';

  /// Purpose: Return the localized string for `financeAddCategory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAddCategory => '新增分類';

  /// Purpose: Return the localized string for `financeEditCategory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEditCategory => '編輯分類';

  /// Purpose: Return the localized string for `financeName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeName => '名稱';

  /// Purpose: Return the localized string for `financeBankApp`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBankApp => '銀行 / App';

  /// Purpose: Return the localized string for `financeCardNumber`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCardNumber => '卡號（選填）';

  /// Purpose: Return the localized string for `financeExpiry`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeExpiry => '有效期';

  /// Purpose: Return the localized string for `financeSecurityCode`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSecurityCode => '安全碼';

  /// Purpose: Return the localized string for `financeIcon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeIcon => '圖示';

  /// Purpose: Return the localized string for `financeEmoji`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEmoji => '表情';

  /// Purpose: Return the localized string for `financeCategoryHintExpense`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCategoryHintExpense => '例如 餐飲、交通';

  /// Purpose: Return the localized string for `financeCategoryHintIncome`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCategoryHintIncome => '例如 薪資、投資';

  /// Purpose: Return the localized string for `financeThisTransaction`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeThisTransaction => '此流水';

  /// Purpose: Return the localized string for `financeNoAccounts`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoAccounts => '暫無帳戶';

  /// Purpose: Return the localized string for `financeNoCategories`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoCategories => '暫無分類';

  /// Purpose: Return the localized string for `financeByYear`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeByYear => '按年';

  /// Purpose: Return the localized string for `financeByMonth`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeByMonth => '按月';

  /// Purpose: Return the localized string for `financeByDay`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeByDay => '按日';

  /// Purpose: Return the localized string for `financeCustomRange`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCustomRange => '自訂範圍';

  /// Purpose: Return the localized string for `financeExpenseTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeExpenseTrend => '支出趨勢';

  /// Purpose: Return the localized string for `financeIncomeTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeIncomeTrend => '收入趨勢';

  /// Purpose: Return the localized string for `financeAssetsTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAssetsTrend => '資產趨勢';

  /// Purpose: Return the localized string for `financeThisCategory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeThisCategory => '此分類';

  /// Purpose: Implement the finance no categories of type behavior for this file.
  /// Inputs: `type`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeNoCategoriesOfType(String type) {
    return '暫無$type分類';
  }

  /// Purpose: Return the localized string for `financeImportDefaults`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeImportDefaults => '匯入預設分類';

  /// Purpose: Return the localized string for `financeCatFood`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatFood => '餐飲';

  /// Purpose: Return the localized string for `financeCatTransport`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatTransport => '交通';

  /// Purpose: Return the localized string for `financeCatShopping`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatShopping => '購物';

  /// Purpose: Return the localized string for `financeCatRent`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatRent => '房租';

  /// Purpose: Return the localized string for `financeCatDigital`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatDigital => '數位';

  /// Purpose: Return the localized string for `financeCatEntertainment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatEntertainment => '娛樂';

  /// Purpose: Return the localized string for `financeCatHealthcare`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatHealthcare => '醫療';

  /// Purpose: Return the localized string for `financeCatEducation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatEducation => '教育';

  /// Purpose: Return the localized string for `financeCatSalary`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatSalary => '薪資';

  /// Purpose: Return the localized string for `financeCatBonus`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatBonus => '獎金';

  /// Purpose: Return the localized string for `financeCatInvestment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatInvestment => '投資';

  /// Purpose: Return the localized string for `financeCatFreelance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatFreelance => '兼職';

  /// Purpose: Return the localized string for `intimacyTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTitle => '親密記錄';

  /// Purpose: Return the localized string for `intimacyNewRecord`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNewRecord => '新記錄';

  /// Purpose: Return the localized string for `intimacyEditRecord`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyEditRecord => '編輯記錄';

  /// Purpose: Return the localized string for `intimacySolo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySolo => '獨自';

  /// Purpose: Return the localized string for `intimacyPartner`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPartner => '伴侶';

  /// Purpose: Return the localized string for `intimacyPartners`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPartners => '伴侶';

  /// Purpose: Return the localized string for `intimacyAddPartner`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyAddPartner => '新增伴侶';

  /// Purpose: Return the localized string for `intimacyEditPartner`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyEditPartner => '編輯伴侶';

  /// Purpose: Return the localized string for `intimacyToys`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyToys => '玩具';

  /// Purpose: Return the localized string for `intimacyAddToy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyAddToy => '新增玩具';

  /// Purpose: Return the localized string for `intimacyEditToy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyEditToy => '編輯玩具';

  /// Purpose: Return the localized string for `intimacyPleasure`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPleasure => '愉悅度';

  /// Purpose: Return the localized string for `intimacyDuration`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyDuration => '持續時間';

  /// Purpose: Return the localized string for `intimacyLocation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyLocation => '地點（可選）';

  /// Purpose: Return the localized string for `intimacyNotes`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNotes => '備註（可選）';

  /// Purpose: Return the localized string for `intimacyOrgasm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyOrgasm => '是否高潮？';

  /// Purpose: Return the localized string for `intimacyWatchedPorn`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyWatchedPorn => '是否觀看色情片？';

  /// Purpose: Return the localized string for `intimacyTimer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimer => '計時器';

  /// Purpose: Return the localized string for `intimacyNoRecords`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNoRecords => '暫無記錄';

  /// Purpose: Return the localized string for `intimacyNoPartners`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNoPartners => '暫無伴侶';

  /// Purpose: Return the localized string for `intimacyNoToys`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNoToys => '暫無玩具';

  /// Purpose: Return the localized string for `intimacyNoPartnersHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNoPartnersHint => '暫無伴侶——請在設定中新增';

  /// Purpose: Return the localized string for `intimacyShowAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyShowAll => '顯示全部';

  /// Purpose: Return the localized string for `intimacyShowAllRecords`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyShowAllRecords => '查看全部記錄';

  /// Purpose: Return the localized string for `intimacyAllRecords`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyAllRecords => '所有記錄';

  /// Purpose: Return the localized string for `intimacyStart`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyStart => '開始';

  /// Purpose: Return the localized string for `intimacyPause`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPause => '暫停';

  /// Purpose: Return the localized string for `intimacyResume`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyResume => '繼續';

  /// Purpose: Return the localized string for `intimacyStopSave`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyStopSave => '停止並儲存';

  /// Purpose: Return the localized string for `intimacyReset`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyReset => '重置';

  /// Purpose: Return the localized string for `intimacyTimerStartedAt`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerStartedAt => '開始於';

  /// Purpose: Return the localized string for `intimacyTimerHistory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerHistory => '歷史記錄';

  /// Purpose: Return the localized string for `intimacyTimerClearHistory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerClearHistory => '清除';

  /// Purpose: Return the localized string for `intimacyTimerRetention3d`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerRetention3d => '3 天';

  /// Purpose: Return the localized string for `intimacyTimerRetention7d`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerRetention7d => '7 天';

  /// Purpose: Return the localized string for `intimacyTimerRetention14d`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerRetention14d => '14 天';

  /// Purpose: Return the localized string for `intimacyTimerRetentionForever`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerRetentionForever => '永久';

  /// Purpose: Return the localized string for `intimacyManage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyManage => '管理';

  /// Purpose: Return the localized string for `intimacyModuleVisible`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyModuleVisible => '已顯示';

  /// Purpose: Return the localized string for `intimacyModuleHidden`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyModuleHidden => '已隱藏';

  /// Purpose: Return the localized string for `intimacySortNewest`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortNewest => '最新優先';

  /// Purpose: Return the localized string for `intimacySortOldest`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortOldest => '最早優先';

  /// Purpose: Return the localized string for `intimacySortPleasure`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortPleasure => '愉悅度最高';

  /// Purpose: Return the localized string for `intimacySortDuration`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortDuration => '時長最長';

  /// Purpose: Return the localized string for `intimacyFilterAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFilterAll => '全部';

  /// Purpose: Return the localized string for `intimacyFilterSolo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFilterSolo => '獨自';

  /// Purpose: Return the localized string for `intimacyFilterPartnered`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFilterPartnered => '與伴侶';

  /// Purpose: Return the localized string for `intimacyFilterOrgasm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFilterOrgasm => '有高潮';

  /// Purpose: Return the localized string for `intimacyFilterNoOrgasm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFilterNoOrgasm => '無高潮';

  /// Purpose: Return the localized string for `intimacyExportCsv`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyExportCsv => '匯出CSV';

  /// Purpose: Return the localized string for `intimacyExportCsvSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyExportCsvSuccess => 'CSV匯出成功';

  /// Purpose: Return the localized string for `intimacyExportCsvEmpty`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyExportCsvEmpty => '沒有記錄可匯出';

  /// Purpose: Return the localized string for `intimacyStartDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyStartDate => '交往開始';

  /// Purpose: Return the localized string for `intimacyEndDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyEndDate => '交往結束';

  /// Purpose: Return the localized string for `intimacyPurchaseDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPurchaseDate => '購買日期';

  /// Purpose: Return the localized string for `intimacyRetiredDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyRetiredDate => '退役日期';

  /// Purpose: Return the localized string for `intimacyBreakUp`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyBreakUp => '分手';

  /// Purpose: Return the localized string for `intimacyRetire`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyRetire => '退役';

  /// Purpose: Return the localized string for `settingsTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsTitle => '設定';

  /// Purpose: Return the localized string for `settingsGeneral`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsGeneral => '一般';

  /// Purpose: Return the localized string for `settingsLanguage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsLanguage => '語言';

  /// Purpose: Return the localized string for `settingsTheme`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsTheme => '主題';

  /// Purpose: Return the localized string for `settingsThemeSystem`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsThemeSystem => '跟隨系統';

  /// Purpose: Return the localized string for `settingsThemeLight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsThemeLight => '淺色';

  /// Purpose: Return the localized string for `settingsThemeDark`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsThemeDark => '深色';

  /// Purpose: Return the localized string for `settingsPrivacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsPrivacy => '隱私';

  /// Purpose: Return the localized string for `settingsIntimacyModule`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsIntimacyModule => '親密模組';

  /// Purpose: Return the localized string for `settingsData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsData => '資料';

  /// Purpose: Return the localized string for `settingsStorageLocation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsStorageLocation => '儲存位置';

  /// Purpose: Return the localized string for `settingsStoragePathHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsStoragePathHint => '輸入資料儲存目錄路徑。留空使用預設路徑。';

  /// Purpose: Return the localized string for `settingsDirectoryPath`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsDirectoryPath => '目錄路徑';

  /// Purpose: Return the localized string for `settingsResetDefault`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsResetDefault => '恢復預設';

  /// Purpose: Return the localized string for `settingsResetDefaultLocation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsResetDefaultLocation => '已恢復預設儲存位置';

  /// Purpose: Return the localized string for `settingsStoragePathUpdated`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsStoragePathUpdated => '儲存路徑已更新';

  /// Purpose: Return the localized string for `settingsOpenDataFolder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsOpenDataFolder => '開啟資料目錄';

  /// Purpose: Return the localized string for `settingsOpenDataFolderDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsOpenDataFolderDesc => '開啟應用程式資料夾';

  /// Purpose: Return the localized string for `settingsWebDAVSync`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVSync => 'WebDAV 同步';

  /// Purpose: Return the localized string for `settingsWebDAVNotConfigured`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVNotConfigured => '未設定';

  /// Purpose: Return the localized string for `settingsWebDAVConfigured`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConfigured => '已設定';

  /// Purpose: Return the localized string for `settingsWebDAVServerURL`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVServerURL => '伺服器位址';

  /// Purpose: Return the localized string for `settingsWebDAVUsername`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVUsername => '使用者名稱';

  /// Purpose: Return the localized string for `settingsWebDAVPassword`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVPassword => '密碼';

  /// Purpose: Return the localized string for `settingsWebDAVRemotePath`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVRemotePath => '遠端路徑';

  /// Purpose: Return the localized string for `settingsWebDAVTestConnection`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVTestConnection => '測試連線';

  /// Purpose: Return the localized string for `settingsWebDAVConnectionSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConnectionSuccess => '連線成功';

  /// Purpose: Return the localized string for `settingsWebDAVConnectionFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConnectionFailed => '連線失敗';

  /// Purpose: Return the localized string for `settingsWebDAVSyncNow`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVSyncNow => '立即同步';

  /// Purpose: Return the localized string for `settingsWebDAVAutoSync`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVAutoSync => '自動同步';

  /// Purpose: Return the localized string for `settingsWebDAVAutoSyncDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVAutoSyncDesc => '編輯後和應用程式恢復時自動同步';

  /// Purpose: Return the localized string for `settingsWebDAVSyncing`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVSyncing => '同步中...';

  /// Purpose: Return the localized string for `settingsWebDAVSyncSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVSyncSuccess => '同步完成';

  /// Purpose: Return the localized string for `settingsWebDAVSyncFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVSyncFailed => '同步失敗';

  /// Purpose: Return the localized string for `settingsWebDAVConflictTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConflictTitle => '同步衝突';

  /// Purpose: Return the localized string for `settingsWebDAVConflictDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConflictDesc => '以下紀錄在本機和遠端都有修改，請為每筆紀錄選擇要保留的版本：';

  /// Purpose: Return the localized string for `settingsWebDAVKeepLocal`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVKeepLocal => '保留本機';

  /// Purpose: Return the localized string for `settingsWebDAVKeepRemote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVKeepRemote => '保留遠端';

  /// Purpose: Return the localized string for `settingsWebDAVConflictApply`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConflictApply => '套用';

  /// Purpose: Return the localized string for `settingsWebDAVNextcloud`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVNextcloud => 'Nextcloud 預設';

  /// Purpose: Return the localized string for `settingsWebDAVCustom`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVCustom => '自訂伺服器';

  /// Purpose: Return the localized string for `settingsImportExport`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportExport => '匯入/匯出';

  /// Purpose: Return the localized string for `settingsExportJSON`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportJSON => '匯出 ZIP';

  /// Purpose: Return the localized string for `settingsExportCSV`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportCSV => '匯出 CSV';

  /// Purpose: Return the localized string for `csvExportFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportFinance => '匯出財務 CSV';

  /// Purpose: Return the localized string for `csvExportFinanceDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportFinanceDesc => '財務交易為純文字';

  /// Purpose: Return the localized string for `csvExportIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportIntimacy => '匯出親密 CSV';

  /// Purpose: Return the localized string for `csvExportIntimacyDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportIntimacyDesc => '親密記錄為純文字';

  /// Purpose: Return the localized string for `csvExportWeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportWeight => '匯出體重 CSV';

  /// Purpose: Return the localized string for `csvExportWeightDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportWeightDesc => '體重記錄為純文字';

  /// Purpose: Return the localized string for `settingsImport`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImport => '從檔案匯入';

  /// Purpose: Return the localized string for `settingsExportSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportSuccess => '匯出成功';

  /// Purpose: Return the localized string for `settingsExportFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportFailed => '匯出失敗';

  /// Purpose: Return the localized string for `settingsImportSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportSuccess => '匯入成功';

  /// Purpose: Return the localized string for `settingsImportFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportFailed => '匯入失敗';

  /// Purpose: Return the localized string for `settingsImportConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportConfirm => '此操作將取代所有目前資料。是否繼續？';

  /// Purpose: Return the localized string for `settingsExportCSVWarning`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportCSVWarning => 'CSV 資料將以明文匯出。是否繼續？';

  /// Purpose: Return the localized string for `settingsAbout`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsAbout => '關於';

  /// Purpose: Return the localized string for `settingsAboutTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsAboutTitle => '關於 MyDay!!!!!';

  /// Purpose: Return the localized string for `commonSave`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonSave => '儲存';

  /// Purpose: Return the localized string for `commonDiscard`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonDiscard => '捨棄';

  /// Purpose: Return the localized string for `commonDiscardChangesTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonDiscardChangesTitle => '捨棄修改？';

  /// Purpose: Return the localized string for `commonDiscardChangesMessage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonDiscardChangesMessage => '目前變更尚未儲存，確定要捨棄並關閉嗎？';

  /// Purpose: Return the localized string for `commonCancel`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonCancel => '取消';

  /// Purpose: Return the localized string for `commonDelete`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonDelete => '刪除';

  /// Purpose: Return the localized string for `commonEdit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonEdit => '編輯';

  /// Purpose: Return the localized string for `commonAdd`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonAdd => '新增';

  /// Purpose: Return the localized string for `commonConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonConfirm => '確認';

  /// Purpose: Return the localized string for `commonYes`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonYes => '是';

  /// Purpose: Return the localized string for `commonNo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonNo => '否';

  /// Purpose: Return the localized string for `commonOk`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonOk => '好';

  /// Purpose: Return the localized string for `commonClose`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonClose => '關閉';

  /// Purpose: Return the localized string for `commonName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonName => '名稱';

  /// Purpose: Return the localized string for `commonEmojiOptional`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonEmojiOptional => '圖示（可選）';

  /// Purpose: Return the localized string for `commonOptional`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonOptional => '可選';

  /// Purpose: Implement the common delete confirm behavior for this file.
  /// Inputs: `item`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String commonDeleteConfirm(String item) {
    return '刪除$item？';
  }

  /// Purpose: Implement the common minutes behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String commonMinutes(int count) {
    return '$count分鐘';
  }

  /// Purpose: Return the localized string for `settingsExportSection`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportSection => '匯出';

  /// Purpose: Return the localized string for `settingsImportSection`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportSection => '匯入';

  /// Purpose: Return the localized string for `settingsExportFullBackup`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportFullBackup => '所有資料的完整備份';

  /// Purpose: Return the localized string for `settingsExportJSONPlaintext`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportJSONPlaintext => '所有資料將以 ZIP 壓縮檔匯出';

  /// Purpose: Return the localized string for `settingsExportCSVPlaintext`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportCSVPlaintext => '財務交易為純文字';

  /// Purpose: Return the localized string for `settingsImportRestore`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportRestore => '從ZIP備份還原';

  /// Purpose: Return the localized string for `settingsImportData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportData => '匯入資料';

  /// Purpose: Return the localized string for `csvImportFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportFinance => '匯入財務 CSV';

  /// Purpose: Return the localized string for `csvImportFinanceDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportFinanceDesc => '從 CSV 合併交易記錄（不會覆蓋現有資料）';

  /// Purpose: Return the localized string for `csvImportIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportIntimacy => '匯入親密 CSV';

  /// Purpose: Return the localized string for `csvImportIntimacyDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportIntimacyDesc => '從 CSV 合併記錄（不會覆蓋現有資料）';

  /// Purpose: Return the localized string for `csvImportConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportConfirm => 'CSV 資料將合併到現有記錄中，是否繼續？';

  /// Purpose: Implement the csv import success behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String csvImportSuccess(int count) {
    return '成功匯入 $count 筆記錄';
  }

  /// Purpose: Return the localized string for `csvImportFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportFailed => 'CSV 匯入失敗';

  /// Purpose: Return the localized string for `csvImportEmpty`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportEmpty => 'CSV 中未找到有效記錄';

  /// Purpose: Return the localized string for `csvTemplate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvTemplate => 'CSV 模板';

  /// Purpose: Return the localized string for `csvTemplateFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvTemplateFinance => '下載財務模板';

  /// Purpose: Return the localized string for `csvTemplateIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvTemplateIntimacy => '下載親密模板';

  /// Purpose: Return the localized string for `csvTemplateSaved`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvTemplateSaved => '模板已儲存';

  /// Purpose: Return the localized string for `settingsWebDAVDisconnect`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVDisconnect => '中斷連線';

  /// Purpose: Return the localized string for `settingsWebDAVConfigSaved`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConfigSaved => '設定已儲存';

  /// Purpose: Return the localized string for `settingsWebDAVConfigRemoved`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConfigRemoved => '設定已移除';

  /// Purpose: Return the localized string for `commonDontAskMinutes`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonDontAskMinutes => '5分鐘內不再詢問';

  /// Purpose: Return the localized string for `intimacyHideConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyHideConfirm => '關閉親密模組不會刪除資料，隨時可以重新開啟。';

  /// Purpose: Return the localized string for `settingsLicense`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsLicense => '授權條款 (GPLv3)';

  /// Purpose: Return the localized string for `settingsLicenses`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsLicenses => '開源授權條款';

  /// Purpose: Return the localized string for `settingsPrivacyPolicy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsPrivacyPolicy => '隱私政策';

  /// Purpose: Return the localized string for `settingsDesktop`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsDesktop => '桌面';

  /// Purpose: Return the localized string for `settingsMinimizeToTray`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsMinimizeToTray => '最小化至系統匙';

  /// Purpose: Return the localized string for `settingsCloseToTray`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsCloseToTray => '關閉至系統匙';

  /// Purpose: Return the localized string for `financeBankPresets`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBankPresets => '銀行預設';

  /// Purpose: Return the localized string for `financeBankSearch`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBankSearch => '搜尋銀行或應用...';

  /// Purpose: Return the localized string for `financeBankNoResults`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBankNoResults => '未找到符合的銀行';

  /// Purpose: Return the localized string for `financeSubscriptions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSubscriptions => '訂閱';

  /// Purpose: Return the localized string for `financeSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSubscription => '訂閱';

  /// Purpose: Return the localized string for `financeAddSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAddSubscription => '新增訂閱';

  /// Purpose: Return the localized string for `financeEditSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEditSubscription => '編輯訂閱';

  /// Purpose: Return the localized string for `financeStartDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeStartDate => '開始日期';

  /// Purpose: Return the localized string for `financeTrialDays`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTrialDays => '試用天數';

  /// Purpose: Return the localized string for `financeBillingCycle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBillingCycle => '付費週期';

  /// Purpose: Return the localized string for `financeBillingCycleMonthly`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBillingCycleMonthly => '按月';

  /// Purpose: Return the localized string for `financeBillingCycleYearly`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBillingCycleYearly => '按年';

  /// Purpose: Implement the finance every x months behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeEveryXMonths(int count) {
    return '每 $count 個月';
  }

  /// Purpose: Implement the finance every x years behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeEveryXYears(int count) {
    return '每 $count 年';
  }

  /// Purpose: Return the localized string for `financeBillingDay`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBillingDay => '扣費日';

  /// Purpose: Return the localized string for `financeBillingMonth`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBillingMonth => '扣費月份';

  /// Purpose: Return the localized string for `financeMonthlyDue`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeMonthlyDue => '月應付';

  /// Purpose: Return the localized string for `financeMonthlyAvg`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeMonthlyAvg => '月均花費';

  /// Purpose: Return the localized string for `financeYearlyAvg`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeYearlyAvg => '年均花費';

  /// Purpose: Return the localized string for `financeNoSubscriptions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoSubscriptions => '暫無訂閱';

  /// Purpose: Return the localized string for `financeActiveSubscriptions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeActiveSubscriptions => '進行中';

  /// Purpose: Return the localized string for `financeHistoricalSubscriptions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeHistoricalSubscriptions => '歷史';

  /// Purpose: Return the localized string for `financeCancelSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCancelSubscription => '取消訂閱';

  /// Purpose: Return the localized string for `financeCancelImmediate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCancelImmediate => '立即取消';

  /// Purpose: Return the localized string for `financeCancelAtExpiry`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCancelAtExpiry => '到期取消';

  /// Purpose: Return the localized string for `financeNextBilling`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNextBilling => '下次扣費';

  /// Purpose: Return the localized string for `financeExpiryDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeExpiryDate => '到期日期';

  /// Purpose: Return the localized string for `financeTotalSpent`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTotalSpent => '累計花費';

  /// Purpose: Return the localized string for `financeImportHistory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeImportHistory => '匯入歷史交易';

  /// Purpose: Return the localized string for `financeImportHistoryDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeImportHistoryDesc => '開始日期在今天之前，是否匯入歷史交易？';

  /// Purpose: Return the localized string for `financeThisSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeThisSubscription => '此訂閱';

  /// Purpose: Implement the finance cancelled on behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeCancelledOn(String date) {
    return '已於 $date 取消';
  }

  /// Purpose: Return the localized string for `financeInterval`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeInterval => '間隔';

  /// Purpose: Return the localized string for `financeImage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeImage => '圖片';

  /// Purpose: Return the localized string for `financePickImage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financePickImage => '選擇圖片';

  /// Purpose: Return the localized string for `financeChangeImage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeChangeImage => '更換';

  /// Purpose: Return the localized string for `financeUpcomingRenewals`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeUpcomingRenewals => '即將續費';

  /// Purpose: Return the localized string for `financeSubscriptionReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSubscriptionReminder => '訂閱提醒';

  /// Purpose: Return the localized string for `financeReminderTime`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeReminderTime => '通知時間';

  /// Purpose: Return the localized string for `financeReminderEnabled`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeReminderEnabled => '提醒即將續費的服務';

  /// Purpose: Implement the finance subscription due soon behavior for this file.
  /// Inputs: `name`, `days`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeSubscriptionDueSoon(String name, int days) {
    return '$name 將在 $days 天後續費';
  }

  /// Purpose: Implement the finance subscription due today behavior for this file.
  /// Inputs: `name`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeSubscriptionDueToday(String name) {
    return '$name 今天續費';
  }

  /// Purpose: Return the localized string for `financeSortBy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortBy => '排序';

  /// Purpose: Return the localized string for `financeSortByRenewal`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortByRenewal => '按續費日期';

  /// Purpose: Return the localized string for `financeSortByName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortByName => '按名稱';

  /// Purpose: Return the localized string for `financeSortByBank`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortByBank => '按銀行 / 應用';

  /// Purpose: Return the localized string for `financeSortCustom`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortCustom => '自訂';

  /// Purpose: Return the localized string for `financeSortReorder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortReorder => '調整順序';

  /// Purpose: Return the localized string for `financeSortDone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortDone => '完成';

  /// Purpose: Return the localized string for `financeRestoreSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeRestoreSubscription => '恢復訂閱';

  /// Purpose: Return the localized string for `backupTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupTitle => '備份';

  /// Purpose: Return the localized string for `backupLocalOnlyNote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupLocalOnlyNote => '備份僅儲存在本機，如需雲端同步請使用 WebDAV 同步。';

  /// Purpose: Return the localized string for `backupSettings`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupSettings => '設定';

  /// Purpose: Return the localized string for `backupAutoDaily`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupAutoDaily => '每日自動備份';

  /// Purpose: Return the localized string for `backupAutoDailyDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupAutoDailyDesc => '每天自動建立一次備份';

  /// Purpose: Return the localized string for `backupRetention`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRetention => '保留備份';

  /// Purpose: Return the localized string for `backupRetentionForever`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRetentionForever => '永久保存';

  /// Purpose: Implement the backup retention days behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String backupRetentionDays(int count) {
    return '$count 天';
  }

  /// Purpose: Return the localized string for `backupManual`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupManual => '手動備份';

  /// Purpose: Return the localized string for `backupCreateNow`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupCreateNow => '立即建立備份';

  /// Purpose: Implement the backup history behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String backupHistory(int count) {
    return '備份歷史 ($count)';
  }

  /// Purpose: Return the localized string for `backupEmpty`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupEmpty => '尚無備份';

  /// Purpose: Return the localized string for `backupCreated`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupCreated => '備份建立成功';

  /// Purpose: Return the localized string for `backupFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupFailed => '備份失敗';

  /// Purpose: Return the localized string for `backupRestore`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestore => '還原';

  /// Purpose: Return the localized string for `backupRestoreConfirmTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreConfirmTitle => '確認還原';

  /// Purpose: Return the localized string for `backupRestoreConfirmDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreConfirmDesc => '這將替換所選模組的資料，是否繼續？';

  /// Purpose: Return the localized string for `backupRestoreSelectModules`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreSelectModules => '選擇要還原的模組';

  /// Purpose: Return the localized string for `backupRestoreAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreAll => '全部模組';

  /// Purpose: Return the localized string for `backupRestoreSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreSuccess => '還原成功，請重啟應用。';

  /// Purpose: Return the localized string for `backupRestoreFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreFailed => '還原失敗';

  /// Purpose: Return the localized string for `backupDeleteConfirmTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupDeleteConfirmTitle => '刪除備份';

  /// Purpose: Return the localized string for `backupDeleteConfirmDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupDeleteConfirmDesc => '該備份將被永久刪除。';

  /// Purpose: Return the localized string for `backupModuleTodo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupModuleTodo => '待辦事項';

  /// Purpose: Return the localized string for `backupModuleFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupModuleFinance => '財務';

  /// Purpose: Return the localized string for `backupModuleRates`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupModuleRates => '匯率';

  /// Purpose: Return the localized string for `backupModuleIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupModuleIntimacy => '親密';

  /// Purpose: Implement the intimacy record count behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String intimacyRecordCount(int count) {
    return '$count 條記錄';
  }

  /// Purpose: Return the localized string for `weightTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightTitle => '體重';

  /// Purpose: Return the localized string for `weightSetHeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightSetHeight => '設定身高';

  /// Purpose: Return the localized string for `weightNoRecords`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightNoRecords => '暫無體重記錄';

  /// Purpose: Return the localized string for `weightAddRecord`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightAddRecord => '新增記錄';

  /// Purpose: Return the localized string for `weightKg`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightKg => '體重（kg）';

  /// Purpose: Return the localized string for `weightHeightCm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightHeightCm => '身高（cm）';

  /// Purpose: Return the localized string for `weightNote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightNote => '備註';

  /// Purpose: Return the localized string for `weightNoteHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightNoteHint => '可選備註';

  /// Purpose: Return the localized string for `weightChart`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightChart => '趨勢';

  /// Purpose: Return the localized string for `weightAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightAll => '全部';

  /// Purpose: Return the localized string for `weightHistory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightHistory => '歷史';

  /// Purpose: Return the localized string for `weightShowAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightShowAll => '查看全部記錄';

  /// Purpose: Return the localized string for `weightDays`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightDays => '天';

  /// Purpose: Return the localized string for `weightDaysAgo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightDaysAgo => '天前';

  /// Purpose: Return the localized string for `weightWeeksAgo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightWeeksAgo => '週前';

  /// Purpose: Return the localized string for `weightToday`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightToday => '今天';

  /// Purpose: Return the localized string for `weightYesterday`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightYesterday => '昨天';

  /// Purpose: Return the localized string for `weightRecent`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightRecent => '近期';

  /// Purpose: Return the localized string for `weightExportCsv`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightExportCsv => '匯出CSV';

  /// Purpose: Return the localized string for `weightExportCsvSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightExportCsvSuccess => '體重資料匯出成功';

  /// Purpose: Return the localized string for `weightExportCsvEmpty`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightExportCsvEmpty => '沒有體重記錄可匯出';

  /// Purpose: Return the localized string for `csvImportWeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportWeight => '匯入體重 CSV';

  /// Purpose: Return the localized string for `csvImportWeightDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportWeightDesc => '從 CSV 合併體重記錄（日期、時間、體重）';

  /// Purpose: Return the localized string for `csvTemplateWeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvTemplateWeight => '下載體重模板';

  /// Purpose: Return the localized string for `financeSubscriptionPresets`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSubscriptionPresets => '快速填入';

  /// Purpose: Return the localized string for `intimacyPurchaseLink`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPurchaseLink => '購買連結';

  /// Purpose: Return the localized string for `intimacyPrice`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPrice => '價格';

  /// Purpose: Return the localized string for `intimacyPositions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPositions => '體位';

  /// Purpose: Return the localized string for `intimacyAddPosition`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyAddPosition => '新增體位';

  /// Purpose: Return the localized string for `intimacyEditPosition`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyEditPosition => '編輯體位';

  /// Purpose: Return the localized string for `intimacyNoPositions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNoPositions => '尚無體位';

  /// Purpose: Return the localized string for `intimacyImportDefaults`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyImportDefaults => '匯入預設';

  /// Purpose: Return the localized string for `intimacyTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTrend => '趨勢';

  /// Purpose: Return the localized string for `intimacyFrequency`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFrequency => '頻率';

  /// Purpose: Return the localized string for `intimacyChartNoData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyChartNoData => '資料不足';

  /// Purpose: Return the localized string for `weightTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightTrend => '趨勢';

  /// Purpose: Return the localized string for `weightRaw`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightRaw => '實際';

  /// Purpose: Return the localized string for `weightReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminder => '體重提醒';

  /// Purpose: Return the localized string for `weightReminderNone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderNone => '不提醒';

  /// Purpose: Return the localized string for `weightReminderOnce`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderOnce => '每天一次';

  /// Purpose: Return the localized string for `weightReminderTwice`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderTwice => '每天兩次（早晚）';

  /// Purpose: Return the localized string for `weightReminderMorning`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderMorning => '早晨';

  /// Purpose: Return the localized string for `weightReminderEvening`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderEvening => '晚間';

  /// Purpose: Return the localized string for `weightReminderSkipWindow`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderSkipWindow => '已有記錄則跳過';

  /// Purpose: Implement the weight reminder skip window value behavior for this file.
  /// Inputs: `hours`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String weightReminderSkipWindowValue(String hours) {
    return '提醒前 $hours 小時內';
  }

  /// Purpose: Return the localized string for `weightReminderSkipWindowHours`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderSkipWindowHours => '提醒前小時數';

  /// Purpose: Return the localized string for `commonChange`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonChange => '更換';

  /// Purpose: Return the localized string for `commonPickImage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonPickImage => '選擇圖片';

  /// Purpose: Return the localized string for `commonRemoveIcon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonRemoveIcon => '移除圖示';

  /// Purpose: Return the localized string for `commonPickIcon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonPickIcon => '選擇圖示';

  /// Purpose: Return the localized string for `commonNoData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonNoData => '無資料';

  /// Purpose: Implement the common week group behavior for this file.
  /// Inputs: `year`, `week`, `range`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String commonWeekGroup(int year, int week, String range) {
    return '$year 第$week週（$range）';
  }

  /// Purpose: Return the localized string for `todoDailyReminders`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoDailyReminders => '每日提醒';

  /// Purpose: Return the localized string for `todoRemindReviewHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoRemindReviewHint => '提醒查看今日待辦事項';

  /// Purpose: Return the localized string for `todoRemindUndoneHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoRemindUndoneHint => '提醒未完成的任務';

  /// Purpose: Return the localized string for `todoTapReturnToday`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoTapReturnToday => '點擊返回今天';

  /// Purpose: Return the localized string for `todoCalendar`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCalendar => '日曆';

  /// Purpose: Return the localized string for `todoWeekMon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekMon => '一';

  /// Purpose: Return the localized string for `todoWeekTue`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekTue => '二';

  /// Purpose: Return the localized string for `todoWeekWed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekWed => '三';

  /// Purpose: Return the localized string for `todoWeekThu`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekThu => '四';

  /// Purpose: Return the localized string for `todoWeekFri`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekFri => '五';

  /// Purpose: Return the localized string for `todoWeekSat`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekSat => '六';

  /// Purpose: Return the localized string for `todoWeekSun`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekSun => '日';

  /// Purpose: Return the localized string for `todoCalendarSomeDaily`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCalendarSomeDaily => '部分完成';

  /// Purpose: Return the localized string for `todoCalendarAllDaily`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCalendarAllDaily => '日常全完成';

  /// Purpose: Return the localized string for `todoCalendarAllDone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCalendarAllDone => '全部完成';

  /// Purpose: Return the localized string for `todoWhatNeedsDone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWhatNeedsDone => '需要做什麼？';

  /// Purpose: Implement the todo reminder at behavior for this file.
  /// Inputs: `time`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoReminderAt(String time) {
    return '提醒：$time';
  }

  /// Purpose: Return the localized string for `todoAddReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoAddReminder => '新增提醒（選填）';

  /// Purpose: Implement the todo scheduled at behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoScheduledAt(String date) {
    return '排程：$date';
  }

  /// Purpose: Return the localized string for `todoSetScheduledDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSetScheduledDate => '設定排程日期';

  /// Purpose: Implement the todo completed at behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoCompletedAt(String date) {
    return '完成：$date';
  }

  /// Purpose: Return the localized string for `todoSetCompletedDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSetCompletedDate => '設定完成日期';

  /// Purpose: Return the localized string for `todoSortBy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSortBy => '排序';

  /// Purpose: Return the localized string for `todoSortByAdded`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSortByAdded => '按新增時間';

  /// Purpose: Return the localized string for `todoSortByDueDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSortByDueDate => '按截止日期';

  /// Purpose: Return the localized string for `todoSortByName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSortByName => '按名稱';

  /// Purpose: Return the localized string for `todoSortCustom`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSortCustom => '自訂';

  /// Purpose: Return the localized string for `weightUnitKg`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightUnitKg => 'kg';

  /// Purpose: Implement the weight value kg behavior for this file.
  /// Inputs: `value`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String weightValueKg(String value) {
    return '$value kg';
  }

  /// Purpose: Return the localized string for `positionMissionary`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionMissionary => '傳教士式';

  /// Purpose: Return the localized string for `positionCowgirl`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionCowgirl => '騎乘式';

  /// Purpose: Return the localized string for `positionDoggyStyle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionDoggyStyle => '後入式';

  /// Purpose: Return the localized string for `positionReverseCowgirl`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionReverseCowgirl => '反騎乘式';

  /// Purpose: Return the localized string for `positionSpooning`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionSpooning => '側入式';

  /// Purpose: Return the localized string for `positionStanding`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionStanding => '站立式';

  /// Purpose: Return the localized string for `position69`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get position69 => '69式';

  /// Purpose: Return the localized string for `positionLotus`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionLotus => '蓮花式';

  /// Purpose: Return the localized string for `positionProneBone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionProneBone => '趴伏式';

  /// Purpose: Return the localized string for `notifTodoMorning`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get notifTodoMorning => '早安！是時候查看和更新您的待辦事項了 📝';

  /// Purpose: Return the localized string for `notifTodoCompletion`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get notifTodoCompletion => '別忘了完成今天剩餘的任務！';

  /// Purpose: Implement the notif todo uncompleted behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String notifTodoUncompleted(int count) {
    return '今天還有 $count 個任務未完成！';
  }

  /// Purpose: Return the localized string for `notifWeightReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get notifWeightReminder => '記得記錄體重！⚖️';

  /// Purpose: Implement the notif upcoming renewals behavior for this file.
  /// Inputs: `list`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String notifUpcomingRenewals(String list) {
    return '即將續費：$list';
  }

  /// Purpose: Implement the notif subscription today behavior for this file.
  /// Inputs: `name`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String notifSubscriptionToday(String name) {
    return '$name（今天）';
  }

  /// Purpose: Implement the notif subscription days behavior for this file.
  /// Inputs: `name`, `days`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String notifSubscriptionDays(String name, int days) {
    return '$name（$days天後）';
  }

  /// Purpose: Return the localized string for `trayShow`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get trayShow => '顯示';

  /// Purpose: Return the localized string for `trayQuit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get trayQuit => '退出';

  /// Purpose: Return the localized string for `filePickerExportLocation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get filePickerExportLocation => '選擇匯出位置';

  /// Purpose: Return the localized string for `filePickerBackupFile`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get filePickerBackupFile => '選擇備份檔案';

  /// Purpose: Return the localized string for `filePickerCsvFile`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get filePickerCsvFile => '選擇CSV檔案';

  /// Purpose: Return the localized string for `filePickerSaveTemplate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get filePickerSaveTemplate => '儲存範本到';

  /// Purpose: Return the localized string for `financeBalance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBalance => '餘額';

  /// Purpose: Return the localized string for `financeNewAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNewAccount => '新增帳戶';

  /// Purpose: Return the localized string for `financeAccountTypeFund`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountTypeFund => '活存';

  /// Purpose: Return the localized string for `financeAccountTypeCredit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountTypeCredit => '信用卡';

  /// Purpose: Return the localized string for `financeAccountTypeRecharge`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountTypeRecharge => '儲值';

  /// Purpose: Return the localized string for `financeAccountTypeFinancial`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountTypeFinancial => '理財';

  /// Purpose: Return the localized string for `financeAccountName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountName => '帳戶名稱';

  /// Purpose: Return the localized string for `financeBankAppHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBankAppHint => '例如：玉山銀行、街口支付';

  /// Purpose: Return the localized string for `financeCardNumberHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCardNumberHint => '末4碼';

  /// Purpose: Return the localized string for `financeFeeWaiverConditions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverConditions => '免月管理費條件';

  /// Purpose: Return the localized string for `financeFeeWaiverConditionsHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverConditionsHint => '選填，用於記錄銀行免收月管理費的條件。';

  /// Purpose: Return the localized string for `financeFeeWaiverMinimumBalance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverMinimumBalance => '最低餘額';

  /// Purpose: Return the localized string for `financeFeeWaiverMinimumBalanceHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverMinimumBalanceHint => '例如 1500';

  /// Purpose: Return the localized string for `financeFeeWaiverMonthlyDeposit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverMonthlyDeposit => '每月轉入額';

  /// Purpose: Return the localized string for `financeFeeWaiverMonthlyDepositHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverMonthlyDepositHint => '例如 500';

  /// Purpose: Return the localized string for `financeFeeWaiverSeparator`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverSeparator => ' 或 ';

  /// Purpose: Return the localized string for `financeCurrentBalanceHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCurrentBalanceHint => '留空則從交易記錄計算';

  /// Purpose: Return the localized string for `financeAsOfToday`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAsOfToday => '截至今日';

  /// Purpose: Return the localized string for `financeBalanceEffectiveDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBalanceEffectiveDate => '餘額生效日期';

  /// Purpose: Return the localized string for `financeFetchIcon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFetchIcon => '取得圖示';

  /// Purpose: Return the localized string for `financeAccountsCategories`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountsCategories => '帳戶與分類';

  /// Purpose: Return the localized string for `financeEditRate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEditRate => '編輯匯率';

  /// Purpose: Return the localized string for `financeNewRate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNewRate => '新增匯率';

  /// Purpose: Return the localized string for `financeFrom`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFrom => '從';

  /// Purpose: Return the localized string for `financeTo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTo => '到';

  /// Purpose: Return the localized string for `financeRate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeRate => '匯率';

  /// Purpose: Implement the finance rate hint behavior for this file.
  /// Inputs: `from`, `to`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeRateHint(String from, String to) {
    return '1 $from = ? $to';
  }

  /// Purpose: Return the localized string for `financeNoRates`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoRates => '尚未設定匯率';

  /// Purpose: Return the localized string for `financeNoExpenseData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoExpenseData => '此期間無支出資料';

  /// Purpose: Return the localized string for `financeUncategorized`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeUncategorized => '未分類';

  /// Purpose: Return the localized string for `financeTotal`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTotal => '合計';

  /// Purpose: Return the localized string for `financeSelectDateRange`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSelectDateRange => '選擇日期範圍';

  /// Purpose: Return the localized string for `financeNoTransactionData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoTransactionData => '此期間無交易資料';

  /// Purpose: Implement the finance received amount behavior for this file.
  /// Inputs: `currency`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeReceivedAmount(String currency) {
    return '入帳金額 ($currency)';
  }

  /// Purpose: Return the localized string for `financeReceivedAmountHelper`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeReceivedAmountHelper => '對方帳戶幣別的入帳金額';

  /// Purpose: Return the localized string for `financeNoteHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoteHint => '這筆是為了什麼？';

  /// Purpose: Return the localized string for `financeThisAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeThisAccount => '此帳戶';

  /// Purpose: Return the localized string for `commonThisRecord`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonThisRecord => '此記錄';

  /// Purpose: Return the localized string for `financeBalanceAdjustment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBalanceAdjustment => '餘額調整';

  /// Purpose: Return the localized string for `financeCatCreditCardPayment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatCreditCardPayment => '還信用卡';

  /// Purpose: Return the localized string for `financeCatFixedDeposit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatFixedDeposit => '定存到期';

  /// Purpose: Return the localized string for `financeCatInternalTransfer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatInternalTransfer => '內部轉帳';

  /// Purpose: Return the localized string for `financeCatLoanRepayment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatLoanRepayment => '還貸';

  /// Purpose: Return the localized string for `financeCatInvestmentTransfer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatInvestmentTransfer => '投資轉入';

  /// Purpose: Return the localized string for `financeCatReimburse`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatReimburse => '報帳';

  /// Purpose: Return the localized string for `settingsAutoStart`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsAutoStart => '開機自動啟動';

  /// Purpose: Return the localized string for `settingsApiEnabled`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiEnabled => '本機 API 伺服器';

  /// Purpose: Return the localized string for `settingsApiServer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiServer => 'API 伺服器設定';

  /// Purpose: Implement the settings api running behavior for this file.
  /// Inputs: `port`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String settingsApiRunning(int port) {
    return '運行中，連接埠 $port';
  }

  /// Purpose: Return the localized string for `settingsApiStopped`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiStopped => '已停止';

  /// Purpose: Return the localized string for `settingsApiNeedCredentials`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiNeedCredentials => '非本機存取需設定認證';

  /// Purpose: Implement the settings api restarted behavior for this file.
  /// Inputs: `port`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String settingsApiRestarted(int port) {
    return 'API 伺服器已重啟，連接埠 $port';
  }

  /// Purpose: Return the localized string for `settingsApiListenAddress`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiListenAddress => '監聽地址';

  /// Purpose: Return the localized string for `settingsApiPort`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiPort => '連接埠';

  /// Purpose: Return the localized string for `settingsApiUsername`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiUsername => '使用者名稱';

  /// Purpose: Return the localized string for `settingsApiPassword`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiPassword => '密碼';

  /// Purpose: Return the localized string for `todoRecurrence`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoRecurrence => '重複';

  /// Purpose: Return the localized string for `todoRecurrenceNone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoRecurrenceNone => '無';

  /// Purpose: Implement the todo recurrence every n days behavior for this file.
  /// Inputs: `n`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoRecurrenceEveryNDays(int n) {
    return '每隔 $n 天';
  }

  /// Purpose: Implement the todo recurrence monthly on day behavior for this file.
  /// Inputs: `n`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoRecurrenceMonthlyOnDay(int n) {
    return '每月 $n 日';
  }

  /// Purpose: Implement the todo recurrence yearly on date behavior for this file.
  /// Inputs: `month`, `day`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoRecurrenceYearlyOnDate(int month, int day) {
    return '每年 $month/$day';
  }

  /// Purpose: Return the localized string for `todoNextOccurrence`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoNextOccurrence => '安排下次任務';

  /// Purpose: Return the localized string for `intimacyActivePartners`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyActivePartners => '現役伴侶';

  /// Purpose: Return the localized string for `intimacyPastPartners`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPastPartners => '已分手伴侶';

  /// Purpose: Return the localized string for `intimacyActiveToys`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyActiveToys => '現役玩具';

  /// Purpose: Return the localized string for `intimacyRetiredToys`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyRetiredToys => '退役玩具';

  /// Purpose: Return the localized string for `intimacySortByRelationshipDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortByRelationshipDate => '按交往時間';

  /// Purpose: Return the localized string for `intimacySortByPurchaseDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortByPurchaseDate => '按購買時間';

  /// Purpose: Return the localized string for `intimacySortByUseCount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortByUseCount => '按使用次數';
}
