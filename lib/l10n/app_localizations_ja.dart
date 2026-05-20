// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

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
  String get navTodo => 'ToDo';

  /// Purpose: Return the localized string for `navFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get navFinance => '家計';

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
  String get navIntimacy => 'プライベート';

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
  String get todoSectionDaily => '毎日';

  /// Purpose: Return the localized string for `todoSectionRoutine`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSectionRoutine => '日課';

  /// Purpose: Return the localized string for `todoSectionWork`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSectionWork => '仕事';

  /// Purpose: Return the localized string for `todoAddTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoAddTask => 'タスクを追加';

  /// Purpose: Return the localized string for `todoEditTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoEditTask => 'タスクを編集';

  /// Purpose: Return the localized string for `todoTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoTitle => 'タイトル';

  /// Purpose: Return the localized string for `todoNote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoNote => 'メモ';

  /// Purpose: Return the localized string for `todoNoteHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoNoteHint => '任意のメモを追加';

  /// Purpose: Return the localized string for `todoSubtasks`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSubtasks => 'サブタスク';

  /// Purpose: Return the localized string for `todoAddSubtask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoAddSubtask => 'サブタスクを追加';

  /// Purpose: Return the localized string for `todoReminderTime`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoReminderTime => 'リマインダー時間';

  /// Purpose: Return the localized string for `todoNoTasks`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoNoTasks => 'タスクなし';

  /// Purpose: Return the localized string for `todoType`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoType => '種類';

  /// Purpose: Return the localized string for `todoEmoji`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoEmoji => '絵文字';

  /// Purpose: Return the localized string for `todoDailyTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoDailyTask => '毎日';

  /// Purpose: Return the localized string for `todoRoutineTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoRoutineTask => '日課（1回）';

  /// Purpose: Return the localized string for `todoWorkTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWorkTask => '仕事（1回）';

  /// Purpose: Implement the todo created date behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoCreatedDate(String date) {
    return '作成日：$date';
  }

  /// Purpose: Implement the todo start date behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoStartDate(String date) {
    return '開始日：$date';
  }

  /// Purpose: Implement the todo deleted date behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoDeletedDate(String date) {
    return '削除日：$date';
  }

  /// Purpose: Return the localized string for `todoPermanentDelete`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoPermanentDelete => '完全に削除';

  /// Purpose: Return the localized string for `todoPermanentDeleteConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoPermanentDeleteConfirm => 'このタスクとその履歴を完全に削除します。続行しますか？';

  /// Purpose: Return the localized string for `todoMorningReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoMorningReminder => '朝のプランリマインダー';

  /// Purpose: Return the localized string for `todoCompletionReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCompletionReminder => '完了チェックリマインダー';

  /// Purpose: Return the localized string for `todoSetReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSetReminder => 'リマインダーを設定';

  /// Purpose: Return the localized string for `todoClearReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoClearReminder => 'クリア';

  /// Purpose: Implement the todo reminder set behavior for this file.
  /// Inputs: `time`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoReminderSet(String time) {
    return 'リマインダー設定済み：$time';
  }

  /// Purpose: Return the localized string for `todoCompleted`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCompleted => '完了';

  /// Purpose: Return the localized string for `todoDueDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoDueDate => '期限';

  /// Purpose: Return the localized string for `todoSetDueDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSetDueDate => '期限を設定（任意）';

  /// Purpose: Return the localized string for `todoCustomEmoji`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCustomEmoji => 'カスタム絵文字';

  /// Purpose: Return the localized string for `todoCustomEmojiHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCustomEmojiHint => '絵文字を入力';

  /// Purpose: Return the localized string for `todoEditSubtask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoEditSubtask => 'サブタスクを編集';

  /// Purpose: Implement the todo subtasks progress behavior for this file.
  /// Inputs: `done`, `total`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoSubtasksProgress(int done, int total) {
    return 'サブタスク：$done/$total';
  }

  /// Purpose: Implement the todo task due behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoTaskDue(String date) {
    return '締切：$date';
  }

  /// Purpose: Implement the todo task note behavior for this file.
  /// Inputs: `note`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoTaskNote(String note) {
    return 'メモ：$note';
  }

  /// Purpose: Return the localized string for `todoThisTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoThisTask => 'このタスク';

  /// Purpose: Return the localized string for `financeTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTitle => '家計';

  /// Purpose: Return the localized string for `financeMonthlyExpense`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeMonthlyExpense => '月間支出';

  /// Purpose: Return the localized string for `financeTotalAssets`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTotalAssets => '総資産';

  /// Purpose: Return the localized string for `financeAccounts`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccounts => '口座';

  /// Purpose: Return the localized string for `financeCategories`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCategories => 'カテゴリ';

  /// Purpose: Return the localized string for `financeTrends`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTrends => 'トレンド';

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
  String get financeExchangeRates => '為替レート';

  /// Purpose: Return the localized string for `financeRefreshRates`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeRefreshRates => 'レートを更新';

  /// Purpose: Return the localized string for `financeAddTransaction`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAddTransaction => '取引を追加';

  /// Purpose: Return the localized string for `financeEditTransaction`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEditTransaction => '取引を編集';

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
  String get financeIncome => '収入';

  /// Purpose: Return the localized string for `financeTransfer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTransfer => '振替';

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
  String get financeNote => 'メモ';

  /// Purpose: Return the localized string for `financeCategory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCategory => 'カテゴリ';

  /// Purpose: Return the localized string for `financeAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccount => '口座';

  /// Purpose: Return the localized string for `financeFromAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFromAccount => '振替元口座';

  /// Purpose: Return the localized string for `financeToAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeToAccount => '振替先口座';

  /// Purpose: Return the localized string for `financeCurrency`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCurrency => '通貨';

  /// Purpose: Return the localized string for `financeDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeDate => '日付';

  /// Purpose: Return the localized string for `financeNoTransactions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoTransactions => '取引なし';

  /// Purpose: Return the localized string for `financeForceBalance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeForceBalance => '残高を固定';

  /// Purpose: Return the localized string for `financeCurrentBalance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCurrentBalance => '現在の残高';

  /// Purpose: Return the localized string for `financeAddAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAddAccount => '口座を追加';

  /// Purpose: Return the localized string for `financeEditAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEditAccount => '口座を編集';

  /// Purpose: Return the localized string for `financeAddCategory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAddCategory => 'カテゴリを追加';

  /// Purpose: Return the localized string for `financeEditCategory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEditCategory => 'カテゴリを編集';

  /// Purpose: Return the localized string for `financeName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeName => '名前';

  /// Purpose: Return the localized string for `financeBankApp`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBankApp => '銀行 / アプリ';

  /// Purpose: Return the localized string for `financeCardNumber`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCardNumber => 'カード番号（任意）';

  /// Purpose: Return the localized string for `financeExpiry`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeExpiry => '有効期限';

  /// Purpose: Return the localized string for `financeSecurityCode`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSecurityCode => 'セキュリティコード';

  /// Purpose: Return the localized string for `financeIcon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeIcon => 'アイコン';

  /// Purpose: Return the localized string for `financeEmoji`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEmoji => '絵文字';

  /// Purpose: Return the localized string for `financeCategoryHintExpense`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCategoryHintExpense => '例: 食費、交通費';

  /// Purpose: Return the localized string for `financeCategoryHintIncome`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCategoryHintIncome => '例: 給料、投資';

  /// Purpose: Return the localized string for `financeThisTransaction`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeThisTransaction => 'この取引';

  /// Purpose: Return the localized string for `financeNoAccounts`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoAccounts => '口座なし';

  /// Purpose: Return the localized string for `financeNoCategories`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoCategories => 'カテゴリなし';

  /// Purpose: Return the localized string for `financeByYear`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeByYear => '年別';

  /// Purpose: Return the localized string for `financeByMonth`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeByMonth => '月別';

  /// Purpose: Return the localized string for `financeByDay`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeByDay => '日別';

  /// Purpose: Return the localized string for `financeCustomRange`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCustomRange => 'カスタム範囲';

  /// Purpose: Return the localized string for `financeExpenseTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeExpenseTrend => '支出推移';

  /// Purpose: Return the localized string for `financeIncomeTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeIncomeTrend => '収入推移';

  /// Purpose: Return the localized string for `financeAssetsTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAssetsTrend => '資産推移';

  /// Purpose: Return the localized string for `financeThisCategory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeThisCategory => 'このカテゴリ';

  /// Purpose: Implement the finance no categories of type behavior for this file.
  /// Inputs: `type`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeNoCategoriesOfType(String type) {
    return '$typeカテゴリなし';
  }

  /// Purpose: Return the localized string for `financeImportDefaults`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeImportDefaults => 'デフォルトをインポート';

  /// Purpose: Return the localized string for `financeCatFood`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatFood => '食費';

  /// Purpose: Return the localized string for `financeCatTransport`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatTransport => '交通費';

  /// Purpose: Return the localized string for `financeCatShopping`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatShopping => '買い物';

  /// Purpose: Return the localized string for `financeCatRent`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatRent => '家賃';

  /// Purpose: Return the localized string for `financeCatDigital`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatDigital => 'デジタル';

  /// Purpose: Return the localized string for `financeCatEntertainment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatEntertainment => '娯楽';

  /// Purpose: Return the localized string for `financeCatHealthcare`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatHealthcare => '医療';

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
  String get financeCatSalary => '給料';

  /// Purpose: Return the localized string for `financeCatBonus`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatBonus => 'ボーナス';

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
  String get financeCatFreelance => 'フリーランス';

  /// Purpose: Return the localized string for `intimacyTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTitle => 'プライベート記録';

  /// Purpose: Return the localized string for `intimacyNewRecord`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNewRecord => '新規記録';

  /// Purpose: Return the localized string for `intimacyEditRecord`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyEditRecord => '記録を編集';

  /// Purpose: Return the localized string for `intimacySolo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySolo => 'ソロ';

  /// Purpose: Return the localized string for `intimacyPartner`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPartner => 'パートナー';

  /// Purpose: Return the localized string for `intimacyPartners`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPartners => 'パートナー';

  /// Purpose: Return the localized string for `intimacyAddPartner`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyAddPartner => 'パートナーを追加';

  /// Purpose: Return the localized string for `intimacyEditPartner`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyEditPartner => 'パートナーを編集';

  /// Purpose: Return the localized string for `intimacyToys`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyToys => 'トイ';

  /// Purpose: Return the localized string for `intimacyAddToy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyAddToy => 'トイを追加';

  /// Purpose: Return the localized string for `intimacyEditToy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyEditToy => 'トイを編集';

  /// Purpose: Return the localized string for `intimacyPleasure`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPleasure => '満足度';

  /// Purpose: Return the localized string for `intimacyDuration`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyDuration => '時間';

  /// Purpose: Return the localized string for `intimacyLocation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyLocation => '場所（任意）';

  /// Purpose: Return the localized string for `intimacyNotes`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNotes => 'メモ（任意）';

  /// Purpose: Return the localized string for `intimacyOrgasm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyOrgasm => 'オーガズムあり？';

  /// Purpose: Return the localized string for `intimacyWatchedPorn`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyWatchedPorn => 'ポルノ視聴？';

  /// Purpose: Return the localized string for `intimacyTimer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimer => 'タイマー';

  /// Purpose: Return the localized string for `intimacyNoRecords`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNoRecords => '記録なし';

  /// Purpose: Return the localized string for `intimacyNoPartners`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNoPartners => 'パートナーなし';

  /// Purpose: Return the localized string for `intimacyNoToys`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNoToys => 'トイなし';

  /// Purpose: Return the localized string for `intimacyNoPartnersHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNoPartnersHint => 'パートナーなし — 設定から追加してください';

  /// Purpose: Return the localized string for `intimacyShowAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyShowAll => 'すべて表示';

  /// Purpose: Return the localized string for `intimacyShowAllRecords`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyShowAllRecords => 'すべての記録を表示';

  /// Purpose: Return the localized string for `intimacyAllRecords`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyAllRecords => '全記録';

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
  String get intimacyPause => '一時停止';

  /// Purpose: Return the localized string for `intimacyResume`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyResume => '再開';

  /// Purpose: Return the localized string for `intimacyStopSave`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyStopSave => '停止して保存';

  /// Purpose: Return the localized string for `intimacyReset`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyReset => 'リセット';

  /// Purpose: Return the localized string for `intimacyTimerStartedAt`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerStartedAt => '開始時刻';

  /// Purpose: Return the localized string for `intimacyTimerHistory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerHistory => '履歴';

  /// Purpose: Return the localized string for `intimacyTimerClearHistory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerClearHistory => 'クリア';

  /// Purpose: Return the localized string for `intimacyTimerRetention3d`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerRetention3d => '3日間';

  /// Purpose: Return the localized string for `intimacyTimerRetention7d`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerRetention7d => '7日間';

  /// Purpose: Return the localized string for `intimacyTimerRetention14d`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerRetention14d => '14日間';

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
  String get intimacyModuleVisible => '表示中';

  /// Purpose: Return the localized string for `intimacyModuleHidden`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyModuleHidden => '非表示';

  /// Purpose: Return the localized string for `intimacySortNewest`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortNewest => '新しい順';

  /// Purpose: Return the localized string for `intimacySortOldest`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortOldest => '古い順';

  /// Purpose: Return the localized string for `intimacySortPleasure`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortPleasure => '快感度順';

  /// Purpose: Return the localized string for `intimacySortDuration`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortDuration => '時間順';

  /// Purpose: Return the localized string for `intimacyFilterAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFilterAll => 'すべて';

  /// Purpose: Return the localized string for `intimacyFilterSolo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFilterSolo => 'ソロ';

  /// Purpose: Return the localized string for `intimacyFilterPartnered`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFilterPartnered => 'パートナーと';

  /// Purpose: Return the localized string for `intimacyFilterOrgasm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFilterOrgasm => 'オーガズムあり';

  /// Purpose: Return the localized string for `intimacyFilterNoOrgasm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFilterNoOrgasm => 'オーガズムなし';

  /// Purpose: Return the localized string for `intimacyExportCsv`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyExportCsv => 'CSVエクスポート';

  /// Purpose: Return the localized string for `intimacyExportCsvSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyExportCsvSuccess => 'CSVエクスポート完了';

  /// Purpose: Return the localized string for `intimacyExportCsvEmpty`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyExportCsvEmpty => 'エクスポートする記録がありません';

  /// Purpose: Return the localized string for `intimacyStartDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyStartDate => '交際開始';

  /// Purpose: Return the localized string for `intimacyEndDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyEndDate => '交際終了';

  /// Purpose: Return the localized string for `intimacyPurchaseDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPurchaseDate => '購入日';

  /// Purpose: Return the localized string for `intimacyRetiredDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyRetiredDate => '引退日';

  /// Purpose: Return the localized string for `intimacyBreakUp`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyBreakUp => '別れる';

  /// Purpose: Return the localized string for `intimacyRetire`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyRetire => '引退';

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
  String get settingsLanguage => '言語';

  /// Purpose: Return the localized string for `settingsTheme`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsTheme => 'テーマ';

  /// Purpose: Return the localized string for `settingsThemeSystem`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsThemeSystem => 'システム';

  /// Purpose: Return the localized string for `settingsThemeLight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsThemeLight => 'ライト';

  /// Purpose: Return the localized string for `settingsThemeDark`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsThemeDark => 'ダーク';

  /// Purpose: Return the localized string for `settingsPrivacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsPrivacy => 'プライバシー';

  /// Purpose: Return the localized string for `settingsIntimacyModule`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsIntimacyModule => 'プライベートモジュール';

  /// Purpose: Return the localized string for `settingsData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsData => 'データ';

  /// Purpose: Return the localized string for `settingsStorageLocation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsStorageLocation => '保存場所';

  /// Purpose: Return the localized string for `settingsStoragePathHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsStoragePathHint => 'データ保存先のディレクトリパスを入力。空欄でデフォルトを使用。';

  /// Purpose: Return the localized string for `settingsDirectoryPath`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsDirectoryPath => 'ディレクトリパス';

  /// Purpose: Return the localized string for `settingsResetDefault`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsResetDefault => 'デフォルトに戻す';

  /// Purpose: Return the localized string for `settingsResetDefaultLocation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsResetDefaultLocation => 'デフォルトの保存場所に戻しました';

  /// Purpose: Return the localized string for `settingsStoragePathUpdated`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsStoragePathUpdated => '保存パスを更新しました';

  /// Purpose: Return the localized string for `settingsOpenDataFolder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsOpenDataFolder => 'データフォルダを開く';

  /// Purpose: Return the localized string for `settingsOpenDataFolderDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsOpenDataFolderDesc => 'アプリケーションデータディレクトリを開く';

  /// Purpose: Return the localized string for `settingsWebDAVSync`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVSync => 'WebDAV 同期';

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
  String get settingsWebDAVConfigured => '設定済み';

  /// Purpose: Return the localized string for `settingsWebDAVServerURL`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVServerURL => 'サーバーURL';

  /// Purpose: Return the localized string for `settingsWebDAVUsername`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVUsername => 'ユーザー名';

  /// Purpose: Return the localized string for `settingsWebDAVPassword`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVPassword => 'パスワード';

  /// Purpose: Return the localized string for `settingsWebDAVRemotePath`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVRemotePath => 'リモートパス';

  /// Purpose: Return the localized string for `settingsWebDAVTestConnection`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVTestConnection => '接続テスト';

  /// Purpose: Return the localized string for `settingsWebDAVConnectionSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConnectionSuccess => '接続成功';

  /// Purpose: Return the localized string for `settingsWebDAVConnectionFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConnectionFailed => '接続失敗';

  /// Purpose: Return the localized string for `settingsWebDAVSyncNow`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVSyncNow => '今すぐ同期';

  /// Purpose: Return the localized string for `settingsWebDAVAutoSync`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVAutoSync => '自動同期';

  /// Purpose: Return the localized string for `settingsWebDAVAutoSyncDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVAutoSyncDesc => '編集後やアプリ復帰時に自動で同期します';

  /// Purpose: Return the localized string for `settingsWebDAVSyncing`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVSyncing => '同期中...';

  /// Purpose: Return the localized string for `settingsWebDAVSyncSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVSyncSuccess => '同期完了';

  /// Purpose: Return the localized string for `settingsWebDAVSyncFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVSyncFailed => '同期失敗';

  /// Purpose: Return the localized string for `settingsWebDAVConflictTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConflictTitle => '同期の競合';

  /// Purpose: Return the localized string for `settingsWebDAVConflictDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConflictDesc =>
      '以下のレコードがローカルとリモートの両方で変更されています。それぞれ保持するバージョンを選択してください：';

  /// Purpose: Return the localized string for `settingsWebDAVKeepLocal`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVKeepLocal => 'ローカルを保持';

  /// Purpose: Return the localized string for `settingsWebDAVKeepRemote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVKeepRemote => 'リモートを保持';

  /// Purpose: Return the localized string for `settingsWebDAVConflictApply`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConflictApply => '適用';

  /// Purpose: Return the localized string for `settingsWebDAVNextcloud`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVNextcloud => 'Nextcloud プリセット';

  /// Purpose: Return the localized string for `settingsWebDAVCustom`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVCustom => 'カスタムサーバー';

  /// Purpose: Return the localized string for `settingsImportExport`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportExport => 'インポート/エクスポート';

  /// Purpose: Return the localized string for `settingsExportJSON`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportJSON => 'ZIP エクスポート';

  /// Purpose: Return the localized string for `settingsExportCSV`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportCSV => 'CSV エクスポート';

  /// Purpose: Return the localized string for `csvExportFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportFinance => '財務 CSV エクスポート';

  /// Purpose: Return the localized string for `csvExportFinanceDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportFinanceDesc => '財務取引を平文で出力';

  /// Purpose: Return the localized string for `csvExportIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportIntimacy => 'プライベート CSV エクスポート';

  /// Purpose: Return the localized string for `csvExportIntimacyDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportIntimacyDesc => 'プライベート記録を平文で出力';

  /// Purpose: Return the localized string for `csvExportWeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportWeight => '体重 CSV エクスポート';

  /// Purpose: Return the localized string for `csvExportWeightDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportWeightDesc => '体重記録を平文で出力';

  /// Purpose: Return the localized string for `settingsImport`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImport => 'ファイルからインポート';

  /// Purpose: Return the localized string for `settingsExportSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportSuccess => 'エクスポート成功';

  /// Purpose: Return the localized string for `settingsExportFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportFailed => 'エクスポート失敗';

  /// Purpose: Return the localized string for `settingsImportSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportSuccess => 'インポート成功';

  /// Purpose: Return the localized string for `settingsImportFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportFailed => 'インポート失敗';

  /// Purpose: Return the localized string for `settingsImportConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportConfirm => 'すべてのデータが置き換えられます。続行しますか？';

  /// Purpose: Return the localized string for `settingsExportCSVWarning`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportCSVWarning => 'CSVデータは平文でエクスポートされます。続行しますか？';

  /// Purpose: Return the localized string for `settingsAbout`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsAbout => '情報';

  /// Purpose: Return the localized string for `settingsAboutTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsAboutTitle => 'MyDay!!!!! について';

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
  String get commonDiscard => '破棄';

  /// Purpose: Return the localized string for `commonDiscardChangesTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonDiscardChangesTitle => '変更を破棄しますか？';

  /// Purpose: Return the localized string for `commonDiscardChangesMessage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonDiscardChangesMessage => '保存されていない変更があります。破棄して閉じますか？';

  /// Purpose: Return the localized string for `commonCancel`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonCancel => 'キャンセル';

  /// Purpose: Return the localized string for `commonDelete`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonDelete => '削除';

  /// Purpose: Return the localized string for `commonEdit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonEdit => '編集';

  /// Purpose: Return the localized string for `commonAdd`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonAdd => '追加';

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
  String get commonYes => 'はい';

  /// Purpose: Return the localized string for `commonNo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonNo => 'いいえ';

  /// Purpose: Return the localized string for `commonOk`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonOk => 'OK';

  /// Purpose: Return the localized string for `commonClose`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonClose => '閉じる';

  /// Purpose: Return the localized string for `commonName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonName => '名前';

  /// Purpose: Return the localized string for `commonEmojiOptional`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonEmojiOptional => '絵文字（任意）';

  /// Purpose: Return the localized string for `commonOptional`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonOptional => '任意';

  /// Purpose: Implement the common delete confirm behavior for this file.
  /// Inputs: `item`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String commonDeleteConfirm(String item) {
    return '$itemを削除しますか？';
  }

  /// Purpose: Implement the common minutes behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String commonMinutes(int count) {
    return '$count分';
  }

  /// Purpose: Return the localized string for `settingsExportSection`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportSection => 'エクスポート';

  /// Purpose: Return the localized string for `settingsImportSection`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportSection => 'インポート';

  /// Purpose: Return the localized string for `settingsExportFullBackup`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportFullBackup => '全データの完全バックアップ';

  /// Purpose: Return the localized string for `settingsExportJSONPlaintext`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportJSONPlaintext => '全データがZIPアーカイブとしてエクスポートされます';

  /// Purpose: Return the localized string for `settingsExportCSVPlaintext`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportCSVPlaintext => '財務取引を平文で出力';

  /// Purpose: Return the localized string for `settingsImportRestore`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportRestore => 'ZIPバックアップから復元';

  /// Purpose: Return the localized string for `settingsImportData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportData => 'データをインポート';

  /// Purpose: Return the localized string for `csvImportFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportFinance => '財務 CSV インポート';

  /// Purpose: Return the localized string for `csvImportFinanceDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportFinanceDesc => 'CSV から取引をマージ（既存データは上書きされません）';

  /// Purpose: Return the localized string for `csvImportIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportIntimacy => 'プライベート CSV インポート';

  /// Purpose: Return the localized string for `csvImportIntimacyDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportIntimacyDesc => 'CSV から記録をマージ（既存データは上書きされません）';

  /// Purpose: Return the localized string for `csvImportConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportConfirm => 'CSV データは既存の記録にマージされます。続行しますか？';

  /// Purpose: Implement the csv import success behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String csvImportSuccess(int count) {
    return '$count 件のレコードをインポートしました';
  }

  /// Purpose: Return the localized string for `csvImportFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportFailed => 'CSV インポート失敗';

  /// Purpose: Return the localized string for `csvImportEmpty`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportEmpty => 'CSV に有効なレコードが見つかりません';

  /// Purpose: Return the localized string for `csvTemplate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvTemplate => 'CSV テンプレート';

  /// Purpose: Return the localized string for `csvTemplateFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvTemplateFinance => '財務テンプレートをダウンロード';

  /// Purpose: Return the localized string for `csvTemplateIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvTemplateIntimacy => 'プライベートテンプレートをダウンロード';

  /// Purpose: Return the localized string for `csvTemplateSaved`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvTemplateSaved => 'テンプレートを保存しました';

  /// Purpose: Return the localized string for `settingsWebDAVDisconnect`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVDisconnect => '接続解除';

  /// Purpose: Return the localized string for `settingsWebDAVConfigSaved`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConfigSaved => '設定を保存しました';

  /// Purpose: Return the localized string for `settingsWebDAVConfigRemoved`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConfigRemoved => '設定を削除しました';

  /// Purpose: Return the localized string for `commonDontAskMinutes`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonDontAskMinutes => '5分間確認しない';

  /// Purpose: Return the localized string for `intimacyHideConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyHideConfirm => 'モジュールを非表示にしてもデータは削除されません。いつでも再度有効にできます。';

  /// Purpose: Return the localized string for `settingsLicense`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsLicense => 'ライセンス (GPLv3)';

  /// Purpose: Return the localized string for `settingsLicenses`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsLicenses => 'オープンソースライセンス';

  /// Purpose: Return the localized string for `settingsPrivacyPolicy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsPrivacyPolicy => 'プライバシーポリシー';

  /// Purpose: Return the localized string for `settingsDesktop`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsDesktop => 'デスクトップ';

  /// Purpose: Return the localized string for `settingsMinimizeToTray`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsMinimizeToTray => 'トレイに最小化';

  /// Purpose: Return the localized string for `settingsCloseToTray`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsCloseToTray => 'トレイに閉じる';

  /// Purpose: Return the localized string for `financeBankPresets`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBankPresets => '銀行プリセット';

  /// Purpose: Return the localized string for `financeBankSearch`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBankSearch => '銀行またはアプリを検索...';

  /// Purpose: Return the localized string for `financeBankNoResults`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBankNoResults => '該当する銀行が見つかりません';

  /// Purpose: Return the localized string for `financeSubscriptions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSubscriptions => 'サブスクリプション';

  /// Purpose: Return the localized string for `financeSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSubscription => 'サブスク';

  /// Purpose: Return the localized string for `financeAddSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAddSubscription => 'サブスクを追加';

  /// Purpose: Return the localized string for `financeEditSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEditSubscription => 'サブスクを編集';

  /// Purpose: Return the localized string for `financeStartDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeStartDate => '開始日';

  /// Purpose: Return the localized string for `financeTrialDays`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTrialDays => '試用日数';

  /// Purpose: Return the localized string for `financeBillingCycle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBillingCycle => '請求サイクル';

  /// Purpose: Return the localized string for `financeBillingCycleMonthly`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBillingCycleMonthly => '月次';

  /// Purpose: Return the localized string for `financeBillingCycleYearly`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBillingCycleYearly => '年次';

  /// Purpose: Implement the finance every x months behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeEveryXMonths(int count) {
    return '$count ヶ月ごと';
  }

  /// Purpose: Implement the finance every x years behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeEveryXYears(int count) {
    return '$count 年ごと';
  }

  /// Purpose: Return the localized string for `financeBillingDay`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBillingDay => '請求日';

  /// Purpose: Return the localized string for `financeBillingMonth`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBillingMonth => '請求月';

  /// Purpose: Return the localized string for `financeMonthlyDue`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeMonthlyDue => '月額';

  /// Purpose: Return the localized string for `financeMonthlyAvg`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeMonthlyAvg => '月平均';

  /// Purpose: Return the localized string for `financeYearlyAvg`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeYearlyAvg => '年平均';

  /// Purpose: Return the localized string for `financeNoSubscriptions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoSubscriptions => 'サブスクなし';

  /// Purpose: Return the localized string for `financeActiveSubscriptions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeActiveSubscriptions => '有効';

  /// Purpose: Return the localized string for `financeHistoricalSubscriptions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeHistoricalSubscriptions => '履歴';

  /// Purpose: Return the localized string for `financeCancelSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCancelSubscription => 'サブスクを解約';

  /// Purpose: Return the localized string for `financeCancelImmediate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCancelImmediate => '今すぐ解約';

  /// Purpose: Return the localized string for `financeCancelAtExpiry`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCancelAtExpiry => '期限で解約';

  /// Purpose: Return the localized string for `financeNextBilling`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNextBilling => '次の請求';

  /// Purpose: Return the localized string for `financeExpiryDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeExpiryDate => '有効期限';

  /// Purpose: Return the localized string for `financeTotalSpent`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTotalSpent => '累計支出';

  /// Purpose: Return the localized string for `financeImportHistory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeImportHistory => '過去の取引をインポート';

  /// Purpose: Return the localized string for `financeImportHistoryDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeImportHistoryDesc => '開始日が今日より前です。過去の取引をインポートしますか？';

  /// Purpose: Return the localized string for `financeThisSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeThisSubscription => 'このサブスク';

  /// Purpose: Implement the finance cancelled on behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeCancelledOn(String date) {
    return '$date に解約済み';
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
  String get financeImage => '画像';

  /// Purpose: Return the localized string for `financePickImage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financePickImage => '画像を選択';

  /// Purpose: Return the localized string for `financeChangeImage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeChangeImage => '変更';

  /// Purpose: Return the localized string for `financeUpcomingRenewals`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeUpcomingRenewals => '更新予定';

  /// Purpose: Return the localized string for `financeSubscriptionReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSubscriptionReminder => 'サブスクリプションリマインダー';

  /// Purpose: Return the localized string for `financeReminderTime`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeReminderTime => '通知時刻';

  /// Purpose: Return the localized string for `financeReminderEnabled`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeReminderEnabled => '更新予定のサブスクリプションを通知';

  /// Purpose: Implement the finance subscription due soon behavior for this file.
  /// Inputs: `name`, `days`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeSubscriptionDueSoon(String name, int days) {
    return '$name は$days日後に更新予定';
  }

  /// Purpose: Implement the finance subscription due today behavior for this file.
  /// Inputs: `name`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeSubscriptionDueToday(String name) {
    return '$name は今日更新予定';
  }

  /// Purpose: Return the localized string for `financeSortBy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortBy => '並べ替え';

  /// Purpose: Return the localized string for `financeSortByRenewal`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortByRenewal => '更新日順';

  /// Purpose: Return the localized string for `financeSortByName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortByName => '名前順';

  /// Purpose: Return the localized string for `financeSortByBank`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortByBank => '銀行 / アプリ順';

  /// Purpose: Return the localized string for `financeSortCustom`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortCustom => 'カスタム';

  /// Purpose: Return the localized string for `financeSortReorder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortReorder => '並べ替え';

  /// Purpose: Return the localized string for `financeSortDone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortDone => '完了';

  /// Purpose: Return the localized string for `financeRestoreSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeRestoreSubscription => 'サブスクリプションを復元';

  /// Purpose: Return the localized string for `backupTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupTitle => 'バックアップ';

  /// Purpose: Return the localized string for `backupLocalOnlyNote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupLocalOnlyNote =>
      'バックアップはこのデバイスのみに保存されます。クラウドバックアップにはWebDAV同期をご利用ください。';

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
  String get backupAutoDaily => '毎日自動バックアップ';

  /// Purpose: Return the localized string for `backupAutoDailyDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupAutoDailyDesc => '毎日自動的にバックアップを作成';

  /// Purpose: Return the localized string for `backupRetention`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRetention => 'バックアップ保持';

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
    return '$count日間';
  }

  /// Purpose: Return the localized string for `backupManual`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupManual => '手動バックアップ';

  /// Purpose: Return the localized string for `backupCreateNow`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupCreateNow => '今すぐバックアップ';

  /// Purpose: Implement the backup history behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String backupHistory(int count) {
    return 'バックアップ履歴 ($count)';
  }

  /// Purpose: Return the localized string for `backupEmpty`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupEmpty => 'バックアップなし';

  /// Purpose: Return the localized string for `backupCreated`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupCreated => 'バックアップ作成成功';

  /// Purpose: Return the localized string for `backupFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupFailed => 'バックアップ失敗';

  /// Purpose: Return the localized string for `backupRestore`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestore => '復元';

  /// Purpose: Return the localized string for `backupRestoreConfirmTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreConfirmTitle => '復元確認';

  /// Purpose: Return the localized string for `backupRestoreConfirmDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreConfirmDesc => '選択したモジュールのデータが置き換えられます。続行しますか？';

  /// Purpose: Return the localized string for `backupRestoreSelectModules`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreSelectModules => '復元するモジュールを選択';

  /// Purpose: Return the localized string for `backupRestoreAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreAll => '全モジュール';

  /// Purpose: Return the localized string for `backupRestoreSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreSuccess => '復元成功。アプリを再起動してください。';

  /// Purpose: Return the localized string for `backupRestoreFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreFailed => '復元失敗';

  /// Purpose: Return the localized string for `backupDeleteConfirmTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupDeleteConfirmTitle => 'バックアップ削除';

  /// Purpose: Return the localized string for `backupDeleteConfirmDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupDeleteConfirmDesc => 'このバックアップは完全に削除されます。';

  /// Purpose: Return the localized string for `backupModuleTodo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupModuleTodo => 'Todo';

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
  String get backupModuleRates => '為替レート';

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
    return '$count 件の記録';
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
  String get weightSetHeight => '身長を設定';

  /// Purpose: Return the localized string for `weightNoRecords`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightNoRecords => '体重記録がありません';

  /// Purpose: Return the localized string for `weightAddRecord`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightAddRecord => '記録を追加';

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
  String get weightHeightCm => '身長（cm）';

  /// Purpose: Return the localized string for `weightNote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightNote => 'メモ';

  /// Purpose: Return the localized string for `weightNoteHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightNoteHint => '任意のメモ';

  /// Purpose: Return the localized string for `weightChart`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightChart => '推移';

  /// Purpose: Return the localized string for `weightAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightAll => '全期間';

  /// Purpose: Return the localized string for `weightHistory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightHistory => '履歴';

  /// Purpose: Return the localized string for `weightShowAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightShowAll => 'すべての記録を表示';

  /// Purpose: Return the localized string for `weightDays`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightDays => '日';

  /// Purpose: Return the localized string for `weightDaysAgo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightDaysAgo => '日前';

  /// Purpose: Return the localized string for `weightWeeksAgo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightWeeksAgo => '週間前';

  /// Purpose: Return the localized string for `weightToday`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightToday => '今日';

  /// Purpose: Return the localized string for `weightYesterday`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightYesterday => '昨日';

  /// Purpose: Return the localized string for `weightRecent`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightRecent => '最近';

  /// Purpose: Return the localized string for `weightExportCsv`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightExportCsv => 'CSVエクスポート';

  /// Purpose: Return the localized string for `weightExportCsvSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightExportCsvSuccess => '体重データをエクスポートしました';

  /// Purpose: Return the localized string for `weightExportCsvEmpty`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightExportCsvEmpty => 'エクスポートする体重記録がありません';

  /// Purpose: Return the localized string for `csvImportWeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportWeight => '体重 CSV インポート';

  /// Purpose: Return the localized string for `csvImportWeightDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportWeightDesc => 'CSVから体重記録を統合（日付、時刻、体重）';

  /// Purpose: Return the localized string for `csvTemplateWeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvTemplateWeight => '体重テンプレートをダウンロード';

  /// Purpose: Return the localized string for `financeSubscriptionPresets`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSubscriptionPresets => 'クイック入力';

  /// Purpose: Return the localized string for `intimacyPurchaseLink`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPurchaseLink => '購入リンク';

  /// Purpose: Return the localized string for `intimacyPrice`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPrice => '価格';

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
  String get intimacyAddPosition => '体位を追加';

  /// Purpose: Return the localized string for `intimacyEditPosition`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyEditPosition => '体位を編集';

  /// Purpose: Return the localized string for `intimacyNoPositions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNoPositions => '体位がありません';

  /// Purpose: Return the localized string for `intimacyImportDefaults`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyImportDefaults => 'デフォルトをインポート';

  /// Purpose: Return the localized string for `intimacyTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTrend => 'トレンド';

  /// Purpose: Return the localized string for `intimacyFrequency`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFrequency => '頻度';

  /// Purpose: Return the localized string for `intimacyChartNoData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyChartNoData => 'データ不足';

  /// Purpose: Return the localized string for `weightTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightTrend => 'トレンド';

  /// Purpose: Return the localized string for `weightRaw`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightRaw => '実測';

  /// Purpose: Return the localized string for `weightReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminder => '体重リマインダー';

  /// Purpose: Return the localized string for `weightReminderNone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderNone => 'リマインダーなし';

  /// Purpose: Return the localized string for `weightReminderOnce`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderOnce => '1日１回';

  /// Purpose: Return the localized string for `weightReminderTwice`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderTwice => '1日２回（朝・夜）';

  /// Purpose: Return the localized string for `weightReminderMorning`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderMorning => '朝';

  /// Purpose: Return the localized string for `weightReminderEvening`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderEvening => '夜';

  /// Purpose: Return the localized string for `weightReminderSkipWindow`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderSkipWindow => '記録済みならスキップ';

  /// Purpose: Implement the weight reminder skip window value behavior for this file.
  /// Inputs: `hours`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String weightReminderSkipWindowValue(String hours) {
    return 'リマインダー前 $hours 時間以内';
  }

  /// Purpose: Return the localized string for `weightReminderSkipWindowHours`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderSkipWindowHours => 'リマインダー前の時間';

  /// Purpose: Return the localized string for `commonChange`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonChange => '変更';

  /// Purpose: Return the localized string for `commonPickImage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonPickImage => '画像を選択';

  /// Purpose: Return the localized string for `commonRemoveIcon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonRemoveIcon => 'アイコンを削除';

  /// Purpose: Return the localized string for `commonPickIcon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonPickIcon => 'アイコンを選択';

  /// Purpose: Return the localized string for `commonNoData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonNoData => 'データなし';

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
  String get todoDailyReminders => '毎日リマインダー';

  /// Purpose: Return the localized string for `todoRemindReviewHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoRemindReviewHint => 'Todoリストを確認するリマインダー';

  /// Purpose: Return the localized string for `todoRemindUndoneHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoRemindUndoneHint => '未完了タスクのリマインダー';

  /// Purpose: Return the localized string for `todoTapReturnToday`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoTapReturnToday => 'タップで今日に戻る';

  /// Purpose: Return the localized string for `todoCalendar`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCalendar => 'カレンダー';

  /// Purpose: Return the localized string for `todoWeekMon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekMon => '月';

  /// Purpose: Return the localized string for `todoWeekTue`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekTue => '火';

  /// Purpose: Return the localized string for `todoWeekWed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekWed => '水';

  /// Purpose: Return the localized string for `todoWeekThu`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekThu => '木';

  /// Purpose: Return the localized string for `todoWeekFri`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekFri => '金';

  /// Purpose: Return the localized string for `todoWeekSat`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekSat => '土';

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
  String get todoCalendarSomeDaily => '一部完了';

  /// Purpose: Return the localized string for `todoCalendarAllDaily`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCalendarAllDaily => '日課全完了';

  /// Purpose: Return the localized string for `todoCalendarAllDone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCalendarAllDone => '全完了';

  /// Purpose: Return the localized string for `todoWhatNeedsDone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWhatNeedsDone => '何をする必要がありますか？';

  /// Purpose: Implement the todo reminder at behavior for this file.
  /// Inputs: `time`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoReminderAt(String time) {
    return 'リマインダー：$time';
  }

  /// Purpose: Return the localized string for `todoAddReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoAddReminder => 'リマインダーを追加（任意）';

  /// Purpose: Implement the todo scheduled at behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoScheduledAt(String date) {
    return '予定：$date';
  }

  /// Purpose: Return the localized string for `todoSetScheduledDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSetScheduledDate => '予定日を設定';

  /// Purpose: Implement the todo completed at behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoCompletedAt(String date) {
    return '完了：$date';
  }

  /// Purpose: Return the localized string for `todoSetCompletedDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSetCompletedDate => '完了日を設定';

  /// Purpose: Return the localized string for `todoSortBy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSortBy => '並べ替え';

  /// Purpose: Return the localized string for `todoSortByAdded`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSortByAdded => '追加日時順';

  /// Purpose: Return the localized string for `todoSortByDueDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSortByDueDate => '期限順';

  /// Purpose: Return the localized string for `todoSortByName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSortByName => '名前順';

  /// Purpose: Return the localized string for `todoSortCustom`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSortCustom => 'カスタム';

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
  String get positionMissionary => '正常位';

  /// Purpose: Return the localized string for `positionCowgirl`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionCowgirl => '騎乗位';

  /// Purpose: Return the localized string for `positionDoggyStyle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionDoggyStyle => 'バック';

  /// Purpose: Return the localized string for `positionReverseCowgirl`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionReverseCowgirl => '背面騎乗位';

  /// Purpose: Return the localized string for `positionSpooning`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionSpooning => '横向き';

  /// Purpose: Return the localized string for `positionStanding`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionStanding => '立位';

  /// Purpose: Return the localized string for `position69`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get position69 => '69';

  /// Purpose: Return the localized string for `positionLotus`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionLotus => '蓮華座';

  /// Purpose: Return the localized string for `positionProneBone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionProneBone => 'うつ伏せ';

  /// Purpose: Return the localized string for `notifTodoMorning`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get notifTodoMorning => 'おはようございます！Todoリストを確認しましょう 📝';

  /// Purpose: Return the localized string for `notifTodoCompletion`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get notifTodoCompletion => '今日の残りのタスクを完了しましょう！';

  /// Purpose: Implement the notif todo uncompleted behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String notifTodoUncompleted(int count) {
    return '今日はまだ $count 件のタスクが未完了です！';
  }

  /// Purpose: Return the localized string for `notifWeightReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get notifWeightReminder => '体重を記録しましょう！⚖️';

  /// Purpose: Implement the notif upcoming renewals behavior for this file.
  /// Inputs: `list`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String notifUpcomingRenewals(String list) {
    return '更新予定：$list';
  }

  /// Purpose: Implement the notif subscription today behavior for this file.
  /// Inputs: `name`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String notifSubscriptionToday(String name) {
    return '$name（今日）';
  }

  /// Purpose: Implement the notif subscription days behavior for this file.
  /// Inputs: `name`, `days`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String notifSubscriptionDays(String name, int days) {
    return '$name（$days日後）';
  }

  /// Purpose: Return the localized string for `trayShow`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get trayShow => '表示';

  /// Purpose: Return the localized string for `trayQuit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get trayQuit => '終了';

  /// Purpose: Return the localized string for `filePickerExportLocation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get filePickerExportLocation => 'エクスポート先を選択';

  /// Purpose: Return the localized string for `filePickerBackupFile`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get filePickerBackupFile => 'バックアップファイルを選択';

  /// Purpose: Return the localized string for `filePickerCsvFile`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get filePickerCsvFile => 'CSVファイルを選択';

  /// Purpose: Return the localized string for `filePickerSaveTemplate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get filePickerSaveTemplate => 'テンプレートの保存先';

  /// Purpose: Return the localized string for `financeBalance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBalance => '残高';

  /// Purpose: Return the localized string for `financeNewAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNewAccount => '新規口座';

  /// Purpose: Return the localized string for `financeAccountTypeFund`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountTypeFund => '普通';

  /// Purpose: Return the localized string for `financeAccountTypeCredit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountTypeCredit => 'クレジット';

  /// Purpose: Return the localized string for `financeAccountTypeRecharge`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountTypeRecharge => 'チャージ';

  /// Purpose: Return the localized string for `financeAccountTypeFinancial`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountTypeFinancial => '投資';

  /// Purpose: Return the localized string for `financeAccountName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountName => '口座名';

  /// Purpose: Return the localized string for `financeBankAppHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBankAppHint => '例：三菱UFJ、PayPay';

  /// Purpose: Return the localized string for `financeCardNumberHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCardNumberHint => '下4桁';

  /// Purpose: Return the localized string for `financeFeeWaiverConditions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverConditions => '月額管理手数料の免除条件';

  /// Purpose: Return the localized string for `financeFeeWaiverConditionsHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverConditionsHint => '月額管理手数料を避けるための任意条件です。';

  /// Purpose: Return the localized string for `financeFeeWaiverMinimumBalance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverMinimumBalance => '最低残高';

  /// Purpose: Return the localized string for `financeFeeWaiverMinimumBalanceHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverMinimumBalanceHint => '例：1500';

  /// Purpose: Return the localized string for `financeFeeWaiverMonthlyDeposit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverMonthlyDeposit => '毎月入金額';

  /// Purpose: Return the localized string for `financeFeeWaiverMonthlyDepositHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverMonthlyDepositHint => '例：500';

  /// Purpose: Return the localized string for `financeFeeWaiverSeparator`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverSeparator => ' または ';

  /// Purpose: Return the localized string for `financeCurrentBalanceHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCurrentBalanceHint => '空欄の場合取引から計算';

  /// Purpose: Return the localized string for `financeAsOfToday`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAsOfToday => '今日時点';

  /// Purpose: Return the localized string for `financeBalanceEffectiveDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBalanceEffectiveDate => '残高基準日';

  /// Purpose: Return the localized string for `financeFetchIcon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFetchIcon => 'アイコンを取得';

  /// Purpose: Return the localized string for `financeAccountsCategories`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountsCategories => '口座とカテゴリ';

  /// Purpose: Return the localized string for `financeEditRate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEditRate => '為替レートを編集';

  /// Purpose: Return the localized string for `financeNewRate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNewRate => '新規為替レート';

  /// Purpose: Return the localized string for `financeFrom`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFrom => '変換元';

  /// Purpose: Return the localized string for `financeTo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTo => '変換先';

  /// Purpose: Return the localized string for `financeRate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeRate => 'レート';

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
  String get financeNoRates => '為替レート未設定';

  /// Purpose: Return the localized string for `financeNoExpenseData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoExpenseData => 'この期間の支出データなし';

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
  String get financeSelectDateRange => '日付範囲を選択';

  /// Purpose: Return the localized string for `financeNoTransactionData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoTransactionData => 'この期間の取引データなし';

  /// Purpose: Implement the finance received amount behavior for this file.
  /// Inputs: `currency`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeReceivedAmount(String currency) {
    return '入金額 ($currency)';
  }

  /// Purpose: Return the localized string for `financeReceivedAmountHelper`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeReceivedAmountHelper => '先方口座の通貨での入金額';

  /// Purpose: Return the localized string for `financeNoteHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoteHint => '何のため？';

  /// Purpose: Return the localized string for `financeThisAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeThisAccount => 'この口座';

  /// Purpose: Return the localized string for `commonThisRecord`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonThisRecord => 'この記録';

  /// Purpose: Return the localized string for `financeBalanceAdjustment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBalanceAdjustment => '残高調整';

  /// Purpose: Return the localized string for `financeCatCreditCardPayment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatCreditCardPayment => 'クレジットカード決済';

  /// Purpose: Return the localized string for `financeCatFixedDeposit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatFixedDeposit => '定期預金満期';

  /// Purpose: Return the localized string for `financeCatInternalTransfer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatInternalTransfer => '内部振替';

  /// Purpose: Return the localized string for `financeCatLoanRepayment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatLoanRepayment => 'ローン返済';

  /// Purpose: Return the localized string for `financeCatInvestmentTransfer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatInvestmentTransfer => '投資振替';

  /// Purpose: Return the localized string for `financeCatReimburse`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatReimburse => '立替精算';

  /// Purpose: Return the localized string for `settingsAutoStart`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsAutoStart => '起動時に自動起動';

  /// Purpose: Return the localized string for `settingsApiEnabled`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiEnabled => 'ローカル API サーバー';

  /// Purpose: Return the localized string for `settingsApiServer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiServer => 'API サーバー設定';

  /// Purpose: Implement the settings api running behavior for this file.
  /// Inputs: `port`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String settingsApiRunning(int port) {
    return 'ポート $port で実行中';
  }

  /// Purpose: Return the localized string for `settingsApiStopped`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiStopped => '停止中';

  /// Purpose: Return the localized string for `settingsApiNeedCredentials`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiNeedCredentials => 'ローカル以外のアクセスには認証が必要';

  /// Purpose: Implement the settings api restarted behavior for this file.
  /// Inputs: `port`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String settingsApiRestarted(int port) {
    return 'API サーバーをポート $port で再起動しました';
  }

  /// Purpose: Return the localized string for `settingsApiListenAddress`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiListenAddress => 'リッスンアドレス';

  /// Purpose: Return the localized string for `settingsApiPort`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiPort => 'ポート';

  /// Purpose: Return the localized string for `settingsApiUsername`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiUsername => 'ユーザー名';

  /// Purpose: Return the localized string for `settingsApiPassword`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiPassword => 'パスワード';

  /// Purpose: Return the localized string for `todoRecurrence`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoRecurrence => '繰り返し';

  /// Purpose: Return the localized string for `todoRecurrenceNone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoRecurrenceNone => 'なし';

  /// Purpose: Implement the todo recurrence every n days behavior for this file.
  /// Inputs: `n`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoRecurrenceEveryNDays(int n) {
    return '$n日ごと';
  }

  /// Purpose: Implement the todo recurrence monthly on day behavior for this file.
  /// Inputs: `n`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoRecurrenceMonthlyOnDay(int n) {
    return '毎月$n日';
  }

  /// Purpose: Implement the todo recurrence yearly on date behavior for this file.
  /// Inputs: `month`, `day`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoRecurrenceYearlyOnDate(int month, int day) {
    return '毎年$month/$day';
  }

  /// Purpose: Return the localized string for `todoNextOccurrence`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoNextOccurrence => '次の発生をスケジュール';

  /// Purpose: Return the localized string for `intimacyActivePartners`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyActivePartners => '現役パートナー';

  /// Purpose: Return the localized string for `intimacyPastPartners`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPastPartners => '過去のパートナー';

  /// Purpose: Return the localized string for `intimacyActiveToys`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyActiveToys => '現役トイ';

  /// Purpose: Return the localized string for `intimacyRetiredToys`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyRetiredToys => '引退済みトイ';

  /// Purpose: Return the localized string for `intimacySortByRelationshipDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortByRelationshipDate => '交際開始日順';

  /// Purpose: Return the localized string for `intimacySortByPurchaseDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortByPurchaseDate => '購入日順';

  /// Purpose: Return the localized string for `intimacySortByUseCount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortByUseCount => '使用回数順';
}
