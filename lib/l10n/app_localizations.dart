import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MyDay!!!!!'**
  String get appTitle;

  /// No description provided for @navTodo.
  ///
  /// In en, this message translates to:
  /// **'Todo'**
  String get navTodo;

  /// No description provided for @navFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get navFinance;

  /// No description provided for @navWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get navWeight;

  /// No description provided for @navIntimacy.
  ///
  /// In en, this message translates to:
  /// **'Intimacy'**
  String get navIntimacy;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @todoSectionDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get todoSectionDaily;

  /// No description provided for @todoSectionRoutine.
  ///
  /// In en, this message translates to:
  /// **'Routine'**
  String get todoSectionRoutine;

  /// No description provided for @todoSectionWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get todoSectionWork;

  /// No description provided for @todoAddTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get todoAddTask;

  /// No description provided for @todoEditTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get todoEditTask;

  /// No description provided for @todoTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get todoTitle;

  /// No description provided for @todoSubtasks.
  ///
  /// In en, this message translates to:
  /// **'Subtasks'**
  String get todoSubtasks;

  /// No description provided for @todoAddSubtask.
  ///
  /// In en, this message translates to:
  /// **'Add Subtask'**
  String get todoAddSubtask;

  /// No description provided for @todoReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get todoReminderTime;

  /// No description provided for @todoNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks'**
  String get todoNoTasks;

  /// No description provided for @todoType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get todoType;

  /// No description provided for @todoEmoji.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get todoEmoji;

  /// No description provided for @todoDailyTask.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get todoDailyTask;

  /// No description provided for @todoRoutineTask.
  ///
  /// In en, this message translates to:
  /// **'Routine Once'**
  String get todoRoutineTask;

  /// No description provided for @todoWorkTask.
  ///
  /// In en, this message translates to:
  /// **'Work Once'**
  String get todoWorkTask;

  /// No description provided for @todoCreatedDate.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String todoCreatedDate(String date);

  /// No description provided for @todoStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date: {date}'**
  String todoStartDate(String date);

  /// No description provided for @todoDeletedDate.
  ///
  /// In en, this message translates to:
  /// **'Deleted: {date}'**
  String todoDeletedDate(String date);

  /// No description provided for @todoPermanentDelete.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete'**
  String get todoPermanentDelete;

  /// No description provided for @todoPermanentDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove this task and all its history. Continue?'**
  String get todoPermanentDeleteConfirm;

  /// No description provided for @todoMorningReminder.
  ///
  /// In en, this message translates to:
  /// **'Morning Plan Reminder'**
  String get todoMorningReminder;

  /// No description provided for @todoCompletionReminder.
  ///
  /// In en, this message translates to:
  /// **'Completion Check Reminder'**
  String get todoCompletionReminder;

  /// No description provided for @todoSetReminder.
  ///
  /// In en, this message translates to:
  /// **'Set Reminder'**
  String get todoSetReminder;

  /// No description provided for @todoClearReminder.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get todoClearReminder;

  /// No description provided for @todoReminderSet.
  ///
  /// In en, this message translates to:
  /// **'Reminder set for {time}'**
  String todoReminderSet(String time);

  /// No description provided for @todoCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get todoCompleted;

  /// No description provided for @todoDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get todoDueDate;

  /// No description provided for @todoSetDueDate.
  ///
  /// In en, this message translates to:
  /// **'Set due date (optional)'**
  String get todoSetDueDate;

  /// No description provided for @todoEditSubtask.
  ///
  /// In en, this message translates to:
  /// **'Edit Subtask'**
  String get todoEditSubtask;

  /// No description provided for @financeTitle.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get financeTitle;

  /// No description provided for @financeMonthlyExpense.
  ///
  /// In en, this message translates to:
  /// **'Monthly Expense'**
  String get financeMonthlyExpense;

  /// No description provided for @financeTotalAssets.
  ///
  /// In en, this message translates to:
  /// **'Total Assets'**
  String get financeTotalAssets;

  /// No description provided for @financeAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get financeAccounts;

  /// No description provided for @financeCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get financeCategories;

  /// No description provided for @financeAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get financeAnalysis;

  /// No description provided for @financeExchangeRates.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rates'**
  String get financeExchangeRates;

  /// No description provided for @financeRefreshRates.
  ///
  /// In en, this message translates to:
  /// **'Refresh Rates'**
  String get financeRefreshRates;

  /// No description provided for @financeAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get financeAddTransaction;

  /// No description provided for @financeEditTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get financeEditTransaction;

  /// No description provided for @financeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get financeExpense;

  /// No description provided for @financeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get financeIncome;

  /// No description provided for @financeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get financeTransfer;

  /// No description provided for @financeAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get financeAmount;

  /// No description provided for @financeNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get financeNote;

  /// No description provided for @financeCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get financeCategory;

  /// No description provided for @financeAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get financeAccount;

  /// No description provided for @financeFromAccount.
  ///
  /// In en, this message translates to:
  /// **'From Account'**
  String get financeFromAccount;

  /// No description provided for @financeToAccount.
  ///
  /// In en, this message translates to:
  /// **'To Account'**
  String get financeToAccount;

  /// No description provided for @financeCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get financeCurrency;

  /// No description provided for @financeDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get financeDate;

  /// No description provided for @financeNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get financeNoTransactions;

  /// No description provided for @financeForceBalance.
  ///
  /// In en, this message translates to:
  /// **'Force Balance'**
  String get financeForceBalance;

  /// No description provided for @financeCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get financeCurrentBalance;

  /// No description provided for @financeAddAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get financeAddAccount;

  /// No description provided for @financeEditAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit Account'**
  String get financeEditAccount;

  /// No description provided for @financeAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get financeAddCategory;

  /// No description provided for @financeEditCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get financeEditCategory;

  /// No description provided for @financeName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get financeName;

  /// No description provided for @financeBankApp.
  ///
  /// In en, this message translates to:
  /// **'Bank / App'**
  String get financeBankApp;

  /// No description provided for @financeCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get financeCardNumber;

  /// No description provided for @financeExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get financeExpiry;

  /// No description provided for @financeSecurityCode.
  ///
  /// In en, this message translates to:
  /// **'Security Code'**
  String get financeSecurityCode;

  /// No description provided for @financeIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get financeIcon;

  /// No description provided for @financeEmoji.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get financeEmoji;

  /// No description provided for @financeCategoryHintExpense.
  ///
  /// In en, this message translates to:
  /// **'e.g. Food, Transport'**
  String get financeCategoryHintExpense;

  /// No description provided for @financeCategoryHintIncome.
  ///
  /// In en, this message translates to:
  /// **'e.g. Salary, Investment'**
  String get financeCategoryHintIncome;

  /// No description provided for @financeThisTransaction.
  ///
  /// In en, this message translates to:
  /// **'this transaction'**
  String get financeThisTransaction;

  /// No description provided for @financeNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get financeNoAccounts;

  /// No description provided for @financeNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get financeNoCategories;

  /// No description provided for @financeByYear.
  ///
  /// In en, this message translates to:
  /// **'By Year'**
  String get financeByYear;

  /// No description provided for @financeByMonth.
  ///
  /// In en, this message translates to:
  /// **'By Month'**
  String get financeByMonth;

  /// No description provided for @financeByDay.
  ///
  /// In en, this message translates to:
  /// **'By Day'**
  String get financeByDay;

  /// No description provided for @financeCustomRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get financeCustomRange;

  /// No description provided for @financeExpenseTrend.
  ///
  /// In en, this message translates to:
  /// **'Expense Trend'**
  String get financeExpenseTrend;

  /// No description provided for @financeIncomeTrend.
  ///
  /// In en, this message translates to:
  /// **'Income Trend'**
  String get financeIncomeTrend;

  /// No description provided for @financeAssetsTrend.
  ///
  /// In en, this message translates to:
  /// **'Assets Trend'**
  String get financeAssetsTrend;

  /// No description provided for @financeThisCategory.
  ///
  /// In en, this message translates to:
  /// **'this category'**
  String get financeThisCategory;

  /// No description provided for @financeNoCategoriesOfType.
  ///
  /// In en, this message translates to:
  /// **'No {type} categories'**
  String financeNoCategoriesOfType(String type);

  /// No description provided for @financeImportDefaults.
  ///
  /// In en, this message translates to:
  /// **'Import Defaults'**
  String get financeImportDefaults;

  /// No description provided for @financeCatFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get financeCatFood;

  /// No description provided for @financeCatTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get financeCatTransport;

  /// No description provided for @financeCatShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get financeCatShopping;

  /// No description provided for @financeCatRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get financeCatRent;

  /// No description provided for @financeCatDigital.
  ///
  /// In en, this message translates to:
  /// **'Digital'**
  String get financeCatDigital;

  /// No description provided for @financeCatEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get financeCatEntertainment;

  /// No description provided for @financeCatHealthcare.
  ///
  /// In en, this message translates to:
  /// **'Healthcare'**
  String get financeCatHealthcare;

  /// No description provided for @financeCatEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get financeCatEducation;

  /// No description provided for @financeCatSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get financeCatSalary;

  /// No description provided for @financeCatBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get financeCatBonus;

  /// No description provided for @financeCatInvestment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get financeCatInvestment;

  /// No description provided for @financeCatFreelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get financeCatFreelance;

  /// No description provided for @intimacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Intimacy'**
  String get intimacyTitle;

  /// No description provided for @intimacyNewRecord.
  ///
  /// In en, this message translates to:
  /// **'New Record'**
  String get intimacyNewRecord;

  /// No description provided for @intimacyEditRecord.
  ///
  /// In en, this message translates to:
  /// **'Edit Record'**
  String get intimacyEditRecord;

  /// No description provided for @intimacySolo.
  ///
  /// In en, this message translates to:
  /// **'Solo'**
  String get intimacySolo;

  /// No description provided for @intimacyPartner.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get intimacyPartner;

  /// No description provided for @intimacyPartners.
  ///
  /// In en, this message translates to:
  /// **'Partners'**
  String get intimacyPartners;

  /// No description provided for @intimacyAddPartner.
  ///
  /// In en, this message translates to:
  /// **'Add Partner'**
  String get intimacyAddPartner;

  /// No description provided for @intimacyEditPartner.
  ///
  /// In en, this message translates to:
  /// **'Edit Partner'**
  String get intimacyEditPartner;

  /// No description provided for @intimacyToys.
  ///
  /// In en, this message translates to:
  /// **'Toys'**
  String get intimacyToys;

  /// No description provided for @intimacyAddToy.
  ///
  /// In en, this message translates to:
  /// **'Add Toy'**
  String get intimacyAddToy;

  /// No description provided for @intimacyEditToy.
  ///
  /// In en, this message translates to:
  /// **'Edit Toy'**
  String get intimacyEditToy;

  /// No description provided for @intimacyPleasure.
  ///
  /// In en, this message translates to:
  /// **'Pleasure'**
  String get intimacyPleasure;

  /// No description provided for @intimacyDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get intimacyDuration;

  /// No description provided for @intimacyLocation.
  ///
  /// In en, this message translates to:
  /// **'Location (optional)'**
  String get intimacyLocation;

  /// No description provided for @intimacyNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get intimacyNotes;

  /// No description provided for @intimacyOrgasm.
  ///
  /// In en, this message translates to:
  /// **'Had Orgasm?'**
  String get intimacyOrgasm;

  /// No description provided for @intimacyWatchedPorn.
  ///
  /// In en, this message translates to:
  /// **'Watched Porn?'**
  String get intimacyWatchedPorn;

  /// No description provided for @intimacyTimer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get intimacyTimer;

  /// No description provided for @intimacyNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No records'**
  String get intimacyNoRecords;

  /// No description provided for @intimacyNoPartners.
  ///
  /// In en, this message translates to:
  /// **'No partners yet'**
  String get intimacyNoPartners;

  /// No description provided for @intimacyNoToys.
  ///
  /// In en, this message translates to:
  /// **'No toys yet'**
  String get intimacyNoToys;

  /// No description provided for @intimacyNoPartnersHint.
  ///
  /// In en, this message translates to:
  /// **'No partners — add one in Settings'**
  String get intimacyNoPartnersHint;

  /// No description provided for @intimacyShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get intimacyShowAll;

  /// No description provided for @intimacyAllRecords.
  ///
  /// In en, this message translates to:
  /// **'All Records'**
  String get intimacyAllRecords;

  /// No description provided for @intimacyStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get intimacyStart;

  /// No description provided for @intimacyPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get intimacyPause;

  /// No description provided for @intimacyResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get intimacyResume;

  /// No description provided for @intimacyStopSave.
  ///
  /// In en, this message translates to:
  /// **'Stop & Save'**
  String get intimacyStopSave;

  /// No description provided for @intimacyReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get intimacyReset;

  /// No description provided for @intimacyTimerStartedAt.
  ///
  /// In en, this message translates to:
  /// **'Started at'**
  String get intimacyTimerStartedAt;

  /// No description provided for @intimacyTimerHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get intimacyTimerHistory;

  /// No description provided for @intimacyTimerClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get intimacyTimerClearHistory;

  /// No description provided for @intimacyManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get intimacyManage;

  /// No description provided for @intimacyModuleVisible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get intimacyModuleVisible;

  /// No description provided for @intimacyModuleHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get intimacyModuleHidden;

  /// No description provided for @intimacySortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get intimacySortNewest;

  /// No description provided for @intimacySortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get intimacySortOldest;

  /// No description provided for @intimacySortPleasure.
  ///
  /// In en, this message translates to:
  /// **'Highest pleasure'**
  String get intimacySortPleasure;

  /// No description provided for @intimacySortDuration.
  ///
  /// In en, this message translates to:
  /// **'Longest duration'**
  String get intimacySortDuration;

  /// No description provided for @intimacyFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get intimacyFilterAll;

  /// No description provided for @intimacyFilterSolo.
  ///
  /// In en, this message translates to:
  /// **'Solo'**
  String get intimacyFilterSolo;

  /// No description provided for @intimacyFilterPartnered.
  ///
  /// In en, this message translates to:
  /// **'With partner'**
  String get intimacyFilterPartnered;

  /// No description provided for @intimacyFilterOrgasm.
  ///
  /// In en, this message translates to:
  /// **'Had orgasm'**
  String get intimacyFilterOrgasm;

  /// No description provided for @intimacyFilterNoOrgasm.
  ///
  /// In en, this message translates to:
  /// **'No orgasm'**
  String get intimacyFilterNoOrgasm;

  /// No description provided for @intimacyExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get intimacyExportCsv;

  /// No description provided for @intimacyExportCsvSuccess.
  ///
  /// In en, this message translates to:
  /// **'CSV exported successfully'**
  String get intimacyExportCsvSuccess;

  /// No description provided for @intimacyExportCsvEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records to export'**
  String get intimacyExportCsvEmpty;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsIntimacyModule.
  ///
  /// In en, this message translates to:
  /// **'Intimacy Module'**
  String get settingsIntimacyModule;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// No description provided for @settingsStorageLocation.
  ///
  /// In en, this message translates to:
  /// **'Storage Location'**
  String get settingsStorageLocation;

  /// No description provided for @settingsStoragePathHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the directory path for storing data. Leave empty to use default.'**
  String get settingsStoragePathHint;

  /// No description provided for @settingsDirectoryPath.
  ///
  /// In en, this message translates to:
  /// **'Directory Path'**
  String get settingsDirectoryPath;

  /// No description provided for @settingsResetDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default'**
  String get settingsResetDefault;

  /// No description provided for @settingsResetDefaultLocation.
  ///
  /// In en, this message translates to:
  /// **'Reset to default location'**
  String get settingsResetDefaultLocation;

  /// No description provided for @settingsStoragePathUpdated.
  ///
  /// In en, this message translates to:
  /// **'Storage path updated'**
  String get settingsStoragePathUpdated;

  /// No description provided for @settingsOpenDataFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Data Folder'**
  String get settingsOpenDataFolder;

  /// No description provided for @settingsOpenDataFolderDesc.
  ///
  /// In en, this message translates to:
  /// **'Open the application data directory'**
  String get settingsOpenDataFolderDesc;

  /// No description provided for @settingsWebDAVSync.
  ///
  /// In en, this message translates to:
  /// **'WebDAV Sync'**
  String get settingsWebDAVSync;

  /// No description provided for @settingsWebDAVNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get settingsWebDAVNotConfigured;

  /// No description provided for @settingsWebDAVConfigured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get settingsWebDAVConfigured;

  /// No description provided for @settingsWebDAVServerURL.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get settingsWebDAVServerURL;

  /// No description provided for @settingsWebDAVUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get settingsWebDAVUsername;

  /// No description provided for @settingsWebDAVPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get settingsWebDAVPassword;

  /// No description provided for @settingsWebDAVRemotePath.
  ///
  /// In en, this message translates to:
  /// **'Remote Path'**
  String get settingsWebDAVRemotePath;

  /// No description provided for @settingsWebDAVTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get settingsWebDAVTestConnection;

  /// No description provided for @settingsWebDAVConnectionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection successful'**
  String get settingsWebDAVConnectionSuccess;

  /// No description provided for @settingsWebDAVConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get settingsWebDAVConnectionFailed;

  /// No description provided for @settingsWebDAVSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get settingsWebDAVSyncNow;

  /// No description provided for @settingsWebDAVAutoSync.
  ///
  /// In en, this message translates to:
  /// **'Auto Sync'**
  String get settingsWebDAVAutoSync;

  /// No description provided for @settingsWebDAVAutoSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically sync after editing and when the app resumes'**
  String get settingsWebDAVAutoSyncDesc;

  /// No description provided for @settingsWebDAVSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get settingsWebDAVSyncing;

  /// No description provided for @settingsWebDAVSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sync completed'**
  String get settingsWebDAVSyncSuccess;

  /// No description provided for @settingsWebDAVSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get settingsWebDAVSyncFailed;

  /// No description provided for @settingsWebDAVConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync Conflicts'**
  String get settingsWebDAVConflictTitle;

  /// No description provided for @settingsWebDAVConflictDesc.
  ///
  /// In en, this message translates to:
  /// **'Both local and remote have changes for the following records. Choose which version to keep for each:'**
  String get settingsWebDAVConflictDesc;

  /// No description provided for @settingsWebDAVKeepLocal.
  ///
  /// In en, this message translates to:
  /// **'Keep Local'**
  String get settingsWebDAVKeepLocal;

  /// No description provided for @settingsWebDAVKeepRemote.
  ///
  /// In en, this message translates to:
  /// **'Keep Remote'**
  String get settingsWebDAVKeepRemote;

  /// No description provided for @settingsWebDAVConflictApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get settingsWebDAVConflictApply;

  /// No description provided for @settingsWebDAVNextcloud.
  ///
  /// In en, this message translates to:
  /// **'Nextcloud Preset'**
  String get settingsWebDAVNextcloud;

  /// No description provided for @settingsWebDAVCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom Server'**
  String get settingsWebDAVCustom;

  /// No description provided for @settingsImportExport.
  ///
  /// In en, this message translates to:
  /// **'Import / Export'**
  String get settingsImportExport;

  /// No description provided for @settingsExportJSON.
  ///
  /// In en, this message translates to:
  /// **'Export ZIP'**
  String get settingsExportJSON;

  /// No description provided for @settingsExportCSV.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get settingsExportCSV;

  /// No description provided for @csvExportFinance.
  ///
  /// In en, this message translates to:
  /// **'Export Finance CSV'**
  String get csvExportFinance;

  /// No description provided for @csvExportFinanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Finance transactions as plaintext'**
  String get csvExportFinanceDesc;

  /// No description provided for @csvExportIntimacy.
  ///
  /// In en, this message translates to:
  /// **'Export Intimacy CSV'**
  String get csvExportIntimacy;

  /// No description provided for @csvExportIntimacyDesc.
  ///
  /// In en, this message translates to:
  /// **'Intimacy records as plaintext'**
  String get csvExportIntimacyDesc;

  /// No description provided for @csvExportWeight.
  ///
  /// In en, this message translates to:
  /// **'Export Weight CSV'**
  String get csvExportWeight;

  /// No description provided for @csvExportWeightDesc.
  ///
  /// In en, this message translates to:
  /// **'Weight records as plaintext'**
  String get csvExportWeightDesc;

  /// No description provided for @settingsImport.
  ///
  /// In en, this message translates to:
  /// **'Import from File'**
  String get settingsImport;

  /// No description provided for @settingsExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported successfully'**
  String get settingsExportSuccess;

  /// No description provided for @settingsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get settingsExportFailed;

  /// No description provided for @settingsImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Imported successfully'**
  String get settingsImportSuccess;

  /// No description provided for @settingsImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get settingsImportFailed;

  /// No description provided for @settingsImportConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will replace all current data. Continue?'**
  String get settingsImportConfirm;

  /// No description provided for @settingsExportCSVWarning.
  ///
  /// In en, this message translates to:
  /// **'CSV data will be exported as plaintext. Continue?'**
  String get settingsExportCSVWarning;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About MyDay!!!!!'**
  String get settingsAboutTitle;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get commonName;

  /// No description provided for @commonEmojiOptional.
  ///
  /// In en, this message translates to:
  /// **'Emoji (optional)'**
  String get commonEmojiOptional;

  /// No description provided for @commonDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {item}?'**
  String commonDeleteConfirm(String item);

  /// No description provided for @commonMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}min'**
  String commonMinutes(int count);

  /// No description provided for @settingsExportSection.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get settingsExportSection;

  /// No description provided for @settingsImportSection.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get settingsImportSection;

  /// No description provided for @settingsExportFullBackup.
  ///
  /// In en, this message translates to:
  /// **'Full backup of all data'**
  String get settingsExportFullBackup;

  /// No description provided for @settingsExportJSONPlaintext.
  ///
  /// In en, this message translates to:
  /// **'All data will be exported as a ZIP archive'**
  String get settingsExportJSONPlaintext;

  /// No description provided for @settingsExportCSVPlaintext.
  ///
  /// In en, this message translates to:
  /// **'Finance transactions as plaintext'**
  String get settingsExportCSVPlaintext;

  /// No description provided for @settingsImportRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore from ZIP backup'**
  String get settingsImportRestore;

  /// No description provided for @settingsImportData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get settingsImportData;

  /// No description provided for @csvImportFinance.
  ///
  /// In en, this message translates to:
  /// **'Import Finance CSV'**
  String get csvImportFinance;

  /// No description provided for @csvImportFinanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Merge transactions from CSV (will not overwrite existing data)'**
  String get csvImportFinanceDesc;

  /// No description provided for @csvImportIntimacy.
  ///
  /// In en, this message translates to:
  /// **'Import Intimacy CSV'**
  String get csvImportIntimacy;

  /// No description provided for @csvImportIntimacyDesc.
  ///
  /// In en, this message translates to:
  /// **'Merge records from CSV (will not overwrite existing data)'**
  String get csvImportIntimacyDesc;

  /// No description provided for @csvImportConfirm.
  ///
  /// In en, this message translates to:
  /// **'CSV data will be merged into existing records. Continue?'**
  String get csvImportConfirm;

  /// No description provided for @csvImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} records successfully'**
  String csvImportSuccess(int count);

  /// No description provided for @csvImportFailed.
  ///
  /// In en, this message translates to:
  /// **'CSV import failed'**
  String get csvImportFailed;

  /// No description provided for @csvImportEmpty.
  ///
  /// In en, this message translates to:
  /// **'No valid records found in CSV'**
  String get csvImportEmpty;

  /// No description provided for @csvTemplate.
  ///
  /// In en, this message translates to:
  /// **'CSV Templates'**
  String get csvTemplate;

  /// No description provided for @csvTemplateFinance.
  ///
  /// In en, this message translates to:
  /// **'Download Finance Template'**
  String get csvTemplateFinance;

  /// No description provided for @csvTemplateIntimacy.
  ///
  /// In en, this message translates to:
  /// **'Download Intimacy Template'**
  String get csvTemplateIntimacy;

  /// No description provided for @csvTemplateSaved.
  ///
  /// In en, this message translates to:
  /// **'Template saved'**
  String get csvTemplateSaved;

  /// No description provided for @settingsWebDAVDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get settingsWebDAVDisconnect;

  /// No description provided for @settingsWebDAVConfigSaved.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved'**
  String get settingsWebDAVConfigSaved;

  /// No description provided for @settingsWebDAVConfigRemoved.
  ///
  /// In en, this message translates to:
  /// **'Configuration removed'**
  String get settingsWebDAVConfigRemoved;

  /// No description provided for @commonDontAskMinutes.
  ///
  /// In en, this message translates to:
  /// **'Don\'t ask for 5 minutes'**
  String get commonDontAskMinutes;

  /// No description provided for @intimacyHideConfirm.
  ///
  /// In en, this message translates to:
  /// **'Hiding the module will not delete your data. You can re-enable it anytime.'**
  String get intimacyHideConfirm;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get settingsLicenses;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsDesktop.
  ///
  /// In en, this message translates to:
  /// **'Desktop'**
  String get settingsDesktop;

  /// No description provided for @settingsMinimizeToTray.
  ///
  /// In en, this message translates to:
  /// **'Minimize to Tray'**
  String get settingsMinimizeToTray;

  /// No description provided for @settingsCloseToTray.
  ///
  /// In en, this message translates to:
  /// **'Close to Tray'**
  String get settingsCloseToTray;

  /// No description provided for @financeBankPresets.
  ///
  /// In en, this message translates to:
  /// **'Bank Presets'**
  String get financeBankPresets;

  /// No description provided for @financeBankSearch.
  ///
  /// In en, this message translates to:
  /// **'Search bank or app...'**
  String get financeBankSearch;

  /// No description provided for @financeBankNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching banks found'**
  String get financeBankNoResults;

  /// No description provided for @financeSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get financeSubscriptions;

  /// No description provided for @financeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get financeSubscription;

  /// No description provided for @financeAddSubscription.
  ///
  /// In en, this message translates to:
  /// **'Add Subscription'**
  String get financeAddSubscription;

  /// No description provided for @financeEditSubscription.
  ///
  /// In en, this message translates to:
  /// **'Edit Subscription'**
  String get financeEditSubscription;

  /// No description provided for @financeStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get financeStartDate;

  /// No description provided for @financeTrialDays.
  ///
  /// In en, this message translates to:
  /// **'Trial Days'**
  String get financeTrialDays;

  /// No description provided for @financeBillingCycle.
  ///
  /// In en, this message translates to:
  /// **'Billing Cycle'**
  String get financeBillingCycle;

  /// No description provided for @financeBillingCycleMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get financeBillingCycleMonthly;

  /// No description provided for @financeBillingCycleYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get financeBillingCycleYearly;

  /// No description provided for @financeEveryXMonths.
  ///
  /// In en, this message translates to:
  /// **'Every {count} month(s)'**
  String financeEveryXMonths(int count);

  /// No description provided for @financeEveryXYears.
  ///
  /// In en, this message translates to:
  /// **'Every {count} year(s)'**
  String financeEveryXYears(int count);

  /// No description provided for @financeBillingDay.
  ///
  /// In en, this message translates to:
  /// **'Billing Day'**
  String get financeBillingDay;

  /// No description provided for @financeBillingMonth.
  ///
  /// In en, this message translates to:
  /// **'Billing Month'**
  String get financeBillingMonth;

  /// No description provided for @financeMonthlyDue.
  ///
  /// In en, this message translates to:
  /// **'Monthly Due'**
  String get financeMonthlyDue;

  /// No description provided for @financeMonthlyAvg.
  ///
  /// In en, this message translates to:
  /// **'Monthly Avg'**
  String get financeMonthlyAvg;

  /// No description provided for @financeYearlyAvg.
  ///
  /// In en, this message translates to:
  /// **'Yearly Avg'**
  String get financeYearlyAvg;

  /// No description provided for @financeNoSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions'**
  String get financeNoSubscriptions;

  /// No description provided for @financeActiveSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get financeActiveSubscriptions;

  /// No description provided for @financeHistoricalSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get financeHistoricalSubscriptions;

  /// No description provided for @financeCancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription'**
  String get financeCancelSubscription;

  /// No description provided for @financeCancelImmediate.
  ///
  /// In en, this message translates to:
  /// **'Cancel Now'**
  String get financeCancelImmediate;

  /// No description provided for @financeCancelAtExpiry.
  ///
  /// In en, this message translates to:
  /// **'Cancel at Expiry'**
  String get financeCancelAtExpiry;

  /// No description provided for @financeNextBilling.
  ///
  /// In en, this message translates to:
  /// **'Next Billing'**
  String get financeNextBilling;

  /// No description provided for @financeExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get financeExpiryDate;

  /// No description provided for @financeTotalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get financeTotalSpent;

  /// No description provided for @financeImportHistory.
  ///
  /// In en, this message translates to:
  /// **'Import Historical Transactions'**
  String get financeImportHistory;

  /// No description provided for @financeImportHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Start date is before today. Import historical transactions?'**
  String get financeImportHistoryDesc;

  /// No description provided for @financeThisSubscription.
  ///
  /// In en, this message translates to:
  /// **'this subscription'**
  String get financeThisSubscription;

  /// No description provided for @financeCancelledOn.
  ///
  /// In en, this message translates to:
  /// **'Cancelled {date}'**
  String financeCancelledOn(String date);

  /// No description provided for @financeInterval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get financeInterval;

  /// No description provided for @financeImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get financeImage;

  /// No description provided for @financePickImage.
  ///
  /// In en, this message translates to:
  /// **'Pick Image'**
  String get financePickImage;

  /// No description provided for @financeChangeImage.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get financeChangeImage;

  /// No description provided for @financeUpcomingRenewals.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Renewals'**
  String get financeUpcomingRenewals;

  /// No description provided for @financeSubscriptionReminder.
  ///
  /// In en, this message translates to:
  /// **'Subscription Reminder'**
  String get financeSubscriptionReminder;

  /// No description provided for @financeReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Notification Time'**
  String get financeReminderTime;

  /// No description provided for @financeReminderEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notify upcoming renewals'**
  String get financeReminderEnabled;

  /// No description provided for @financeSubscriptionDueSoon.
  ///
  /// In en, this message translates to:
  /// **'{name} is due in {days} day(s)'**
  String financeSubscriptionDueSoon(String name, int days);

  /// No description provided for @financeSubscriptionDueToday.
  ///
  /// In en, this message translates to:
  /// **'{name} is due today'**
  String financeSubscriptionDueToday(String name);

  /// No description provided for @financeSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get financeSortBy;

  /// No description provided for @financeSortByRenewal.
  ///
  /// In en, this message translates to:
  /// **'By Renewal Date'**
  String get financeSortByRenewal;

  /// No description provided for @financeSortByName.
  ///
  /// In en, this message translates to:
  /// **'By Name'**
  String get financeSortByName;

  /// No description provided for @financeSortCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get financeSortCustom;

  /// No description provided for @financeSortReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get financeSortReorder;

  /// No description provided for @financeSortDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get financeSortDone;

  /// No description provided for @financeRestoreSubscription.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get financeRestoreSubscription;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupTitle;

  /// No description provided for @backupLocalOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Backups are stored locally on this device only. Use WebDAV Sync for cloud backup.'**
  String get backupLocalOnlyNote;

  /// No description provided for @backupSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get backupSettings;

  /// No description provided for @backupAutoDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily Auto-Backup'**
  String get backupAutoDaily;

  /// No description provided for @backupAutoDailyDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically create backup once per day'**
  String get backupAutoDailyDesc;

  /// No description provided for @backupRetention.
  ///
  /// In en, this message translates to:
  /// **'Keep backups'**
  String get backupRetention;

  /// No description provided for @backupRetentionForever.
  ///
  /// In en, this message translates to:
  /// **'Forever'**
  String get backupRetentionForever;

  /// No description provided for @backupRetentionDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String backupRetentionDays(int count);

  /// No description provided for @backupManual.
  ///
  /// In en, this message translates to:
  /// **'Manual Backup'**
  String get backupManual;

  /// No description provided for @backupCreateNow.
  ///
  /// In en, this message translates to:
  /// **'Create Backup Now'**
  String get backupCreateNow;

  /// No description provided for @backupHistory.
  ///
  /// In en, this message translates to:
  /// **'Backups ({count})'**
  String backupHistory(int count);

  /// No description provided for @backupEmpty.
  ///
  /// In en, this message translates to:
  /// **'No backups yet'**
  String get backupEmpty;

  /// No description provided for @backupCreated.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully'**
  String get backupCreated;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed'**
  String get backupFailed;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupRestore;

  /// No description provided for @backupRestoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Restore'**
  String get backupRestoreConfirmTitle;

  /// No description provided for @backupRestoreConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'This will replace selected module data. Continue?'**
  String get backupRestoreConfirmDesc;

  /// No description provided for @backupRestoreSelectModules.
  ///
  /// In en, this message translates to:
  /// **'Select Modules to Restore'**
  String get backupRestoreSelectModules;

  /// No description provided for @backupRestoreAll.
  ///
  /// In en, this message translates to:
  /// **'All Modules'**
  String get backupRestoreAll;

  /// No description provided for @backupRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restore successful. Please restart the app.'**
  String get backupRestoreSuccess;

  /// No description provided for @backupRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get backupRestoreFailed;

  /// No description provided for @backupDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Backup'**
  String get backupDeleteConfirmTitle;

  /// No description provided for @backupDeleteConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'This backup will be permanently deleted.'**
  String get backupDeleteConfirmDesc;

  /// No description provided for @backupModuleTodo.
  ///
  /// In en, this message translates to:
  /// **'Todo'**
  String get backupModuleTodo;

  /// No description provided for @backupModuleFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get backupModuleFinance;

  /// No description provided for @backupModuleRates.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rates'**
  String get backupModuleRates;

  /// No description provided for @backupModuleIntimacy.
  ///
  /// In en, this message translates to:
  /// **'Intimacy'**
  String get backupModuleIntimacy;

  /// No description provided for @intimacyRecordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String intimacyRecordCount(int count);

  /// No description provided for @weightTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightTitle;

  /// No description provided for @weightSetHeight.
  ///
  /// In en, this message translates to:
  /// **'Set Height'**
  String get weightSetHeight;

  /// No description provided for @weightNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No weight records yet'**
  String get weightNoRecords;

  /// No description provided for @weightAddRecord.
  ///
  /// In en, this message translates to:
  /// **'Add Record'**
  String get weightAddRecord;

  /// No description provided for @weightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKg;

  /// No description provided for @weightHeightCm.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get weightHeightCm;

  /// No description provided for @weightNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get weightNote;

  /// No description provided for @weightNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Optional note'**
  String get weightNoteHint;

  /// No description provided for @weightChart.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get weightChart;

  /// No description provided for @weightAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get weightAll;

  /// No description provided for @weightHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get weightHistory;

  /// No description provided for @weightShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all records'**
  String get weightShowAll;

  /// No description provided for @weightDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get weightDays;

  /// No description provided for @weightDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String get weightDaysAgo;

  /// No description provided for @weightWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'weeks ago'**
  String get weightWeeksAgo;

  /// No description provided for @weightToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get weightToday;

  /// No description provided for @weightYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get weightYesterday;

  /// No description provided for @weightRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get weightRecent;

  /// No description provided for @weightExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get weightExportCsv;

  /// No description provided for @weightExportCsvSuccess.
  ///
  /// In en, this message translates to:
  /// **'Weight data exported successfully'**
  String get weightExportCsvSuccess;

  /// No description provided for @weightExportCsvEmpty.
  ///
  /// In en, this message translates to:
  /// **'No weight records to export'**
  String get weightExportCsvEmpty;

  /// No description provided for @csvImportWeight.
  ///
  /// In en, this message translates to:
  /// **'Import Weight CSV'**
  String get csvImportWeight;

  /// No description provided for @csvImportWeightDesc.
  ///
  /// In en, this message translates to:
  /// **'Merge weight records from CSV (Date, Time, Weight)'**
  String get csvImportWeightDesc;

  /// No description provided for @csvTemplateWeight.
  ///
  /// In en, this message translates to:
  /// **'Download Weight Template'**
  String get csvTemplateWeight;

  /// No description provided for @financeSubscriptionPresets.
  ///
  /// In en, this message translates to:
  /// **'Quick Fill'**
  String get financeSubscriptionPresets;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
