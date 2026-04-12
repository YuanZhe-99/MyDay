// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MyDay!!!!!';

  @override
  String get navTodo => 'Todo';

  @override
  String get navFinance => 'Finance';

  @override
  String get navWeight => 'Weight';

  @override
  String get navIntimacy => 'Intimacy';

  @override
  String get navSettings => 'Settings';

  @override
  String get todoSectionDaily => 'Daily';

  @override
  String get todoSectionRoutine => 'Routine';

  @override
  String get todoSectionWork => 'Work';

  @override
  String get todoAddTask => 'Add Task';

  @override
  String get todoEditTask => 'Edit Task';

  @override
  String get todoTitle => 'Title';

  @override
  String get todoSubtasks => 'Subtasks';

  @override
  String get todoAddSubtask => 'Add Subtask';

  @override
  String get todoReminderTime => 'Reminder Time';

  @override
  String get todoNoTasks => 'No tasks';

  @override
  String get todoType => 'Type';

  @override
  String get todoEmoji => 'Emoji';

  @override
  String get todoDailyTask => 'Daily';

  @override
  String get todoRoutineTask => 'Routine Once';

  @override
  String get todoWorkTask => 'Work Once';

  @override
  String todoCreatedDate(String date) {
    return 'Created: $date';
  }

  @override
  String todoStartDate(String date) {
    return 'Start Date: $date';
  }

  @override
  String todoDeletedDate(String date) {
    return 'Deleted: $date';
  }

  @override
  String get todoPermanentDelete => 'Permanently Delete';

  @override
  String get todoPermanentDeleteConfirm =>
      'This will permanently remove this task and all its history. Continue?';

  @override
  String get todoMorningReminder => 'Morning Plan Reminder';

  @override
  String get todoCompletionReminder => 'Completion Check Reminder';

  @override
  String get todoSetReminder => 'Set Reminder';

  @override
  String get todoClearReminder => 'Clear';

  @override
  String todoReminderSet(String time) {
    return 'Reminder set for $time';
  }

  @override
  String get todoCompleted => 'Completed';

  @override
  String get todoDueDate => 'Due';

  @override
  String get todoSetDueDate => 'Set due date (optional)';

  @override
  String get todoCustomEmoji => 'Custom Emoji';

  @override
  String get todoCustomEmojiHint => 'Enter an emoji';

  @override
  String get todoEditSubtask => 'Edit Subtask';

  @override
  String todoSubtasksProgress(int done, int total) {
    return 'Subtasks: $done/$total';
  }

  @override
  String todoTaskDue(String date) {
    return 'Due: $date';
  }

  @override
  String get todoThisTask => 'this task';

  @override
  String get financeTitle => 'Finance';

  @override
  String get financeMonthlyExpense => 'Monthly Expense';

  @override
  String get financeTotalAssets => 'Total Assets';

  @override
  String get financeAccounts => 'Accounts';

  @override
  String get financeCategories => 'Categories';

  @override
  String get financeTrends => 'Trends';

  @override
  String get financeAnalysis => 'Analysis';

  @override
  String get financeExchangeRates => 'Exchange Rates';

  @override
  String get financeRefreshRates => 'Refresh Rates';

  @override
  String get financeAddTransaction => 'Add Transaction';

  @override
  String get financeEditTransaction => 'Edit Transaction';

  @override
  String get financeExpense => 'Expense';

  @override
  String get financeIncome => 'Income';

  @override
  String get financeTransfer => 'Transfer';

  @override
  String get financeAmount => 'Amount';

  @override
  String get financeNote => 'Note';

  @override
  String get financeCategory => 'Category';

  @override
  String get financeAccount => 'Account';

  @override
  String get financeFromAccount => 'From Account';

  @override
  String get financeToAccount => 'To Account';

  @override
  String get financeCurrency => 'Currency';

  @override
  String get financeDate => 'Date';

  @override
  String get financeNoTransactions => 'No transactions';

  @override
  String get financeForceBalance => 'Force Balance';

  @override
  String get financeCurrentBalance => 'Current Balance';

  @override
  String get financeAddAccount => 'Add Account';

  @override
  String get financeEditAccount => 'Edit Account';

  @override
  String get financeAddCategory => 'Add Category';

  @override
  String get financeEditCategory => 'Edit Category';

  @override
  String get financeName => 'Name';

  @override
  String get financeBankApp => 'Bank / App';

  @override
  String get financeCardNumber => 'Card Number (optional)';

  @override
  String get financeExpiry => 'Expiry';

  @override
  String get financeSecurityCode => 'Security Code';

  @override
  String get financeIcon => 'Icon';

  @override
  String get financeEmoji => 'Emoji';

  @override
  String get financeCategoryHintExpense => 'e.g. Food, Transport';

  @override
  String get financeCategoryHintIncome => 'e.g. Salary, Investment';

  @override
  String get financeThisTransaction => 'this transaction';

  @override
  String get financeNoAccounts => 'No accounts yet';

  @override
  String get financeNoCategories => 'No categories yet';

  @override
  String get financeByYear => 'By Year';

  @override
  String get financeByMonth => 'By Month';

  @override
  String get financeByDay => 'By Day';

  @override
  String get financeCustomRange => 'Custom Range';

  @override
  String get financeExpenseTrend => 'Expense Trend';

  @override
  String get financeIncomeTrend => 'Income Trend';

  @override
  String get financeAssetsTrend => 'Assets Trend';

  @override
  String get financeThisCategory => 'this category';

  @override
  String financeNoCategoriesOfType(String type) {
    return 'No $type categories';
  }

  @override
  String get financeImportDefaults => 'Import Defaults';

  @override
  String get financeCatFood => 'Food';

  @override
  String get financeCatTransport => 'Transport';

  @override
  String get financeCatShopping => 'Shopping';

  @override
  String get financeCatRent => 'Rent';

  @override
  String get financeCatDigital => 'Digital';

  @override
  String get financeCatEntertainment => 'Entertainment';

  @override
  String get financeCatHealthcare => 'Healthcare';

  @override
  String get financeCatEducation => 'Education';

  @override
  String get financeCatSalary => 'Salary';

  @override
  String get financeCatBonus => 'Bonus';

  @override
  String get financeCatInvestment => 'Investment';

  @override
  String get financeCatFreelance => 'Freelance';

  @override
  String get intimacyTitle => 'Intimacy';

  @override
  String get intimacyNewRecord => 'New Record';

  @override
  String get intimacyEditRecord => 'Edit Record';

  @override
  String get intimacySolo => 'Solo';

  @override
  String get intimacyPartner => 'Partner';

  @override
  String get intimacyPartners => 'Partners';

  @override
  String get intimacyAddPartner => 'Add Partner';

  @override
  String get intimacyEditPartner => 'Edit Partner';

  @override
  String get intimacyToys => 'Toys';

  @override
  String get intimacyAddToy => 'Add Toy';

  @override
  String get intimacyEditToy => 'Edit Toy';

  @override
  String get intimacyPleasure => 'Pleasure';

  @override
  String get intimacyDuration => 'Duration';

  @override
  String get intimacyLocation => 'Location (optional)';

  @override
  String get intimacyNotes => 'Notes (optional)';

  @override
  String get intimacyOrgasm => 'Had Orgasm?';

  @override
  String get intimacyWatchedPorn => 'Watched Porn?';

  @override
  String get intimacyTimer => 'Timer';

  @override
  String get intimacyNoRecords => 'No records';

  @override
  String get intimacyNoPartners => 'No partners yet';

  @override
  String get intimacyNoToys => 'No toys yet';

  @override
  String get intimacyNoPartnersHint => 'No partners — add one in Settings';

  @override
  String get intimacyShowAll => 'Show all';

  @override
  String get intimacyAllRecords => 'All Records';

  @override
  String get intimacyStart => 'Start';

  @override
  String get intimacyPause => 'Pause';

  @override
  String get intimacyResume => 'Resume';

  @override
  String get intimacyStopSave => 'Stop & Save';

  @override
  String get intimacyReset => 'Reset';

  @override
  String get intimacyTimerStartedAt => 'Started at';

  @override
  String get intimacyTimerHistory => 'History';

  @override
  String get intimacyTimerClearHistory => 'Clear';

  @override
  String get intimacyTimerRetention3d => '3 days';

  @override
  String get intimacyTimerRetention7d => '7 days';

  @override
  String get intimacyTimerRetention14d => '14 days';

  @override
  String get intimacyTimerRetentionForever => 'Forever';

  @override
  String get intimacyManage => 'Manage';

  @override
  String get intimacyModuleVisible => 'Visible';

  @override
  String get intimacyModuleHidden => 'Hidden';

  @override
  String get intimacySortNewest => 'Newest first';

  @override
  String get intimacySortOldest => 'Oldest first';

  @override
  String get intimacySortPleasure => 'Highest pleasure';

  @override
  String get intimacySortDuration => 'Longest duration';

  @override
  String get intimacyFilterAll => 'All';

  @override
  String get intimacyFilterSolo => 'Solo';

  @override
  String get intimacyFilterPartnered => 'With partner';

  @override
  String get intimacyFilterOrgasm => 'Had orgasm';

  @override
  String get intimacyFilterNoOrgasm => 'No orgasm';

  @override
  String get intimacyExportCsv => 'Export CSV';

  @override
  String get intimacyExportCsvSuccess => 'CSV exported successfully';

  @override
  String get intimacyExportCsvEmpty => 'No records to export';

  @override
  String get intimacyStartDate => 'Start Date';

  @override
  String get intimacyEndDate => 'End Date';

  @override
  String get intimacyPurchaseDate => 'Purchase Date';

  @override
  String get intimacyRetiredDate => 'Retired Date';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsIntimacyModule => 'Intimacy Module';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsStorageLocation => 'Storage Location';

  @override
  String get settingsStoragePathHint =>
      'Enter the directory path for storing data. Leave empty to use default.';

  @override
  String get settingsDirectoryPath => 'Directory Path';

  @override
  String get settingsResetDefault => 'Reset to Default';

  @override
  String get settingsResetDefaultLocation => 'Reset to default location';

  @override
  String get settingsStoragePathUpdated => 'Storage path updated';

  @override
  String get settingsOpenDataFolder => 'Open Data Folder';

  @override
  String get settingsOpenDataFolderDesc =>
      'Open the application data directory';

  @override
  String get settingsWebDAVSync => 'WebDAV Sync';

  @override
  String get settingsWebDAVNotConfigured => 'Not configured';

  @override
  String get settingsWebDAVConfigured => 'Configured';

  @override
  String get settingsWebDAVServerURL => 'Server URL';

  @override
  String get settingsWebDAVUsername => 'Username';

  @override
  String get settingsWebDAVPassword => 'Password';

  @override
  String get settingsWebDAVRemotePath => 'Remote Path';

  @override
  String get settingsWebDAVTestConnection => 'Test Connection';

  @override
  String get settingsWebDAVConnectionSuccess => 'Connection successful';

  @override
  String get settingsWebDAVConnectionFailed => 'Connection failed';

  @override
  String get settingsWebDAVSyncNow => 'Sync Now';

  @override
  String get settingsWebDAVAutoSync => 'Auto Sync';

  @override
  String get settingsWebDAVAutoSyncDesc =>
      'Automatically sync after editing and when the app resumes';

  @override
  String get settingsWebDAVSyncing => 'Syncing...';

  @override
  String get settingsWebDAVSyncSuccess => 'Sync completed';

  @override
  String get settingsWebDAVSyncFailed => 'Sync failed';

  @override
  String get settingsWebDAVConflictTitle => 'Sync Conflicts';

  @override
  String get settingsWebDAVConflictDesc =>
      'Both local and remote have changes for the following records. Choose which version to keep for each:';

  @override
  String get settingsWebDAVKeepLocal => 'Keep Local';

  @override
  String get settingsWebDAVKeepRemote => 'Keep Remote';

  @override
  String get settingsWebDAVConflictApply => 'Apply';

  @override
  String get settingsWebDAVNextcloud => 'Nextcloud Preset';

  @override
  String get settingsWebDAVCustom => 'Custom Server';

  @override
  String get settingsImportExport => 'Import / Export';

  @override
  String get settingsExportJSON => 'Export ZIP';

  @override
  String get settingsExportCSV => 'Export CSV';

  @override
  String get csvExportFinance => 'Export Finance CSV';

  @override
  String get csvExportFinanceDesc => 'Finance transactions as plaintext';

  @override
  String get csvExportIntimacy => 'Export Intimacy CSV';

  @override
  String get csvExportIntimacyDesc => 'Intimacy records as plaintext';

  @override
  String get csvExportWeight => 'Export Weight CSV';

  @override
  String get csvExportWeightDesc => 'Weight records as plaintext';

  @override
  String get settingsImport => 'Import from File';

  @override
  String get settingsExportSuccess => 'Exported successfully';

  @override
  String get settingsExportFailed => 'Export failed';

  @override
  String get settingsImportSuccess => 'Imported successfully';

  @override
  String get settingsImportFailed => 'Import failed';

  @override
  String get settingsImportConfirm =>
      'This will replace all current data. Continue?';

  @override
  String get settingsExportCSVWarning =>
      'CSV data will be exported as plaintext. Continue?';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutTitle => 'About MyDay!!!!!';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonOk => 'OK';

  @override
  String get commonClose => 'Close';

  @override
  String get commonName => 'Name';

  @override
  String get commonEmojiOptional => 'Emoji (optional)';

  @override
  String get commonOptional => 'optional';

  @override
  String commonDeleteConfirm(String item) {
    return 'Delete $item?';
  }

  @override
  String commonMinutes(int count) {
    return '${count}min';
  }

  @override
  String get settingsExportSection => 'Export';

  @override
  String get settingsImportSection => 'Import';

  @override
  String get settingsExportFullBackup => 'Full backup of all data';

  @override
  String get settingsExportJSONPlaintext =>
      'All data will be exported as a ZIP archive';

  @override
  String get settingsExportCSVPlaintext => 'Finance transactions as plaintext';

  @override
  String get settingsImportRestore => 'Restore from ZIP backup';

  @override
  String get settingsImportData => 'Import Data';

  @override
  String get csvImportFinance => 'Import Finance CSV';

  @override
  String get csvImportFinanceDesc =>
      'Merge transactions from CSV (will not overwrite existing data)';

  @override
  String get csvImportIntimacy => 'Import Intimacy CSV';

  @override
  String get csvImportIntimacyDesc =>
      'Merge records from CSV (will not overwrite existing data)';

  @override
  String get csvImportConfirm =>
      'CSV data will be merged into existing records. Continue?';

  @override
  String csvImportSuccess(int count) {
    return 'Imported $count records successfully';
  }

  @override
  String get csvImportFailed => 'CSV import failed';

  @override
  String get csvImportEmpty => 'No valid records found in CSV';

  @override
  String get csvTemplate => 'CSV Templates';

  @override
  String get csvTemplateFinance => 'Download Finance Template';

  @override
  String get csvTemplateIntimacy => 'Download Intimacy Template';

  @override
  String get csvTemplateSaved => 'Template saved';

  @override
  String get settingsWebDAVDisconnect => 'Disconnect';

  @override
  String get settingsWebDAVConfigSaved => 'Configuration saved';

  @override
  String get settingsWebDAVConfigRemoved => 'Configuration removed';

  @override
  String get commonDontAskMinutes => 'Don\'t ask for 5 minutes';

  @override
  String get intimacyHideConfirm =>
      'Hiding the module will not delete your data. You can re-enable it anytime.';

  @override
  String get settingsLicense => 'License (GPLv3)';

  @override
  String get settingsLicenses => 'Open Source Licenses';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsDesktop => 'Desktop';

  @override
  String get settingsMinimizeToTray => 'Minimize to Tray';

  @override
  String get settingsCloseToTray => 'Close to Tray';

  @override
  String get financeBankPresets => 'Bank Presets';

  @override
  String get financeBankSearch => 'Search bank or app...';

  @override
  String get financeBankNoResults => 'No matching banks found';

  @override
  String get financeSubscriptions => 'Subscriptions';

  @override
  String get financeSubscription => 'Subscription';

  @override
  String get financeAddSubscription => 'Add Subscription';

  @override
  String get financeEditSubscription => 'Edit Subscription';

  @override
  String get financeStartDate => 'Start Date';

  @override
  String get financeTrialDays => 'Trial Days';

  @override
  String get financeBillingCycle => 'Billing Cycle';

  @override
  String get financeBillingCycleMonthly => 'Monthly';

  @override
  String get financeBillingCycleYearly => 'Yearly';

  @override
  String financeEveryXMonths(int count) {
    return 'Every $count month(s)';
  }

  @override
  String financeEveryXYears(int count) {
    return 'Every $count year(s)';
  }

  @override
  String get financeBillingDay => 'Billing Day';

  @override
  String get financeBillingMonth => 'Billing Month';

  @override
  String get financeMonthlyDue => 'Monthly Due';

  @override
  String get financeMonthlyAvg => 'Monthly Avg';

  @override
  String get financeYearlyAvg => 'Yearly Avg';

  @override
  String get financeNoSubscriptions => 'No subscriptions';

  @override
  String get financeActiveSubscriptions => 'Active';

  @override
  String get financeHistoricalSubscriptions => 'History';

  @override
  String get financeCancelSubscription => 'Cancel Subscription';

  @override
  String get financeCancelImmediate => 'Cancel Now';

  @override
  String get financeCancelAtExpiry => 'Cancel at Expiry';

  @override
  String get financeNextBilling => 'Next Billing';

  @override
  String get financeExpiryDate => 'Expiry';

  @override
  String get financeTotalSpent => 'Total Spent';

  @override
  String get financeImportHistory => 'Import Historical Transactions';

  @override
  String get financeImportHistoryDesc =>
      'Start date is before today. Import historical transactions?';

  @override
  String get financeThisSubscription => 'this subscription';

  @override
  String financeCancelledOn(String date) {
    return 'Cancelled $date';
  }

  @override
  String get financeInterval => 'Interval';

  @override
  String get financeImage => 'Image';

  @override
  String get financePickImage => 'Pick Image';

  @override
  String get financeChangeImage => 'Change';

  @override
  String get financeUpcomingRenewals => 'Upcoming Renewals';

  @override
  String get financeSubscriptionReminder => 'Subscription Reminder';

  @override
  String get financeReminderTime => 'Notification Time';

  @override
  String get financeReminderEnabled => 'Notify upcoming renewals';

  @override
  String financeSubscriptionDueSoon(String name, int days) {
    return '$name is due in $days day(s)';
  }

  @override
  String financeSubscriptionDueToday(String name) {
    return '$name is due today';
  }

  @override
  String get financeSortBy => 'Sort';

  @override
  String get financeSortByRenewal => 'By Renewal Date';

  @override
  String get financeSortByName => 'By Name';

  @override
  String get financeSortCustom => 'Custom';

  @override
  String get financeSortReorder => 'Reorder';

  @override
  String get financeSortDone => 'Done';

  @override
  String get financeRestoreSubscription => 'Restore';

  @override
  String get backupTitle => 'Backup';

  @override
  String get backupLocalOnlyNote =>
      'Backups are stored locally on this device only. Use WebDAV Sync for cloud backup.';

  @override
  String get backupSettings => 'Settings';

  @override
  String get backupAutoDaily => 'Daily Auto-Backup';

  @override
  String get backupAutoDailyDesc => 'Automatically create backup once per day';

  @override
  String get backupRetention => 'Keep backups';

  @override
  String get backupRetentionForever => 'Forever';

  @override
  String backupRetentionDays(int count) {
    return '$count days';
  }

  @override
  String get backupManual => 'Manual Backup';

  @override
  String get backupCreateNow => 'Create Backup Now';

  @override
  String backupHistory(int count) {
    return 'Backups ($count)';
  }

  @override
  String get backupEmpty => 'No backups yet';

  @override
  String get backupCreated => 'Backup created successfully';

  @override
  String get backupFailed => 'Backup failed';

  @override
  String get backupRestore => 'Restore';

  @override
  String get backupRestoreConfirmTitle => 'Confirm Restore';

  @override
  String get backupRestoreConfirmDesc =>
      'This will replace selected module data. Continue?';

  @override
  String get backupRestoreSelectModules => 'Select Modules to Restore';

  @override
  String get backupRestoreAll => 'All Modules';

  @override
  String get backupRestoreSuccess =>
      'Restore successful. Please restart the app.';

  @override
  String get backupRestoreFailed => 'Restore failed';

  @override
  String get backupDeleteConfirmTitle => 'Delete Backup';

  @override
  String get backupDeleteConfirmDesc =>
      'This backup will be permanently deleted.';

  @override
  String get backupModuleTodo => 'Todo';

  @override
  String get backupModuleFinance => 'Finance';

  @override
  String get backupModuleRates => 'Exchange Rates';

  @override
  String get backupModuleIntimacy => 'Intimacy';

  @override
  String intimacyRecordCount(int count) {
    return '$count records';
  }

  @override
  String get weightTitle => 'Weight';

  @override
  String get weightSetHeight => 'Set Height';

  @override
  String get weightNoRecords => 'No weight records yet';

  @override
  String get weightAddRecord => 'Add Record';

  @override
  String get weightKg => 'Weight (kg)';

  @override
  String get weightHeightCm => 'Height (cm)';

  @override
  String get weightNote => 'Note';

  @override
  String get weightNoteHint => 'Optional note';

  @override
  String get weightChart => 'Trend';

  @override
  String get weightAll => 'All';

  @override
  String get weightHistory => 'History';

  @override
  String get weightShowAll => 'Show all records';

  @override
  String get weightDays => 'days';

  @override
  String get weightDaysAgo => 'days ago';

  @override
  String get weightWeeksAgo => 'weeks ago';

  @override
  String get weightToday => 'Today';

  @override
  String get weightYesterday => 'Yesterday';

  @override
  String get weightRecent => 'Recent';

  @override
  String get weightExportCsv => 'Export CSV';

  @override
  String get weightExportCsvSuccess => 'Weight data exported successfully';

  @override
  String get weightExportCsvEmpty => 'No weight records to export';

  @override
  String get csvImportWeight => 'Import Weight CSV';

  @override
  String get csvImportWeightDesc =>
      'Merge weight records from CSV (Date, Time, Weight)';

  @override
  String get csvTemplateWeight => 'Download Weight Template';

  @override
  String get financeSubscriptionPresets => 'Quick Fill';

  @override
  String get intimacyPurchaseLink => 'Purchase Link';

  @override
  String get intimacyPrice => 'Price';

  @override
  String get intimacyPositions => 'Positions';

  @override
  String get intimacyAddPosition => 'Add Position';

  @override
  String get intimacyEditPosition => 'Edit Position';

  @override
  String get intimacyNoPositions => 'No positions yet';

  @override
  String get intimacyImportDefaults => 'Import Defaults';

  @override
  String get intimacyTrend => 'Trend';

  @override
  String get intimacyFrequency => 'Frequency';

  @override
  String get intimacyChartNoData => 'Not enough data';

  @override
  String get weightTrend => 'Trend';

  @override
  String get weightRaw => 'Actual';

  @override
  String get weightReminder => 'Weight Reminder';

  @override
  String get weightReminderNone => 'No Reminder';

  @override
  String get weightReminderOnce => 'Once Daily';

  @override
  String get weightReminderTwice => 'Twice Daily (Morning & Evening)';

  @override
  String get weightReminderMorning => 'Morning';

  @override
  String get weightReminderEvening => 'Evening';

  @override
  String get commonChange => 'Change';

  @override
  String get commonPickImage => 'Pick Image';

  @override
  String get commonRemoveIcon => 'Remove icon';

  @override
  String get commonPickIcon => 'Pick an icon';

  @override
  String get commonNoData => 'No data';

  @override
  String get todoDailyReminders => 'Daily Reminders';

  @override
  String get todoRemindReviewHint => 'Remind to review today\'s Todo list';

  @override
  String get todoRemindUndoneHint => 'Remind if tasks are still undone';

  @override
  String get todoTapReturnToday => 'Tap to return to today';

  @override
  String get todoCalendar => 'Calendar';

  @override
  String get todoWeekMon => 'Mon';

  @override
  String get todoWeekTue => 'Tue';

  @override
  String get todoWeekWed => 'Wed';

  @override
  String get todoWeekThu => 'Thu';

  @override
  String get todoWeekFri => 'Fri';

  @override
  String get todoWeekSat => 'Sat';

  @override
  String get todoWeekSun => 'Sun';

  @override
  String get todoCalendarSomeDaily => 'Some daily';

  @override
  String get todoCalendarAllDaily => 'All daily';

  @override
  String get todoCalendarAllDone => 'All done';

  @override
  String get todoWhatNeedsDone => 'What needs to be done?';

  @override
  String todoReminderAt(String time) {
    return 'Reminder: $time';
  }

  @override
  String get todoAddReminder => 'Add reminder (optional)';

  @override
  String todoScheduledAt(String date) {
    return 'Scheduled: $date';
  }

  @override
  String get todoSetScheduledDate => 'Set scheduled date';

  @override
  String todoCompletedAt(String date) {
    return 'Completed: $date';
  }

  @override
  String get todoSetCompletedDate => 'Set completed date';

  @override
  String get weightUnitKg => 'kg';

  @override
  String weightValueKg(String value) {
    return '$value kg';
  }

  @override
  String get positionMissionary => 'Missionary';

  @override
  String get positionCowgirl => 'Cowgirl';

  @override
  String get positionDoggyStyle => 'Doggy Style';

  @override
  String get positionReverseCowgirl => 'Reverse Cowgirl';

  @override
  String get positionSpooning => 'Spooning';

  @override
  String get positionStanding => 'Standing';

  @override
  String get position69 => '69';

  @override
  String get positionLotus => 'Lotus';

  @override
  String get positionProneBone => 'Prone Bone';

  @override
  String get notifTodoMorning =>
      'Good morning! Time to review and update your Todo list 📝';

  @override
  String get notifTodoCompletion =>
      'Don\'t forget to complete your remaining tasks today!';

  @override
  String notifTodoUncompleted(int count) {
    return 'You still have $count uncompleted tasks today!';
  }

  @override
  String get notifWeightReminder => 'Time to log your weight! ⚖️';

  @override
  String notifUpcomingRenewals(String list) {
    return 'Upcoming renewals: $list';
  }

  @override
  String notifSubscriptionToday(String name) {
    return '$name(today)';
  }

  @override
  String notifSubscriptionDays(String name, int days) {
    return '$name(${days}d)';
  }

  @override
  String get trayShow => 'Show';

  @override
  String get trayQuit => 'Quit';

  @override
  String get filePickerExportLocation => 'Choose export location';

  @override
  String get filePickerBackupFile => 'Choose backup file';

  @override
  String get filePickerCsvFile => 'Choose CSV file';

  @override
  String get filePickerSaveTemplate => 'Save template to';

  @override
  String get financeBalance => 'Balance';

  @override
  String get financeNewAccount => 'New Account';

  @override
  String get financeAccountTypeFund => 'Fund';

  @override
  String get financeAccountTypeCredit => 'Credit';

  @override
  String get financeAccountTypeRecharge => 'Recharge';

  @override
  String get financeAccountTypeFinancial => 'Financial';

  @override
  String get financeAccountName => 'Account Name';

  @override
  String get financeBankAppHint => 'e.g. ICBC, Alipay';

  @override
  String get financeCardNumberHint => 'Last 4 digits';

  @override
  String get financeCurrentBalanceHint =>
      'Leave empty to calculate from transactions';

  @override
  String get financeAsOfToday => 'As of today';

  @override
  String get financeBalanceEffectiveDate => 'Balance effective date';

  @override
  String get financeFetchIcon => 'Fetch Icon';

  @override
  String get financeAccountsCategories => 'Accounts & Categories';

  @override
  String get financeEditRate => 'Edit Rate';

  @override
  String get financeNewRate => 'New Exchange Rate';

  @override
  String get financeFrom => 'From';

  @override
  String get financeTo => 'To';

  @override
  String get financeRate => 'Rate';

  @override
  String financeRateHint(String from, String to) {
    return '1 $from = ? $to';
  }

  @override
  String get financeNoRates => 'No exchange rates configured';

  @override
  String get financeNoExpenseData => 'No expense data for this period';

  @override
  String get financeUncategorized => 'Uncategorized';

  @override
  String get financeTotal => 'Total';

  @override
  String get financeSelectDateRange => 'Select a date range';

  @override
  String get financeNoTransactionData => 'No transaction data for this period';

  @override
  String financeReceivedAmount(String currency) {
    return 'Received Amount ($currency)';
  }

  @override
  String get financeReceivedAmountHelper =>
      'Amount received in target account currency';

  @override
  String get financeNoteHint => 'What was this for?';

  @override
  String get financeThisAccount => 'this account';

  @override
  String get commonThisRecord => 'this record';

  @override
  String get financeBalanceAdjustment => 'Balance Adjustment';

  @override
  String get financeCatCreditCardPayment => 'Credit Card Payment';

  @override
  String get financeCatFixedDeposit => 'Fixed Deposit Maturity';

  @override
  String get financeCatInternalTransfer => 'Internal Transfer';

  @override
  String get financeCatLoanRepayment => 'Loan Repayment';

  @override
  String get financeCatInvestmentTransfer => 'Investment Transfer';

  @override
  String get financeCatReimburse => 'Reimbursement';

  @override
  String get settingsAutoStart => 'Launch at Startup';

  @override
  String get settingsApiEnabled => 'Local API Server';

  @override
  String get settingsApiServer => 'API Server Settings';

  @override
  String settingsApiRunning(int port) {
    return 'Running on port $port';
  }

  @override
  String get settingsApiStopped => 'Stopped';

  @override
  String get settingsApiNeedCredentials =>
      'Credentials required for non-localhost';

  @override
  String settingsApiRestarted(int port) {
    return 'API server restarted on port $port';
  }

  @override
  String get settingsApiListenAddress => 'Listen Address';

  @override
  String get settingsApiPort => 'Port';

  @override
  String get settingsApiUsername => 'Username';

  @override
  String get settingsApiPassword => 'Password';
}
