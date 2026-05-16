// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get navTodo => 'Todo';

  /// Purpose: Return the localized string for `navFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get navFinance => 'Finance';

  /// Purpose: Return the localized string for `navWeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get navWeight => 'Weight';

  /// Purpose: Return the localized string for `navIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get navIntimacy => 'Intimacy';

  /// Purpose: Return the localized string for `navSettings`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get navSettings => 'Settings';

  /// Purpose: Return the localized string for `todoSectionDaily`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSectionDaily => 'Daily';

  /// Purpose: Return the localized string for `todoSectionRoutine`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSectionRoutine => 'Routine';

  /// Purpose: Return the localized string for `todoSectionWork`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSectionWork => 'Work';

  /// Purpose: Return the localized string for `todoAddTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoAddTask => 'Add Task';

  /// Purpose: Return the localized string for `todoEditTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoEditTask => 'Edit Task';

  /// Purpose: Return the localized string for `todoTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoTitle => 'Title';

  /// Purpose: Return the localized string for `todoNote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoNote => 'Note';

  /// Purpose: Return the localized string for `todoNoteHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoNoteHint => 'Add an optional note';

  /// Purpose: Return the localized string for `todoSubtasks`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSubtasks => 'Subtasks';

  /// Purpose: Return the localized string for `todoAddSubtask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoAddSubtask => 'Add Subtask';

  /// Purpose: Return the localized string for `todoReminderTime`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoReminderTime => 'Reminder Time';

  /// Purpose: Return the localized string for `todoNoTasks`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoNoTasks => 'No tasks';

  /// Purpose: Return the localized string for `todoType`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoType => 'Type';

  /// Purpose: Return the localized string for `todoEmoji`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoEmoji => 'Emoji';

  /// Purpose: Return the localized string for `todoDailyTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoDailyTask => 'Daily';

  /// Purpose: Return the localized string for `todoRoutineTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoRoutineTask => 'Routine Once';

  /// Purpose: Return the localized string for `todoWorkTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWorkTask => 'Work Once';

  /// Purpose: Implement the todo created date behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoCreatedDate(String date) {
    return 'Created: $date';
  }

  /// Purpose: Implement the todo start date behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoStartDate(String date) {
    return 'Start Date: $date';
  }

  /// Purpose: Implement the todo deleted date behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoDeletedDate(String date) {
    return 'Deleted: $date';
  }

  /// Purpose: Return the localized string for `todoPermanentDelete`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoPermanentDelete => 'Permanently Delete';

  /// Purpose: Return the localized string for `todoPermanentDeleteConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoPermanentDeleteConfirm =>
      'This will permanently remove this task and all its history. Continue?';

  /// Purpose: Return the localized string for `todoMorningReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoMorningReminder => 'Morning Plan Reminder';

  /// Purpose: Return the localized string for `todoCompletionReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCompletionReminder => 'Completion Check Reminder';

  /// Purpose: Return the localized string for `todoSetReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSetReminder => 'Set Reminder';

  /// Purpose: Return the localized string for `todoClearReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoClearReminder => 'Clear';

  /// Purpose: Implement the todo reminder set behavior for this file.
  /// Inputs: `time`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoReminderSet(String time) {
    return 'Reminder set for $time';
  }

  /// Purpose: Return the localized string for `todoCompleted`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCompleted => 'Completed';

  /// Purpose: Return the localized string for `todoDueDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoDueDate => 'Due';

  /// Purpose: Return the localized string for `todoSetDueDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSetDueDate => 'Set due date (optional)';

  /// Purpose: Return the localized string for `todoCustomEmoji`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCustomEmoji => 'Custom Emoji';

  /// Purpose: Return the localized string for `todoCustomEmojiHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCustomEmojiHint => 'Enter an emoji';

  /// Purpose: Return the localized string for `todoEditSubtask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoEditSubtask => 'Edit Subtask';

  /// Purpose: Implement the todo subtasks progress behavior for this file.
  /// Inputs: `done`, `total`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoSubtasksProgress(int done, int total) {
    return 'Subtasks: $done/$total';
  }

  /// Purpose: Implement the todo task due behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoTaskDue(String date) {
    return 'Due: $date';
  }

  /// Purpose: Implement the todo task note behavior for this file.
  /// Inputs: `note`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoTaskNote(String note) {
    return 'Note: $note';
  }

  /// Purpose: Return the localized string for `todoThisTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoThisTask => 'this task';

  /// Purpose: Return the localized string for `financeTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTitle => 'Finance';

  /// Purpose: Return the localized string for `financeMonthlyExpense`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeMonthlyExpense => 'Monthly Expense';

  /// Purpose: Return the localized string for `financeTotalAssets`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTotalAssets => 'Total Assets';

  /// Purpose: Return the localized string for `financeAccounts`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccounts => 'Accounts';

  /// Purpose: Return the localized string for `financeCategories`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCategories => 'Categories';

  /// Purpose: Return the localized string for `financeTrends`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTrends => 'Trends';

  /// Purpose: Return the localized string for `financeAnalysis`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAnalysis => 'Analysis';

  /// Purpose: Return the localized string for `financeExchangeRates`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeExchangeRates => 'Exchange Rates';

  /// Purpose: Return the localized string for `financeRefreshRates`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeRefreshRates => 'Refresh Rates';

  /// Purpose: Return the localized string for `financeAddTransaction`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAddTransaction => 'Add Transaction';

  /// Purpose: Return the localized string for `financeEditTransaction`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEditTransaction => 'Edit Transaction';

  /// Purpose: Return the localized string for `financeExpense`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeExpense => 'Expense';

  /// Purpose: Return the localized string for `financeIncome`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeIncome => 'Income';

  /// Purpose: Return the localized string for `financeTransfer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTransfer => 'Transfer';

  /// Purpose: Return the localized string for `financeAmount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAmount => 'Amount';

  /// Purpose: Return the localized string for `financeNote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNote => 'Note';

  /// Purpose: Return the localized string for `financeCategory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCategory => 'Category';

  /// Purpose: Return the localized string for `financeAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccount => 'Account';

  /// Purpose: Return the localized string for `financeFromAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFromAccount => 'From Account';

  /// Purpose: Return the localized string for `financeToAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeToAccount => 'To Account';

  /// Purpose: Return the localized string for `financeCurrency`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCurrency => 'Currency';

  /// Purpose: Return the localized string for `financeDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeDate => 'Date';

  /// Purpose: Return the localized string for `financeNoTransactions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoTransactions => 'No transactions';

  /// Purpose: Return the localized string for `financeForceBalance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeForceBalance => 'Force Balance';

  /// Purpose: Return the localized string for `financeCurrentBalance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCurrentBalance => 'Current Balance';

  /// Purpose: Return the localized string for `financeAddAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAddAccount => 'Add Account';

  /// Purpose: Return the localized string for `financeEditAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEditAccount => 'Edit Account';

  /// Purpose: Return the localized string for `financeAddCategory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAddCategory => 'Add Category';

  /// Purpose: Return the localized string for `financeEditCategory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEditCategory => 'Edit Category';

  /// Purpose: Return the localized string for `financeName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeName => 'Name';

  /// Purpose: Return the localized string for `financeBankApp`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBankApp => 'Bank / App';

  /// Purpose: Return the localized string for `financeCardNumber`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCardNumber => 'Card Number (optional)';

  /// Purpose: Return the localized string for `financeExpiry`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeExpiry => 'Expiry';

  /// Purpose: Return the localized string for `financeSecurityCode`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSecurityCode => 'Security Code';

  /// Purpose: Return the localized string for `financeIcon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeIcon => 'Icon';

  /// Purpose: Return the localized string for `financeEmoji`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEmoji => 'Emoji';

  /// Purpose: Return the localized string for `financeCategoryHintExpense`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCategoryHintExpense => 'e.g. Food, Transport';

  /// Purpose: Return the localized string for `financeCategoryHintIncome`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCategoryHintIncome => 'e.g. Salary, Investment';

  /// Purpose: Return the localized string for `financeThisTransaction`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeThisTransaction => 'this transaction';

  /// Purpose: Return the localized string for `financeNoAccounts`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoAccounts => 'No accounts yet';

  /// Purpose: Return the localized string for `financeNoCategories`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoCategories => 'No categories yet';

  /// Purpose: Return the localized string for `financeByYear`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeByYear => 'By Year';

  /// Purpose: Return the localized string for `financeByMonth`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeByMonth => 'By Month';

  /// Purpose: Return the localized string for `financeByDay`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeByDay => 'By Day';

  /// Purpose: Return the localized string for `financeCustomRange`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCustomRange => 'Custom Range';

  /// Purpose: Return the localized string for `financeExpenseTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeExpenseTrend => 'Expense Trend';

  /// Purpose: Return the localized string for `financeIncomeTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeIncomeTrend => 'Income Trend';

  /// Purpose: Return the localized string for `financeAssetsTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAssetsTrend => 'Assets Trend';

  /// Purpose: Return the localized string for `financeThisCategory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeThisCategory => 'this category';

  /// Purpose: Implement the finance no categories of type behavior for this file.
  /// Inputs: `type`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeNoCategoriesOfType(String type) {
    return 'No $type categories';
  }

  /// Purpose: Return the localized string for `financeImportDefaults`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeImportDefaults => 'Import Defaults';

  /// Purpose: Return the localized string for `financeCatFood`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatFood => 'Food';

  /// Purpose: Return the localized string for `financeCatTransport`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatTransport => 'Transport';

  /// Purpose: Return the localized string for `financeCatShopping`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatShopping => 'Shopping';

  /// Purpose: Return the localized string for `financeCatRent`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatRent => 'Rent';

  /// Purpose: Return the localized string for `financeCatDigital`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatDigital => 'Digital';

  /// Purpose: Return the localized string for `financeCatEntertainment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatEntertainment => 'Entertainment';

  /// Purpose: Return the localized string for `financeCatHealthcare`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatHealthcare => 'Healthcare';

  /// Purpose: Return the localized string for `financeCatEducation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatEducation => 'Education';

  /// Purpose: Return the localized string for `financeCatSalary`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatSalary => 'Salary';

  /// Purpose: Return the localized string for `financeCatBonus`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatBonus => 'Bonus';

  /// Purpose: Return the localized string for `financeCatInvestment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatInvestment => 'Investment';

  /// Purpose: Return the localized string for `financeCatFreelance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatFreelance => 'Freelance';

  /// Purpose: Return the localized string for `intimacyTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTitle => 'Intimacy';

  /// Purpose: Return the localized string for `intimacyNewRecord`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNewRecord => 'New Record';

  /// Purpose: Return the localized string for `intimacyEditRecord`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyEditRecord => 'Edit Record';

  /// Purpose: Return the localized string for `intimacySolo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySolo => 'Solo';

  /// Purpose: Return the localized string for `intimacyPartner`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPartner => 'Partner';

  /// Purpose: Return the localized string for `intimacyPartners`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPartners => 'Partners';

  /// Purpose: Return the localized string for `intimacyAddPartner`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyAddPartner => 'Add Partner';

  /// Purpose: Return the localized string for `intimacyEditPartner`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyEditPartner => 'Edit Partner';

  /// Purpose: Return the localized string for `intimacyToys`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyToys => 'Toys';

  /// Purpose: Return the localized string for `intimacyAddToy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyAddToy => 'Add Toy';

  /// Purpose: Return the localized string for `intimacyEditToy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyEditToy => 'Edit Toy';

  /// Purpose: Return the localized string for `intimacyPleasure`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPleasure => 'Pleasure';

  /// Purpose: Return the localized string for `intimacyDuration`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyDuration => 'Duration';

  /// Purpose: Return the localized string for `intimacyLocation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyLocation => 'Location (optional)';

  /// Purpose: Return the localized string for `intimacyNotes`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNotes => 'Notes (optional)';

  /// Purpose: Return the localized string for `intimacyOrgasm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyOrgasm => 'Had Orgasm?';

  /// Purpose: Return the localized string for `intimacyWatchedPorn`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyWatchedPorn => 'Watched Porn?';

  /// Purpose: Return the localized string for `intimacyTimer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimer => 'Timer';

  /// Purpose: Return the localized string for `intimacyNoRecords`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNoRecords => 'No records';

  /// Purpose: Return the localized string for `intimacyNoPartners`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNoPartners => 'No partners yet';

  /// Purpose: Return the localized string for `intimacyNoToys`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNoToys => 'No toys yet';

  /// Purpose: Return the localized string for `intimacyNoPartnersHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNoPartnersHint => 'No partners — add one in Settings';

  /// Purpose: Return the localized string for `intimacyShowAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyShowAll => 'Show all';

  /// Purpose: Return the localized string for `intimacyAllRecords`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyAllRecords => 'All Records';

  /// Purpose: Return the localized string for `intimacyStart`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyStart => 'Start';

  /// Purpose: Return the localized string for `intimacyPause`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPause => 'Pause';

  /// Purpose: Return the localized string for `intimacyResume`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyResume => 'Resume';

  /// Purpose: Return the localized string for `intimacyStopSave`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyStopSave => 'Stop & Save';

  /// Purpose: Return the localized string for `intimacyReset`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyReset => 'Reset';

  /// Purpose: Return the localized string for `intimacyTimerStartedAt`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerStartedAt => 'Started at';

  /// Purpose: Return the localized string for `intimacyTimerHistory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerHistory => 'History';

  /// Purpose: Return the localized string for `intimacyTimerClearHistory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerClearHistory => 'Clear';

  /// Purpose: Return the localized string for `intimacyTimerRetention3d`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerRetention3d => '3 days';

  /// Purpose: Return the localized string for `intimacyTimerRetention7d`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerRetention7d => '7 days';

  /// Purpose: Return the localized string for `intimacyTimerRetention14d`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerRetention14d => '14 days';

  /// Purpose: Return the localized string for `intimacyTimerRetentionForever`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTimerRetentionForever => 'Forever';

  /// Purpose: Return the localized string for `intimacyManage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyManage => 'Manage';

  /// Purpose: Return the localized string for `intimacyModuleVisible`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyModuleVisible => 'Visible';

  /// Purpose: Return the localized string for `intimacyModuleHidden`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyModuleHidden => 'Hidden';

  /// Purpose: Return the localized string for `intimacySortNewest`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortNewest => 'Newest first';

  /// Purpose: Return the localized string for `intimacySortOldest`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortOldest => 'Oldest first';

  /// Purpose: Return the localized string for `intimacySortPleasure`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortPleasure => 'Highest pleasure';

  /// Purpose: Return the localized string for `intimacySortDuration`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortDuration => 'Longest duration';

  /// Purpose: Return the localized string for `intimacyFilterAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFilterAll => 'All';

  /// Purpose: Return the localized string for `intimacyFilterSolo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFilterSolo => 'Solo';

  /// Purpose: Return the localized string for `intimacyFilterPartnered`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFilterPartnered => 'With partner';

  /// Purpose: Return the localized string for `intimacyFilterOrgasm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFilterOrgasm => 'Had orgasm';

  /// Purpose: Return the localized string for `intimacyFilterNoOrgasm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFilterNoOrgasm => 'No orgasm';

  /// Purpose: Return the localized string for `intimacyExportCsv`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyExportCsv => 'Export CSV';

  /// Purpose: Return the localized string for `intimacyExportCsvSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyExportCsvSuccess => 'CSV exported successfully';

  /// Purpose: Return the localized string for `intimacyExportCsvEmpty`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyExportCsvEmpty => 'No records to export';

  /// Purpose: Return the localized string for `intimacyStartDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyStartDate => 'Start Date';

  /// Purpose: Return the localized string for `intimacyEndDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyEndDate => 'End Date';

  /// Purpose: Return the localized string for `intimacyPurchaseDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPurchaseDate => 'Purchase Date';

  /// Purpose: Return the localized string for `intimacyRetiredDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyRetiredDate => 'Retired Date';

  /// Purpose: Return the localized string for `intimacyBreakUp`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyBreakUp => 'Break Up';

  /// Purpose: Return the localized string for `intimacyRetire`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyRetire => 'Retire';

  /// Purpose: Return the localized string for `settingsTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsTitle => 'Settings';

  /// Purpose: Return the localized string for `settingsGeneral`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsGeneral => 'General';

  /// Purpose: Return the localized string for `settingsLanguage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsLanguage => 'Language';

  /// Purpose: Return the localized string for `settingsTheme`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsTheme => 'Theme';

  /// Purpose: Return the localized string for `settingsThemeSystem`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsThemeSystem => 'System';

  /// Purpose: Return the localized string for `settingsThemeLight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsThemeLight => 'Light';

  /// Purpose: Return the localized string for `settingsThemeDark`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsThemeDark => 'Dark';

  /// Purpose: Return the localized string for `settingsPrivacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsPrivacy => 'Privacy';

  /// Purpose: Return the localized string for `settingsIntimacyModule`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsIntimacyModule => 'Intimacy Module';

  /// Purpose: Return the localized string for `settingsData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsData => 'Data';

  /// Purpose: Return the localized string for `settingsStorageLocation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsStorageLocation => 'Storage Location';

  /// Purpose: Return the localized string for `settingsStoragePathHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsStoragePathHint =>
      'Enter the directory path for storing data. Leave empty to use default.';

  /// Purpose: Return the localized string for `settingsDirectoryPath`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsDirectoryPath => 'Directory Path';

  /// Purpose: Return the localized string for `settingsResetDefault`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsResetDefault => 'Reset to Default';

  /// Purpose: Return the localized string for `settingsResetDefaultLocation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsResetDefaultLocation => 'Reset to default location';

  /// Purpose: Return the localized string for `settingsStoragePathUpdated`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsStoragePathUpdated => 'Storage path updated';

  /// Purpose: Return the localized string for `settingsOpenDataFolder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsOpenDataFolder => 'Open Data Folder';

  /// Purpose: Return the localized string for `settingsOpenDataFolderDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsOpenDataFolderDesc =>
      'Open the application data directory';

  /// Purpose: Return the localized string for `settingsWebDAVSync`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVSync => 'WebDAV Sync';

  /// Purpose: Return the localized string for `settingsWebDAVNotConfigured`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVNotConfigured => 'Not configured';

  /// Purpose: Return the localized string for `settingsWebDAVConfigured`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConfigured => 'Configured';

  /// Purpose: Return the localized string for `settingsWebDAVServerURL`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVServerURL => 'Server URL';

  /// Purpose: Return the localized string for `settingsWebDAVUsername`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVUsername => 'Username';

  /// Purpose: Return the localized string for `settingsWebDAVPassword`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVPassword => 'Password';

  /// Purpose: Return the localized string for `settingsWebDAVRemotePath`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVRemotePath => 'Remote Path';

  /// Purpose: Return the localized string for `settingsWebDAVTestConnection`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVTestConnection => 'Test Connection';

  /// Purpose: Return the localized string for `settingsWebDAVConnectionSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConnectionSuccess => 'Connection successful';

  /// Purpose: Return the localized string for `settingsWebDAVConnectionFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConnectionFailed => 'Connection failed';

  /// Purpose: Return the localized string for `settingsWebDAVSyncNow`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVSyncNow => 'Sync Now';

  /// Purpose: Return the localized string for `settingsWebDAVAutoSync`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVAutoSync => 'Auto Sync';

  /// Purpose: Return the localized string for `settingsWebDAVAutoSyncDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVAutoSyncDesc =>
      'Automatically sync after editing and when the app resumes';

  /// Purpose: Return the localized string for `settingsWebDAVSyncing`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVSyncing => 'Syncing...';

  /// Purpose: Return the localized string for `settingsWebDAVSyncSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVSyncSuccess => 'Sync completed';

  /// Purpose: Return the localized string for `settingsWebDAVSyncFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVSyncFailed => 'Sync failed';

  /// Purpose: Return the localized string for `settingsWebDAVConflictTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConflictTitle => 'Sync Conflicts';

  /// Purpose: Return the localized string for `settingsWebDAVConflictDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConflictDesc =>
      'Both local and remote have changes for the following records. Choose which version to keep for each:';

  /// Purpose: Return the localized string for `settingsWebDAVKeepLocal`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVKeepLocal => 'Keep Local';

  /// Purpose: Return the localized string for `settingsWebDAVKeepRemote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVKeepRemote => 'Keep Remote';

  /// Purpose: Return the localized string for `settingsWebDAVConflictApply`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConflictApply => 'Apply';

  /// Purpose: Return the localized string for `settingsWebDAVNextcloud`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVNextcloud => 'Nextcloud Preset';

  /// Purpose: Return the localized string for `settingsWebDAVCustom`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVCustom => 'Custom Server';

  /// Purpose: Return the localized string for `settingsImportExport`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportExport => 'Import / Export';

  /// Purpose: Return the localized string for `settingsExportJSON`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportJSON => 'Export ZIP';

  /// Purpose: Return the localized string for `settingsExportCSV`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportCSV => 'Export CSV';

  /// Purpose: Return the localized string for `csvExportFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportFinance => 'Export Finance CSV';

  /// Purpose: Return the localized string for `csvExportFinanceDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportFinanceDesc => 'Finance transactions as plaintext';

  /// Purpose: Return the localized string for `csvExportIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportIntimacy => 'Export Intimacy CSV';

  /// Purpose: Return the localized string for `csvExportIntimacyDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportIntimacyDesc => 'Intimacy records as plaintext';

  /// Purpose: Return the localized string for `csvExportWeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportWeight => 'Export Weight CSV';

  /// Purpose: Return the localized string for `csvExportWeightDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvExportWeightDesc => 'Weight records as plaintext';

  /// Purpose: Return the localized string for `settingsImport`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImport => 'Import from File';

  /// Purpose: Return the localized string for `settingsExportSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportSuccess => 'Exported successfully';

  /// Purpose: Return the localized string for `settingsExportFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportFailed => 'Export failed';

  /// Purpose: Return the localized string for `settingsImportSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportSuccess => 'Imported successfully';

  /// Purpose: Return the localized string for `settingsImportFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportFailed => 'Import failed';

  /// Purpose: Return the localized string for `settingsImportConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportConfirm =>
      'This will replace all current data. Continue?';

  /// Purpose: Return the localized string for `settingsExportCSVWarning`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportCSVWarning =>
      'CSV data will be exported as plaintext. Continue?';

  /// Purpose: Return the localized string for `settingsAbout`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsAbout => 'About';

  /// Purpose: Return the localized string for `settingsAboutTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsAboutTitle => 'About MyDay!!!!!';

  /// Purpose: Return the localized string for `commonSave`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonSave => 'Save';

  /// Purpose: Return the localized string for `commonDiscard`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonDiscard => 'Discard';

  /// Purpose: Return the localized string for `commonDiscardChangesTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonDiscardChangesTitle => 'Discard changes?';

  /// Purpose: Return the localized string for `commonDiscardChangesMessage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonDiscardChangesMessage =>
      'You have unsaved changes. Discard them and close?';

  /// Purpose: Return the localized string for `commonCancel`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonCancel => 'Cancel';

  /// Purpose: Return the localized string for `commonDelete`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonDelete => 'Delete';

  /// Purpose: Return the localized string for `commonEdit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonEdit => 'Edit';

  /// Purpose: Return the localized string for `commonAdd`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonAdd => 'Add';

  /// Purpose: Return the localized string for `commonConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonConfirm => 'Confirm';

  /// Purpose: Return the localized string for `commonYes`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonYes => 'Yes';

  /// Purpose: Return the localized string for `commonNo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonNo => 'No';

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
  String get commonClose => 'Close';

  /// Purpose: Return the localized string for `commonName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonName => 'Name';

  /// Purpose: Return the localized string for `commonEmojiOptional`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonEmojiOptional => 'Emoji (optional)';

  /// Purpose: Return the localized string for `commonOptional`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonOptional => 'optional';

  /// Purpose: Implement the common delete confirm behavior for this file.
  /// Inputs: `item`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String commonDeleteConfirm(String item) {
    return 'Delete $item?';
  }

  /// Purpose: Implement the common minutes behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String commonMinutes(int count) {
    return '${count}min';
  }

  /// Purpose: Return the localized string for `settingsExportSection`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportSection => 'Export';

  /// Purpose: Return the localized string for `settingsImportSection`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportSection => 'Import';

  /// Purpose: Return the localized string for `settingsExportFullBackup`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportFullBackup => 'Full backup of all data';

  /// Purpose: Return the localized string for `settingsExportJSONPlaintext`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportJSONPlaintext =>
      'All data will be exported as a ZIP archive';

  /// Purpose: Return the localized string for `settingsExportCSVPlaintext`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsExportCSVPlaintext => 'Finance transactions as plaintext';

  /// Purpose: Return the localized string for `settingsImportRestore`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportRestore => 'Restore from ZIP backup';

  /// Purpose: Return the localized string for `settingsImportData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsImportData => 'Import Data';

  /// Purpose: Return the localized string for `csvImportFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportFinance => 'Import Finance CSV';

  /// Purpose: Return the localized string for `csvImportFinanceDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportFinanceDesc =>
      'Merge transactions from CSV (will not overwrite existing data)';

  /// Purpose: Return the localized string for `csvImportIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportIntimacy => 'Import Intimacy CSV';

  /// Purpose: Return the localized string for `csvImportIntimacyDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportIntimacyDesc =>
      'Merge records from CSV (will not overwrite existing data)';

  /// Purpose: Return the localized string for `csvImportConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportConfirm =>
      'CSV data will be merged into existing records. Continue?';

  /// Purpose: Implement the csv import success behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String csvImportSuccess(int count) {
    return 'Imported $count records successfully';
  }

  /// Purpose: Return the localized string for `csvImportFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportFailed => 'CSV import failed';

  /// Purpose: Return the localized string for `csvImportEmpty`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportEmpty => 'No valid records found in CSV';

  /// Purpose: Return the localized string for `csvTemplate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvTemplate => 'CSV Templates';

  /// Purpose: Return the localized string for `csvTemplateFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvTemplateFinance => 'Download Finance Template';

  /// Purpose: Return the localized string for `csvTemplateIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvTemplateIntimacy => 'Download Intimacy Template';

  /// Purpose: Return the localized string for `csvTemplateSaved`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvTemplateSaved => 'Template saved';

  /// Purpose: Return the localized string for `settingsWebDAVDisconnect`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVDisconnect => 'Disconnect';

  /// Purpose: Return the localized string for `settingsWebDAVConfigSaved`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConfigSaved => 'Configuration saved';

  /// Purpose: Return the localized string for `settingsWebDAVConfigRemoved`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsWebDAVConfigRemoved => 'Configuration removed';

  /// Purpose: Return the localized string for `commonDontAskMinutes`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonDontAskMinutes => 'Don\'t ask for 5 minutes';

  /// Purpose: Return the localized string for `intimacyHideConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyHideConfirm =>
      'Hiding the module will not delete your data. You can re-enable it anytime.';

  /// Purpose: Return the localized string for `settingsLicense`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsLicense => 'License (GPLv3)';

  /// Purpose: Return the localized string for `settingsLicenses`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsLicenses => 'Open Source Licenses';

  /// Purpose: Return the localized string for `settingsPrivacyPolicy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  /// Purpose: Return the localized string for `settingsDesktop`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsDesktop => 'Desktop';

  /// Purpose: Return the localized string for `settingsMinimizeToTray`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsMinimizeToTray => 'Minimize to Tray';

  /// Purpose: Return the localized string for `settingsCloseToTray`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsCloseToTray => 'Close to Tray';

  /// Purpose: Return the localized string for `financeBankPresets`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBankPresets => 'Bank Presets';

  /// Purpose: Return the localized string for `financeBankSearch`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBankSearch => 'Search bank or app...';

  /// Purpose: Return the localized string for `financeBankNoResults`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBankNoResults => 'No matching banks found';

  /// Purpose: Return the localized string for `financeSubscriptions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSubscriptions => 'Subscriptions';

  /// Purpose: Return the localized string for `financeSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSubscription => 'Subscription';

  /// Purpose: Return the localized string for `financeAddSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAddSubscription => 'Add Subscription';

  /// Purpose: Return the localized string for `financeEditSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEditSubscription => 'Edit Subscription';

  /// Purpose: Return the localized string for `financeStartDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeStartDate => 'Start Date';

  /// Purpose: Return the localized string for `financeTrialDays`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTrialDays => 'Trial Days';

  /// Purpose: Return the localized string for `financeBillingCycle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBillingCycle => 'Billing Cycle';

  /// Purpose: Return the localized string for `financeBillingCycleMonthly`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBillingCycleMonthly => 'Monthly';

  /// Purpose: Return the localized string for `financeBillingCycleYearly`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBillingCycleYearly => 'Yearly';

  /// Purpose: Implement the finance every x months behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeEveryXMonths(int count) {
    return 'Every $count month(s)';
  }

  /// Purpose: Implement the finance every x years behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeEveryXYears(int count) {
    return 'Every $count year(s)';
  }

  /// Purpose: Return the localized string for `financeBillingDay`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBillingDay => 'Billing Day';

  /// Purpose: Return the localized string for `financeBillingMonth`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBillingMonth => 'Billing Month';

  /// Purpose: Return the localized string for `financeMonthlyDue`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeMonthlyDue => 'Monthly Due';

  /// Purpose: Return the localized string for `financeMonthlyAvg`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeMonthlyAvg => 'Monthly Avg';

  /// Purpose: Return the localized string for `financeYearlyAvg`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeYearlyAvg => 'Yearly Avg';

  /// Purpose: Return the localized string for `financeNoSubscriptions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoSubscriptions => 'No subscriptions';

  /// Purpose: Return the localized string for `financeActiveSubscriptions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeActiveSubscriptions => 'Active';

  /// Purpose: Return the localized string for `financeHistoricalSubscriptions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeHistoricalSubscriptions => 'History';

  /// Purpose: Return the localized string for `financeCancelSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCancelSubscription => 'Cancel Subscription';

  /// Purpose: Return the localized string for `financeCancelImmediate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCancelImmediate => 'Cancel Now';

  /// Purpose: Return the localized string for `financeCancelAtExpiry`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCancelAtExpiry => 'Cancel at Expiry';

  /// Purpose: Return the localized string for `financeNextBilling`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNextBilling => 'Next Billing';

  /// Purpose: Return the localized string for `financeExpiryDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeExpiryDate => 'Expiry';

  /// Purpose: Return the localized string for `financeTotalSpent`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTotalSpent => 'Total Spent';

  /// Purpose: Return the localized string for `financeImportHistory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeImportHistory => 'Import Historical Transactions';

  /// Purpose: Return the localized string for `financeImportHistoryDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeImportHistoryDesc =>
      'Start date is before today. Import historical transactions?';

  /// Purpose: Return the localized string for `financeThisSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeThisSubscription => 'this subscription';

  /// Purpose: Implement the finance cancelled on behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeCancelledOn(String date) {
    return 'Cancelled $date';
  }

  /// Purpose: Return the localized string for `financeInterval`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeInterval => 'Interval';

  /// Purpose: Return the localized string for `financeImage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeImage => 'Image';

  /// Purpose: Return the localized string for `financePickImage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financePickImage => 'Pick Image';

  /// Purpose: Return the localized string for `financeChangeImage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeChangeImage => 'Change';

  /// Purpose: Return the localized string for `financeUpcomingRenewals`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeUpcomingRenewals => 'Upcoming Renewals';

  /// Purpose: Return the localized string for `financeSubscriptionReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSubscriptionReminder => 'Subscription Reminder';

  /// Purpose: Return the localized string for `financeReminderTime`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeReminderTime => 'Notification Time';

  /// Purpose: Return the localized string for `financeReminderEnabled`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeReminderEnabled => 'Notify upcoming renewals';

  /// Purpose: Implement the finance subscription due soon behavior for this file.
  /// Inputs: `name`, `days`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeSubscriptionDueSoon(String name, int days) {
    return '$name is due in $days day(s)';
  }

  /// Purpose: Implement the finance subscription due today behavior for this file.
  /// Inputs: `name`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeSubscriptionDueToday(String name) {
    return '$name is due today';
  }

  /// Purpose: Return the localized string for `financeSortBy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortBy => 'Sort';

  /// Purpose: Return the localized string for `financeSortByRenewal`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortByRenewal => 'By Renewal Date';

  /// Purpose: Return the localized string for `financeSortByName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortByName => 'By Name';

  /// Purpose: Return the localized string for `financeSortByBank`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortByBank => 'By Bank / App';

  /// Purpose: Return the localized string for `financeSortCustom`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortCustom => 'Custom';

  /// Purpose: Return the localized string for `financeSortReorder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortReorder => 'Reorder';

  /// Purpose: Return the localized string for `financeSortDone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSortDone => 'Done';

  /// Purpose: Return the localized string for `financeRestoreSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeRestoreSubscription => 'Restore';

  /// Purpose: Return the localized string for `backupTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupTitle => 'Backup';

  /// Purpose: Return the localized string for `backupLocalOnlyNote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupLocalOnlyNote =>
      'Backups are stored locally on this device only. Use WebDAV Sync for cloud backup.';

  /// Purpose: Return the localized string for `backupSettings`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupSettings => 'Settings';

  /// Purpose: Return the localized string for `backupAutoDaily`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupAutoDaily => 'Daily Auto-Backup';

  /// Purpose: Return the localized string for `backupAutoDailyDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupAutoDailyDesc => 'Automatically create backup once per day';

  /// Purpose: Return the localized string for `backupRetention`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRetention => 'Keep backups';

  /// Purpose: Return the localized string for `backupRetentionForever`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRetentionForever => 'Forever';

  /// Purpose: Implement the backup retention days behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String backupRetentionDays(int count) {
    return '$count days';
  }

  /// Purpose: Return the localized string for `backupManual`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupManual => 'Manual Backup';

  /// Purpose: Return the localized string for `backupCreateNow`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupCreateNow => 'Create Backup Now';

  /// Purpose: Implement the backup history behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String backupHistory(int count) {
    return 'Backups ($count)';
  }

  /// Purpose: Return the localized string for `backupEmpty`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupEmpty => 'No backups yet';

  /// Purpose: Return the localized string for `backupCreated`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupCreated => 'Backup created successfully';

  /// Purpose: Return the localized string for `backupFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupFailed => 'Backup failed';

  /// Purpose: Return the localized string for `backupRestore`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestore => 'Restore';

  /// Purpose: Return the localized string for `backupRestoreConfirmTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreConfirmTitle => 'Confirm Restore';

  /// Purpose: Return the localized string for `backupRestoreConfirmDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreConfirmDesc =>
      'This will replace selected module data. Continue?';

  /// Purpose: Return the localized string for `backupRestoreSelectModules`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreSelectModules => 'Select Modules to Restore';

  /// Purpose: Return the localized string for `backupRestoreAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreAll => 'All Modules';

  /// Purpose: Return the localized string for `backupRestoreSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreSuccess =>
      'Restore successful. Please restart the app.';

  /// Purpose: Return the localized string for `backupRestoreFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupRestoreFailed => 'Restore failed';

  /// Purpose: Return the localized string for `backupDeleteConfirmTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupDeleteConfirmTitle => 'Delete Backup';

  /// Purpose: Return the localized string for `backupDeleteConfirmDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupDeleteConfirmDesc =>
      'This backup will be permanently deleted.';

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
  String get backupModuleFinance => 'Finance';

  /// Purpose: Return the localized string for `backupModuleRates`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupModuleRates => 'Exchange Rates';

  /// Purpose: Return the localized string for `backupModuleIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get backupModuleIntimacy => 'Intimacy';

  /// Purpose: Implement the intimacy record count behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String intimacyRecordCount(int count) {
    return '$count records';
  }

  /// Purpose: Return the localized string for `weightTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightTitle => 'Weight';

  /// Purpose: Return the localized string for `weightSetHeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightSetHeight => 'Set Height';

  /// Purpose: Return the localized string for `weightNoRecords`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightNoRecords => 'No weight records yet';

  /// Purpose: Return the localized string for `weightAddRecord`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightAddRecord => 'Add Record';

  /// Purpose: Return the localized string for `weightKg`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightKg => 'Weight (kg)';

  /// Purpose: Return the localized string for `weightHeightCm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightHeightCm => 'Height (cm)';

  /// Purpose: Return the localized string for `weightNote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightNote => 'Note';

  /// Purpose: Return the localized string for `weightNoteHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightNoteHint => 'Optional note';

  /// Purpose: Return the localized string for `weightChart`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightChart => 'Trend';

  /// Purpose: Return the localized string for `weightAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightAll => 'All';

  /// Purpose: Return the localized string for `weightHistory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightHistory => 'History';

  /// Purpose: Return the localized string for `weightShowAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightShowAll => 'Show all records';

  /// Purpose: Return the localized string for `weightDays`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightDays => 'days';

  /// Purpose: Return the localized string for `weightDaysAgo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightDaysAgo => 'days ago';

  /// Purpose: Return the localized string for `weightWeeksAgo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightWeeksAgo => 'weeks ago';

  /// Purpose: Return the localized string for `weightToday`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightToday => 'Today';

  /// Purpose: Return the localized string for `weightYesterday`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightYesterday => 'Yesterday';

  /// Purpose: Return the localized string for `weightRecent`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightRecent => 'Recent';

  /// Purpose: Return the localized string for `weightExportCsv`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightExportCsv => 'Export CSV';

  /// Purpose: Return the localized string for `weightExportCsvSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightExportCsvSuccess => 'Weight data exported successfully';

  /// Purpose: Return the localized string for `weightExportCsvEmpty`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightExportCsvEmpty => 'No weight records to export';

  /// Purpose: Return the localized string for `csvImportWeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportWeight => 'Import Weight CSV';

  /// Purpose: Return the localized string for `csvImportWeightDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvImportWeightDesc =>
      'Merge weight records from CSV (Date, Time, Weight)';

  /// Purpose: Return the localized string for `csvTemplateWeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get csvTemplateWeight => 'Download Weight Template';

  /// Purpose: Return the localized string for `financeSubscriptionPresets`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSubscriptionPresets => 'Quick Fill';

  /// Purpose: Return the localized string for `intimacyPurchaseLink`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPurchaseLink => 'Purchase Link';

  /// Purpose: Return the localized string for `intimacyPrice`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPrice => 'Price';

  /// Purpose: Return the localized string for `intimacyPositions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPositions => 'Positions';

  /// Purpose: Return the localized string for `intimacyAddPosition`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyAddPosition => 'Add Position';

  /// Purpose: Return the localized string for `intimacyEditPosition`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyEditPosition => 'Edit Position';

  /// Purpose: Return the localized string for `intimacyNoPositions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyNoPositions => 'No positions yet';

  /// Purpose: Return the localized string for `intimacyImportDefaults`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyImportDefaults => 'Import Defaults';

  /// Purpose: Return the localized string for `intimacyTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyTrend => 'Trend';

  /// Purpose: Return the localized string for `intimacyFrequency`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyFrequency => 'Frequency';

  /// Purpose: Return the localized string for `intimacyChartNoData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyChartNoData => 'Not enough data';

  /// Purpose: Return the localized string for `weightTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightTrend => 'Trend';

  /// Purpose: Return the localized string for `weightRaw`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightRaw => 'Actual';

  /// Purpose: Return the localized string for `weightReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminder => 'Weight Reminder';

  /// Purpose: Return the localized string for `weightReminderNone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderNone => 'No Reminder';

  /// Purpose: Return the localized string for `weightReminderOnce`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderOnce => 'Once Daily';

  /// Purpose: Return the localized string for `weightReminderTwice`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderTwice => 'Twice Daily (Morning & Evening)';

  /// Purpose: Return the localized string for `weightReminderMorning`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderMorning => 'Morning';

  /// Purpose: Return the localized string for `weightReminderEvening`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderEvening => 'Evening';

  /// Purpose: Return the localized string for `weightReminderSkipWindow`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderSkipWindow => 'Skip if already logged';

  /// Purpose: Implement the weight reminder skip window value behavior for this file.
  /// Inputs: `hours`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String weightReminderSkipWindowValue(String hours) {
    return '$hours h before reminder';
  }

  /// Purpose: Return the localized string for `weightReminderSkipWindowHours`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get weightReminderSkipWindowHours => 'Hours before reminder';

  /// Purpose: Return the localized string for `commonChange`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonChange => 'Change';

  /// Purpose: Return the localized string for `commonPickImage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonPickImage => 'Pick Image';

  /// Purpose: Return the localized string for `commonRemoveIcon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonRemoveIcon => 'Remove icon';

  /// Purpose: Return the localized string for `commonPickIcon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonPickIcon => 'Pick an icon';

  /// Purpose: Return the localized string for `commonNoData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonNoData => 'No data';

  /// Purpose: Implement the common week group behavior for this file.
  /// Inputs: `year`, `week`, `range`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String commonWeekGroup(int year, int week, String range) {
    return '$year Week $week ($range)';
  }

  /// Purpose: Return the localized string for `todoDailyReminders`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoDailyReminders => 'Daily Reminders';

  /// Purpose: Return the localized string for `todoRemindReviewHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoRemindReviewHint => 'Remind to review today\'s Todo list';

  /// Purpose: Return the localized string for `todoRemindUndoneHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoRemindUndoneHint => 'Remind if tasks are still undone';

  /// Purpose: Return the localized string for `todoTapReturnToday`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoTapReturnToday => 'Tap to return to today';

  /// Purpose: Return the localized string for `todoCalendar`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCalendar => 'Calendar';

  /// Purpose: Return the localized string for `todoWeekMon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekMon => 'Mon';

  /// Purpose: Return the localized string for `todoWeekTue`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekTue => 'Tue';

  /// Purpose: Return the localized string for `todoWeekWed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekWed => 'Wed';

  /// Purpose: Return the localized string for `todoWeekThu`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekThu => 'Thu';

  /// Purpose: Return the localized string for `todoWeekFri`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekFri => 'Fri';

  /// Purpose: Return the localized string for `todoWeekSat`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekSat => 'Sat';

  /// Purpose: Return the localized string for `todoWeekSun`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWeekSun => 'Sun';

  /// Purpose: Return the localized string for `todoCalendarSomeDaily`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCalendarSomeDaily => 'Some daily';

  /// Purpose: Return the localized string for `todoCalendarAllDaily`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCalendarAllDaily => 'All daily';

  /// Purpose: Return the localized string for `todoCalendarAllDone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoCalendarAllDone => 'All done';

  /// Purpose: Return the localized string for `todoWhatNeedsDone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoWhatNeedsDone => 'What needs to be done?';

  /// Purpose: Implement the todo reminder at behavior for this file.
  /// Inputs: `time`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoReminderAt(String time) {
    return 'Reminder: $time';
  }

  /// Purpose: Return the localized string for `todoAddReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoAddReminder => 'Add reminder (optional)';

  /// Purpose: Implement the todo scheduled at behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoScheduledAt(String date) {
    return 'Scheduled: $date';
  }

  /// Purpose: Return the localized string for `todoSetScheduledDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSetScheduledDate => 'Set scheduled date';

  /// Purpose: Implement the todo completed at behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoCompletedAt(String date) {
    return 'Completed: $date';
  }

  /// Purpose: Return the localized string for `todoSetCompletedDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSetCompletedDate => 'Set completed date';

  /// Purpose: Return the localized string for `todoSortBy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSortBy => 'Sort';

  /// Purpose: Return the localized string for `todoSortByAdded`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSortByAdded => 'By Added Time';

  /// Purpose: Return the localized string for `todoSortByDueDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSortByDueDate => 'By Due Date';

  /// Purpose: Return the localized string for `todoSortByName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSortByName => 'By Name';

  /// Purpose: Return the localized string for `todoSortCustom`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoSortCustom => 'Custom';

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
  String get positionMissionary => 'Missionary';

  /// Purpose: Return the localized string for `positionCowgirl`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionCowgirl => 'Cowgirl';

  /// Purpose: Return the localized string for `positionDoggyStyle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionDoggyStyle => 'Doggy Style';

  /// Purpose: Return the localized string for `positionReverseCowgirl`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionReverseCowgirl => 'Reverse Cowgirl';

  /// Purpose: Return the localized string for `positionSpooning`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionSpooning => 'Spooning';

  /// Purpose: Return the localized string for `positionStanding`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionStanding => 'Standing';

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
  String get positionLotus => 'Lotus';

  /// Purpose: Return the localized string for `positionProneBone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get positionProneBone => 'Prone Bone';

  /// Purpose: Return the localized string for `notifTodoMorning`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get notifTodoMorning =>
      'Good morning! Time to review and update your Todo list 📝';

  /// Purpose: Return the localized string for `notifTodoCompletion`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get notifTodoCompletion =>
      'Don\'t forget to complete your remaining tasks today!';

  /// Purpose: Implement the notif todo uncompleted behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String notifTodoUncompleted(int count) {
    return 'You still have $count uncompleted tasks today!';
  }

  /// Purpose: Return the localized string for `notifWeightReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get notifWeightReminder => 'Time to log your weight! ⚖️';

  /// Purpose: Implement the notif upcoming renewals behavior for this file.
  /// Inputs: `list`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String notifUpcomingRenewals(String list) {
    return 'Upcoming renewals: $list';
  }

  /// Purpose: Implement the notif subscription today behavior for this file.
  /// Inputs: `name`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String notifSubscriptionToday(String name) {
    return '$name(today)';
  }

  /// Purpose: Implement the notif subscription days behavior for this file.
  /// Inputs: `name`, `days`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String notifSubscriptionDays(String name, int days) {
    return '$name(${days}d)';
  }

  /// Purpose: Return the localized string for `trayShow`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get trayShow => 'Show';

  /// Purpose: Return the localized string for `trayQuit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get trayQuit => 'Quit';

  /// Purpose: Return the localized string for `filePickerExportLocation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get filePickerExportLocation => 'Choose export location';

  /// Purpose: Return the localized string for `filePickerBackupFile`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get filePickerBackupFile => 'Choose backup file';

  /// Purpose: Return the localized string for `filePickerCsvFile`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get filePickerCsvFile => 'Choose CSV file';

  /// Purpose: Return the localized string for `filePickerSaveTemplate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get filePickerSaveTemplate => 'Save template to';

  /// Purpose: Return the localized string for `financeBalance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBalance => 'Balance';

  /// Purpose: Return the localized string for `financeNewAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNewAccount => 'New Account';

  /// Purpose: Return the localized string for `financeAccountTypeFund`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountTypeFund => 'Fund';

  /// Purpose: Return the localized string for `financeAccountTypeCredit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountTypeCredit => 'Credit';

  /// Purpose: Return the localized string for `financeAccountTypeRecharge`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountTypeRecharge => 'Recharge';

  /// Purpose: Return the localized string for `financeAccountTypeFinancial`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountTypeFinancial => 'Financial';

  /// Purpose: Return the localized string for `financeAccountName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountName => 'Account Name';

  /// Purpose: Return the localized string for `financeBankAppHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBankAppHint => 'e.g. ICBC, Alipay';

  /// Purpose: Return the localized string for `financeCardNumberHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCardNumberHint => 'Last 4 digits';

  /// Purpose: Return the localized string for `financeFeeWaiverConditions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverConditions => 'Monthly fee waiver';

  /// Purpose: Return the localized string for `financeFeeWaiverConditionsHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverConditionsHint =>
      'Optional criteria for avoiding monthly maintenance fees.';

  /// Purpose: Return the localized string for `financeFeeWaiverMinimumBalance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverMinimumBalance => 'Minimum balance';

  /// Purpose: Return the localized string for `financeFeeWaiverMinimumBalanceHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverMinimumBalanceHint => 'e.g. 1500';

  /// Purpose: Return the localized string for `financeFeeWaiverMonthlyDeposit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverMonthlyDeposit => 'Monthly incoming transfer';

  /// Purpose: Return the localized string for `financeFeeWaiverMonthlyDepositHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverMonthlyDepositHint => 'e.g. 500';

  /// Purpose: Return the localized string for `financeFeeWaiverSeparator`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFeeWaiverSeparator => ' or ';

  /// Purpose: Return the localized string for `financeCurrentBalanceHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCurrentBalanceHint =>
      'Leave empty to calculate from transactions';

  /// Purpose: Return the localized string for `financeAsOfToday`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAsOfToday => 'As of today';

  /// Purpose: Return the localized string for `financeBalanceEffectiveDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBalanceEffectiveDate => 'Balance effective date';

  /// Purpose: Return the localized string for `financeFetchIcon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFetchIcon => 'Fetch Icon';

  /// Purpose: Return the localized string for `financeAccountsCategories`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeAccountsCategories => 'Accounts & Categories';

  /// Purpose: Return the localized string for `financeEditRate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeEditRate => 'Edit Rate';

  /// Purpose: Return the localized string for `financeNewRate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNewRate => 'New Exchange Rate';

  /// Purpose: Return the localized string for `financeFrom`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeFrom => 'From';

  /// Purpose: Return the localized string for `financeTo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTo => 'To';

  /// Purpose: Return the localized string for `financeRate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeRate => 'Rate';

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
  String get financeNoRates => 'No exchange rates configured';

  /// Purpose: Return the localized string for `financeNoExpenseData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoExpenseData => 'No expense data for this period';

  /// Purpose: Return the localized string for `financeUncategorized`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeUncategorized => 'Uncategorized';

  /// Purpose: Return the localized string for `financeTotal`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeTotal => 'Total';

  /// Purpose: Return the localized string for `financeSelectDateRange`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeSelectDateRange => 'Select a date range';

  /// Purpose: Return the localized string for `financeNoTransactionData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoTransactionData => 'No transaction data for this period';

  /// Purpose: Implement the finance received amount behavior for this file.
  /// Inputs: `currency`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String financeReceivedAmount(String currency) {
    return 'Received Amount ($currency)';
  }

  /// Purpose: Return the localized string for `financeReceivedAmountHelper`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeReceivedAmountHelper =>
      'Amount received in target account currency';

  /// Purpose: Return the localized string for `financeNoteHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeNoteHint => 'What was this for?';

  /// Purpose: Return the localized string for `financeThisAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeThisAccount => 'this account';

  /// Purpose: Return the localized string for `commonThisRecord`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get commonThisRecord => 'this record';

  /// Purpose: Return the localized string for `financeBalanceAdjustment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeBalanceAdjustment => 'Balance Adjustment';

  /// Purpose: Return the localized string for `financeCatCreditCardPayment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatCreditCardPayment => 'Credit Card Payment';

  /// Purpose: Return the localized string for `financeCatFixedDeposit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatFixedDeposit => 'Fixed Deposit Maturity';

  /// Purpose: Return the localized string for `financeCatInternalTransfer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatInternalTransfer => 'Internal Transfer';

  /// Purpose: Return the localized string for `financeCatLoanRepayment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatLoanRepayment => 'Loan Repayment';

  /// Purpose: Return the localized string for `financeCatInvestmentTransfer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatInvestmentTransfer => 'Investment Transfer';

  /// Purpose: Return the localized string for `financeCatReimburse`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get financeCatReimburse => 'Reimbursement';

  /// Purpose: Return the localized string for `settingsAutoStart`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsAutoStart => 'Launch at Startup';

  /// Purpose: Return the localized string for `settingsApiEnabled`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiEnabled => 'Local API Server';

  /// Purpose: Return the localized string for `settingsApiServer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiServer => 'API Server Settings';

  /// Purpose: Implement the settings api running behavior for this file.
  /// Inputs: `port`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String settingsApiRunning(int port) {
    return 'Running on port $port';
  }

  /// Purpose: Return the localized string for `settingsApiStopped`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiStopped => 'Stopped';

  /// Purpose: Return the localized string for `settingsApiNeedCredentials`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiNeedCredentials =>
      'Credentials required for non-localhost';

  /// Purpose: Implement the settings api restarted behavior for this file.
  /// Inputs: `port`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String settingsApiRestarted(int port) {
    return 'API server restarted on port $port';
  }

  /// Purpose: Return the localized string for `settingsApiListenAddress`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiListenAddress => 'Listen Address';

  /// Purpose: Return the localized string for `settingsApiPort`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiPort => 'Port';

  /// Purpose: Return the localized string for `settingsApiUsername`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiUsername => 'Username';

  /// Purpose: Return the localized string for `settingsApiPassword`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get settingsApiPassword => 'Password';

  /// Purpose: Return the localized string for `todoRecurrence`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoRecurrence => 'Recurrence';

  /// Purpose: Return the localized string for `todoRecurrenceNone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoRecurrenceNone => 'None';

  /// Purpose: Implement the todo recurrence every n days behavior for this file.
  /// Inputs: `n`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoRecurrenceEveryNDays(int n) {
    return 'Every $n days';
  }

  /// Purpose: Implement the todo recurrence monthly on day behavior for this file.
  /// Inputs: `n`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoRecurrenceMonthlyOnDay(int n) {
    return 'Every month on the ${n}th';
  }

  /// Purpose: Implement the todo recurrence yearly on date behavior for this file.
  /// Inputs: `month`, `day`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  String todoRecurrenceYearlyOnDate(int month, int day) {
    return 'Every year on $month/$day';
  }

  /// Purpose: Return the localized string for `todoNextOccurrence`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get todoNextOccurrence => 'Schedule Next Occurrence';

  /// Purpose: Return the localized string for `intimacyActivePartners`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyActivePartners => 'Active Partners';

  /// Purpose: Return the localized string for `intimacyPastPartners`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyPastPartners => 'Past Partners';

  /// Purpose: Return the localized string for `intimacyActiveToys`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyActiveToys => 'Active Toys';

  /// Purpose: Return the localized string for `intimacyRetiredToys`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacyRetiredToys => 'Retired Toys';

  /// Purpose: Return the localized string for `intimacySortByRelationshipDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortByRelationshipDate => 'By Relationship Date';

  /// Purpose: Return the localized string for `intimacySortByPurchaseDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortByPurchaseDate => 'By Purchase Date';

  /// Purpose: Return the localized string for `intimacySortByUseCount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  @override
  String get intimacySortByUseCount => 'By Use Count';
}
