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

  /// Purpose: Return the localized instance for the current build context.
  /// Inputs: `context`.
  /// Returns: `AppLocalizations?`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
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

  /// Purpose: Return the localized string for `appTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MyDay!!!!!'**
  String get appTitle;

  /// Purpose: Return the localized string for `navTodo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @navTodo.
  ///
  /// In en, this message translates to:
  /// **'Todo'**
  String get navTodo;

  /// Purpose: Return the localized string for `navFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @navFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get navFinance;

  /// Purpose: Return the localized string for `navWeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @navWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get navWeight;

  /// Purpose: Return the localized string for `navIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @navIntimacy.
  ///
  /// In en, this message translates to:
  /// **'Intimacy'**
  String get navIntimacy;

  /// Purpose: Return the localized string for `navSettings`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Purpose: Return the localized string for `todoSectionDaily`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoSectionDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get todoSectionDaily;

  /// Purpose: Return the localized string for `todoSectionRoutine`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoSectionRoutine.
  ///
  /// In en, this message translates to:
  /// **'Routine'**
  String get todoSectionRoutine;

  /// Purpose: Return the localized string for `todoSectionWork`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoSectionWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get todoSectionWork;

  /// Purpose: Return the localized string for `todoAddTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoAddTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get todoAddTask;

  /// Purpose: Return the localized string for `todoEditTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoEditTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get todoEditTask;

  /// Purpose: Return the localized string for `todoTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get todoTitle;

  /// Purpose: Return the localized string for `todoNote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get todoNote;

  /// Purpose: Return the localized string for `todoNoteHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add an optional note'**
  String get todoNoteHint;

  /// Purpose: Return the localized string for `todoSubtasks`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoSubtasks.
  ///
  /// In en, this message translates to:
  /// **'Subtasks'**
  String get todoSubtasks;

  /// Purpose: Return the localized string for `todoAddSubtask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoAddSubtask.
  ///
  /// In en, this message translates to:
  /// **'Add Subtask'**
  String get todoAddSubtask;

  /// Purpose: Return the localized string for `todoReminderTime`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get todoReminderTime;

  /// Purpose: Return the localized string for `todoNoTasks`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks'**
  String get todoNoTasks;

  /// Purpose: Return the localized string for `todoType`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get todoType;

  /// Purpose: Return the localized string for `todoEmoji`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoEmoji.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get todoEmoji;

  /// Purpose: Return the localized string for `todoDailyTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoDailyTask.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get todoDailyTask;

  /// Purpose: Return the localized string for `todoRoutineTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoRoutineTask.
  ///
  /// In en, this message translates to:
  /// **'Routine Once'**
  String get todoRoutineTask;

  /// Purpose: Return the localized string for `todoWorkTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoWorkTask.
  ///
  /// In en, this message translates to:
  /// **'Work Once'**
  String get todoWorkTask;

  /// Purpose: Implement the todo created date behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoCreatedDate.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String todoCreatedDate(String date);

  /// Purpose: Implement the todo start date behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date: {date}'**
  String todoStartDate(String date);

  /// Purpose: Implement the todo deleted date behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoDeletedDate.
  ///
  /// In en, this message translates to:
  /// **'Deleted: {date}'**
  String todoDeletedDate(String date);

  /// Purpose: Return the localized string for `todoPermanentDelete`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoPermanentDelete.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete'**
  String get todoPermanentDelete;

  /// Purpose: Return the localized string for `todoPermanentDeleteConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoPermanentDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove this task and all its history. Continue?'**
  String get todoPermanentDeleteConfirm;

  /// Purpose: Return the localized string for `todoMorningReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoMorningReminder.
  ///
  /// In en, this message translates to:
  /// **'Morning Plan Reminder'**
  String get todoMorningReminder;

  /// Purpose: Return the localized string for `todoCompletionReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoCompletionReminder.
  ///
  /// In en, this message translates to:
  /// **'Completion Check Reminder'**
  String get todoCompletionReminder;

  /// Purpose: Return the localized string for `todoSetReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoSetReminder.
  ///
  /// In en, this message translates to:
  /// **'Set Reminder'**
  String get todoSetReminder;

  /// Purpose: Return the localized string for `todoClearReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoClearReminder.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get todoClearReminder;

  /// Purpose: Implement the todo reminder set behavior for this file.
  /// Inputs: `time`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoReminderSet.
  ///
  /// In en, this message translates to:
  /// **'Reminder set for {time}'**
  String todoReminderSet(String time);

  /// Purpose: Return the localized string for `todoCompleted`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get todoCompleted;

  /// Purpose: Return the localized string for `todoDueDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get todoDueDate;

  /// Purpose: Return the localized string for `todoSetDueDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoSetDueDate.
  ///
  /// In en, this message translates to:
  /// **'Set due date (optional)'**
  String get todoSetDueDate;

  /// Purpose: Return the localized string for `todoCustomEmoji`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoCustomEmoji.
  ///
  /// In en, this message translates to:
  /// **'Custom Emoji'**
  String get todoCustomEmoji;

  /// Purpose: Return the localized string for `todoCustomEmojiHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoCustomEmojiHint.
  ///
  /// In en, this message translates to:
  /// **'Enter an emoji'**
  String get todoCustomEmojiHint;

  /// Purpose: Return the localized string for `todoEditSubtask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoEditSubtask.
  ///
  /// In en, this message translates to:
  /// **'Edit Subtask'**
  String get todoEditSubtask;

  /// Purpose: Implement the todo subtasks progress behavior for this file.
  /// Inputs: `done`, `total`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoSubtasksProgress.
  ///
  /// In en, this message translates to:
  /// **'Subtasks: {done}/{total}'**
  String todoSubtasksProgress(int done, int total);

  /// Purpose: Implement the todo task due behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoTaskDue.
  ///
  /// In en, this message translates to:
  /// **'Due: {date}'**
  String todoTaskDue(String date);

  /// Purpose: Implement the todo task note behavior for this file.
  /// Inputs: `note`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoTaskNote.
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String todoTaskNote(String note);

  /// Purpose: Return the localized string for `todoThisTask`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoThisTask.
  ///
  /// In en, this message translates to:
  /// **'this task'**
  String get todoThisTask;

  /// Purpose: Return the localized string for `financeTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeTitle.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get financeTitle;

  /// Purpose: Return the localized string for `financeMonthlyExpense`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeMonthlyExpense.
  ///
  /// In en, this message translates to:
  /// **'Monthly Expense'**
  String get financeMonthlyExpense;

  /// Purpose: Return the localized string for `financeTotalAssets`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeTotalAssets.
  ///
  /// In en, this message translates to:
  /// **'Total Assets'**
  String get financeTotalAssets;

  /// Purpose: Return the localized string for `financeAccounts`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get financeAccounts;

  /// Purpose: Return the localized string for `financeCategories`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get financeCategories;

  /// Purpose: Return the localized string for `financeTrends`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeTrends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get financeTrends;

  /// Purpose: Return the localized string for `financeAnalysis`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get financeAnalysis;

  /// Purpose: Return the localized string for `financeExchangeRates`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeExchangeRates.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rates'**
  String get financeExchangeRates;

  /// Purpose: Return the localized string for `financeRefreshRates`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeRefreshRates.
  ///
  /// In en, this message translates to:
  /// **'Refresh Rates'**
  String get financeRefreshRates;

  /// Purpose: Return the localized string for `financeAddTransaction`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get financeAddTransaction;

  /// Purpose: Return the localized string for `financeEditTransaction`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeEditTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get financeEditTransaction;

  /// Purpose: Return the localized string for `financeExpense`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get financeExpense;

  /// Purpose: Return the localized string for `financeIncome`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get financeIncome;

  /// Purpose: Return the localized string for `financeTransfer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get financeTransfer;

  /// Purpose: Return the localized string for `financeAmount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get financeAmount;

  /// Purpose: Return the localized string for `financeNote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get financeNote;

  /// Purpose: Return the localized string for `financeCategory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get financeCategory;

  /// Purpose: Return the localized string for `financeAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get financeAccount;

  /// Purpose: Return the localized string for `financeFromAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeFromAccount.
  ///
  /// In en, this message translates to:
  /// **'From Account'**
  String get financeFromAccount;

  /// Purpose: Return the localized string for `financeToAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeToAccount.
  ///
  /// In en, this message translates to:
  /// **'To Account'**
  String get financeToAccount;

  /// Purpose: Return the localized string for `financeCurrency`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get financeCurrency;

  /// Purpose: Return the localized string for `financeDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get financeDate;

  /// Purpose: Return the localized string for `financeNoTransactions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get financeNoTransactions;

  /// Purpose: Return the localized string for `financeForceBalance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeForceBalance.
  ///
  /// In en, this message translates to:
  /// **'Force Balance'**
  String get financeForceBalance;

  /// Purpose: Return the localized string for `financeCurrentBalance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get financeCurrentBalance;

  /// Purpose: Return the localized string for `financeAddAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeAddAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get financeAddAccount;

  /// Purpose: Return the localized string for `financeEditAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeEditAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit Account'**
  String get financeEditAccount;

  /// Purpose: Return the localized string for `financeAddCategory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get financeAddCategory;

  /// Purpose: Return the localized string for `financeEditCategory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeEditCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get financeEditCategory;

  /// Purpose: Return the localized string for `financeName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get financeName;

  /// Purpose: Return the localized string for `financeBankApp`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeBankApp.
  ///
  /// In en, this message translates to:
  /// **'Bank / App'**
  String get financeBankApp;

  /// Purpose: Return the localized string for `financeCardNumber`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card Number (optional)'**
  String get financeCardNumber;

  /// Purpose: Return the localized string for `financeExpiry`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get financeExpiry;

  /// Purpose: Return the localized string for `financeSecurityCode`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeSecurityCode.
  ///
  /// In en, this message translates to:
  /// **'Security Code'**
  String get financeSecurityCode;

  /// Purpose: Return the localized string for `financeIcon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get financeIcon;

  /// Purpose: Return the localized string for `financeEmoji`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeEmoji.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get financeEmoji;

  /// Purpose: Return the localized string for `financeCategoryHintExpense`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCategoryHintExpense.
  ///
  /// In en, this message translates to:
  /// **'e.g. Food, Transport'**
  String get financeCategoryHintExpense;

  /// Purpose: Return the localized string for `financeCategoryHintIncome`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCategoryHintIncome.
  ///
  /// In en, this message translates to:
  /// **'e.g. Salary, Investment'**
  String get financeCategoryHintIncome;

  /// Purpose: Return the localized string for `financeThisTransaction`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeThisTransaction.
  ///
  /// In en, this message translates to:
  /// **'this transaction'**
  String get financeThisTransaction;

  /// Purpose: Return the localized string for `financeNoAccounts`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get financeNoAccounts;

  /// Purpose: Return the localized string for `financeNoCategories`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get financeNoCategories;

  /// Purpose: Return the localized string for `financeByYear`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeByYear.
  ///
  /// In en, this message translates to:
  /// **'By Year'**
  String get financeByYear;

  /// Purpose: Return the localized string for `financeByMonth`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeByMonth.
  ///
  /// In en, this message translates to:
  /// **'By Month'**
  String get financeByMonth;

  /// Purpose: Return the localized string for `financeByDay`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeByDay.
  ///
  /// In en, this message translates to:
  /// **'By Day'**
  String get financeByDay;

  /// Purpose: Return the localized string for `financeCustomRange`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCustomRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get financeCustomRange;

  /// Purpose: Return the localized string for `financeExpenseTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeExpenseTrend.
  ///
  /// In en, this message translates to:
  /// **'Expense Trend'**
  String get financeExpenseTrend;

  /// Purpose: Return the localized string for `financeIncomeTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeIncomeTrend.
  ///
  /// In en, this message translates to:
  /// **'Income Trend'**
  String get financeIncomeTrend;

  /// Purpose: Return the localized string for `financeAssetsTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeAssetsTrend.
  ///
  /// In en, this message translates to:
  /// **'Assets Trend'**
  String get financeAssetsTrend;

  /// Purpose: Return the localized string for `financeThisCategory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeThisCategory.
  ///
  /// In en, this message translates to:
  /// **'this category'**
  String get financeThisCategory;

  /// Purpose: Implement the finance no categories of type behavior for this file.
  /// Inputs: `type`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeNoCategoriesOfType.
  ///
  /// In en, this message translates to:
  /// **'No {type} categories'**
  String financeNoCategoriesOfType(String type);

  /// Purpose: Return the localized string for `financeImportDefaults`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeImportDefaults.
  ///
  /// In en, this message translates to:
  /// **'Import Defaults'**
  String get financeImportDefaults;

  /// Purpose: Return the localized string for `financeCatFood`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCatFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get financeCatFood;

  /// Purpose: Return the localized string for `financeCatTransport`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCatTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get financeCatTransport;

  /// Purpose: Return the localized string for `financeCatShopping`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCatShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get financeCatShopping;

  /// Purpose: Return the localized string for `financeCatRent`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCatRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get financeCatRent;

  /// Purpose: Return the localized string for `financeCatDigital`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCatDigital.
  ///
  /// In en, this message translates to:
  /// **'Digital'**
  String get financeCatDigital;

  /// Purpose: Return the localized string for `financeCatEntertainment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCatEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get financeCatEntertainment;

  /// Purpose: Return the localized string for `financeCatHealthcare`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCatHealthcare.
  ///
  /// In en, this message translates to:
  /// **'Healthcare'**
  String get financeCatHealthcare;

  /// Purpose: Return the localized string for `financeCatEducation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCatEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get financeCatEducation;

  /// Purpose: Return the localized string for `financeCatSalary`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCatSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get financeCatSalary;

  /// Purpose: Return the localized string for `financeCatBonus`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCatBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get financeCatBonus;

  /// Purpose: Return the localized string for `financeCatInvestment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCatInvestment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get financeCatInvestment;

  /// Purpose: Return the localized string for `financeCatFreelance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCatFreelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get financeCatFreelance;

  /// Purpose: Return the localized string for `intimacyTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Intimacy'**
  String get intimacyTitle;

  /// Purpose: Return the localized string for `intimacyNewRecord`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyNewRecord.
  ///
  /// In en, this message translates to:
  /// **'New Record'**
  String get intimacyNewRecord;

  /// Purpose: Return the localized string for `intimacyEditRecord`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyEditRecord.
  ///
  /// In en, this message translates to:
  /// **'Edit Record'**
  String get intimacyEditRecord;

  /// Purpose: Return the localized string for `intimacySolo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacySolo.
  ///
  /// In en, this message translates to:
  /// **'Solo'**
  String get intimacySolo;

  /// Purpose: Return the localized string for `intimacyPartner`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyPartner.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get intimacyPartner;

  /// Purpose: Return the localized string for `intimacyPartners`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyPartners.
  ///
  /// In en, this message translates to:
  /// **'Partners'**
  String get intimacyPartners;

  /// Purpose: Return the localized string for `intimacyAddPartner`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyAddPartner.
  ///
  /// In en, this message translates to:
  /// **'Add Partner'**
  String get intimacyAddPartner;

  /// Purpose: Return the localized string for `intimacyEditPartner`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyEditPartner.
  ///
  /// In en, this message translates to:
  /// **'Edit Partner'**
  String get intimacyEditPartner;

  /// Purpose: Return the localized string for `intimacyToys`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyToys.
  ///
  /// In en, this message translates to:
  /// **'Toys'**
  String get intimacyToys;

  /// Purpose: Return the localized string for `intimacyAddToy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyAddToy.
  ///
  /// In en, this message translates to:
  /// **'Add Toy'**
  String get intimacyAddToy;

  /// Purpose: Return the localized string for `intimacyEditToy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyEditToy.
  ///
  /// In en, this message translates to:
  /// **'Edit Toy'**
  String get intimacyEditToy;

  /// Purpose: Return the localized string for `intimacyPleasure`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyPleasure.
  ///
  /// In en, this message translates to:
  /// **'Pleasure'**
  String get intimacyPleasure;

  /// Purpose: Return the localized string for `intimacyDuration`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get intimacyDuration;

  /// Purpose: Return the localized string for `intimacyLocation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyLocation.
  ///
  /// In en, this message translates to:
  /// **'Location (optional)'**
  String get intimacyLocation;

  /// Purpose: Return the localized string for `intimacyNotes`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get intimacyNotes;

  /// Purpose: Return the localized string for `intimacyOrgasm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyOrgasm.
  ///
  /// In en, this message translates to:
  /// **'Had Orgasm?'**
  String get intimacyOrgasm;

  /// Purpose: Return the localized string for `intimacyWatchedPorn`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyWatchedPorn.
  ///
  /// In en, this message translates to:
  /// **'Watched Porn?'**
  String get intimacyWatchedPorn;

  /// Purpose: Return the localized string for `intimacyTimer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyTimer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get intimacyTimer;

  /// Purpose: Return the localized string for `intimacyNoRecords`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No records'**
  String get intimacyNoRecords;

  /// Purpose: Return the localized string for `intimacyNoPartners`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyNoPartners.
  ///
  /// In en, this message translates to:
  /// **'No partners yet'**
  String get intimacyNoPartners;

  /// Purpose: Return the localized string for `intimacyNoToys`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyNoToys.
  ///
  /// In en, this message translates to:
  /// **'No toys yet'**
  String get intimacyNoToys;

  /// Purpose: Return the localized string for `intimacyNoPartnersHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyNoPartnersHint.
  ///
  /// In en, this message translates to:
  /// **'No partners — add one in Settings'**
  String get intimacyNoPartnersHint;

  /// Purpose: Return the localized string for `intimacyShowAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get intimacyShowAll;

  /// Purpose: Return the localized string for `intimacyAllRecords`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyAllRecords.
  ///
  /// In en, this message translates to:
  /// **'All Records'**
  String get intimacyAllRecords;

  /// Purpose: Return the localized string for `intimacyStart`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get intimacyStart;

  /// Purpose: Return the localized string for `intimacyPause`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get intimacyPause;

  /// Purpose: Return the localized string for `intimacyResume`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get intimacyResume;

  /// Purpose: Return the localized string for `intimacyStopSave`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyStopSave.
  ///
  /// In en, this message translates to:
  /// **'Stop & Save'**
  String get intimacyStopSave;

  /// Purpose: Return the localized string for `intimacyReset`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get intimacyReset;

  /// Purpose: Return the localized string for `intimacyTimerStartedAt`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyTimerStartedAt.
  ///
  /// In en, this message translates to:
  /// **'Started at'**
  String get intimacyTimerStartedAt;

  /// Purpose: Return the localized string for `intimacyTimerHistory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyTimerHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get intimacyTimerHistory;

  /// Purpose: Return the localized string for `intimacyTimerClearHistory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyTimerClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get intimacyTimerClearHistory;

  /// Purpose: Return the localized string for `intimacyTimerRetention3d`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyTimerRetention3d.
  ///
  /// In en, this message translates to:
  /// **'3 days'**
  String get intimacyTimerRetention3d;

  /// Purpose: Return the localized string for `intimacyTimerRetention7d`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyTimerRetention7d.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get intimacyTimerRetention7d;

  /// Purpose: Return the localized string for `intimacyTimerRetention14d`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyTimerRetention14d.
  ///
  /// In en, this message translates to:
  /// **'14 days'**
  String get intimacyTimerRetention14d;

  /// Purpose: Return the localized string for `intimacyTimerRetentionForever`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyTimerRetentionForever.
  ///
  /// In en, this message translates to:
  /// **'Forever'**
  String get intimacyTimerRetentionForever;

  /// Purpose: Return the localized string for `intimacyManage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get intimacyManage;

  /// Purpose: Return the localized string for `intimacyModuleVisible`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyModuleVisible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get intimacyModuleVisible;

  /// Purpose: Return the localized string for `intimacyModuleHidden`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyModuleHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get intimacyModuleHidden;

  /// Purpose: Return the localized string for `intimacySortNewest`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacySortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get intimacySortNewest;

  /// Purpose: Return the localized string for `intimacySortOldest`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacySortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get intimacySortOldest;

  /// Purpose: Return the localized string for `intimacySortPleasure`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacySortPleasure.
  ///
  /// In en, this message translates to:
  /// **'Highest pleasure'**
  String get intimacySortPleasure;

  /// Purpose: Return the localized string for `intimacySortDuration`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacySortDuration.
  ///
  /// In en, this message translates to:
  /// **'Longest duration'**
  String get intimacySortDuration;

  /// Purpose: Return the localized string for `intimacyFilterAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get intimacyFilterAll;

  /// Purpose: Return the localized string for `intimacyFilterSolo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyFilterSolo.
  ///
  /// In en, this message translates to:
  /// **'Solo'**
  String get intimacyFilterSolo;

  /// Purpose: Return the localized string for `intimacyFilterPartnered`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyFilterPartnered.
  ///
  /// In en, this message translates to:
  /// **'With partner'**
  String get intimacyFilterPartnered;

  /// Purpose: Return the localized string for `intimacyFilterOrgasm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyFilterOrgasm.
  ///
  /// In en, this message translates to:
  /// **'Had orgasm'**
  String get intimacyFilterOrgasm;

  /// Purpose: Return the localized string for `intimacyFilterNoOrgasm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyFilterNoOrgasm.
  ///
  /// In en, this message translates to:
  /// **'No orgasm'**
  String get intimacyFilterNoOrgasm;

  /// Purpose: Return the localized string for `intimacyExportCsv`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get intimacyExportCsv;

  /// Purpose: Return the localized string for `intimacyExportCsvSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyExportCsvSuccess.
  ///
  /// In en, this message translates to:
  /// **'CSV exported successfully'**
  String get intimacyExportCsvSuccess;

  /// Purpose: Return the localized string for `intimacyExportCsvEmpty`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyExportCsvEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records to export'**
  String get intimacyExportCsvEmpty;

  /// Purpose: Return the localized string for `intimacyStartDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get intimacyStartDate;

  /// Purpose: Return the localized string for `intimacyEndDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyEndDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get intimacyEndDate;

  /// Purpose: Return the localized string for `intimacyPurchaseDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyPurchaseDate.
  ///
  /// In en, this message translates to:
  /// **'Purchase Date'**
  String get intimacyPurchaseDate;

  /// Purpose: Return the localized string for `intimacyRetiredDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyRetiredDate.
  ///
  /// In en, this message translates to:
  /// **'Retired Date'**
  String get intimacyRetiredDate;

  /// Purpose: Return the localized string for `intimacyBreakUp`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyBreakUp.
  ///
  /// In en, this message translates to:
  /// **'Break Up'**
  String get intimacyBreakUp;

  /// Purpose: Return the localized string for `intimacyRetire`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyRetire.
  ///
  /// In en, this message translates to:
  /// **'Retire'**
  String get intimacyRetire;

  /// Purpose: Return the localized string for `settingsTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Purpose: Return the localized string for `settingsGeneral`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// Purpose: Return the localized string for `settingsLanguage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Purpose: Return the localized string for `settingsTheme`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Purpose: Return the localized string for `settingsThemeSystem`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// Purpose: Return the localized string for `settingsThemeLight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Purpose: Return the localized string for `settingsThemeDark`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Purpose: Return the localized string for `settingsPrivacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// Purpose: Return the localized string for `settingsIntimacyModule`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsIntimacyModule.
  ///
  /// In en, this message translates to:
  /// **'Intimacy Module'**
  String get settingsIntimacyModule;

  /// Purpose: Return the localized string for `settingsData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// Purpose: Return the localized string for `settingsStorageLocation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsStorageLocation.
  ///
  /// In en, this message translates to:
  /// **'Storage Location'**
  String get settingsStorageLocation;

  /// Purpose: Return the localized string for `settingsStoragePathHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsStoragePathHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the directory path for storing data. Leave empty to use default.'**
  String get settingsStoragePathHint;

  /// Purpose: Return the localized string for `settingsDirectoryPath`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsDirectoryPath.
  ///
  /// In en, this message translates to:
  /// **'Directory Path'**
  String get settingsDirectoryPath;

  /// Purpose: Return the localized string for `settingsResetDefault`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsResetDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default'**
  String get settingsResetDefault;

  /// Purpose: Return the localized string for `settingsResetDefaultLocation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsResetDefaultLocation.
  ///
  /// In en, this message translates to:
  /// **'Reset to default location'**
  String get settingsResetDefaultLocation;

  /// Purpose: Return the localized string for `settingsStoragePathUpdated`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsStoragePathUpdated.
  ///
  /// In en, this message translates to:
  /// **'Storage path updated'**
  String get settingsStoragePathUpdated;

  /// Purpose: Return the localized string for `settingsOpenDataFolder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsOpenDataFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Data Folder'**
  String get settingsOpenDataFolder;

  /// Purpose: Return the localized string for `settingsOpenDataFolderDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsOpenDataFolderDesc.
  ///
  /// In en, this message translates to:
  /// **'Open the application data directory'**
  String get settingsOpenDataFolderDesc;

  /// Purpose: Return the localized string for `settingsWebDAVSync`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVSync.
  ///
  /// In en, this message translates to:
  /// **'WebDAV Sync'**
  String get settingsWebDAVSync;

  /// Purpose: Return the localized string for `settingsWebDAVNotConfigured`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get settingsWebDAVNotConfigured;

  /// Purpose: Return the localized string for `settingsWebDAVConfigured`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVConfigured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get settingsWebDAVConfigured;

  /// Purpose: Return the localized string for `settingsWebDAVServerURL`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVServerURL.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get settingsWebDAVServerURL;

  /// Purpose: Return the localized string for `settingsWebDAVUsername`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get settingsWebDAVUsername;

  /// Purpose: Return the localized string for `settingsWebDAVPassword`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get settingsWebDAVPassword;

  /// Purpose: Return the localized string for `settingsWebDAVRemotePath`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVRemotePath.
  ///
  /// In en, this message translates to:
  /// **'Remote Path'**
  String get settingsWebDAVRemotePath;

  /// Purpose: Return the localized string for `settingsWebDAVTestConnection`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get settingsWebDAVTestConnection;

  /// Purpose: Return the localized string for `settingsWebDAVConnectionSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVConnectionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection successful'**
  String get settingsWebDAVConnectionSuccess;

  /// Purpose: Return the localized string for `settingsWebDAVConnectionFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get settingsWebDAVConnectionFailed;

  /// Purpose: Return the localized string for `settingsWebDAVSyncNow`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get settingsWebDAVSyncNow;

  /// Purpose: Return the localized string for `settingsWebDAVAutoSync`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVAutoSync.
  ///
  /// In en, this message translates to:
  /// **'Auto Sync'**
  String get settingsWebDAVAutoSync;

  /// Purpose: Return the localized string for `settingsWebDAVAutoSyncDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVAutoSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically sync after editing and when the app resumes'**
  String get settingsWebDAVAutoSyncDesc;

  /// Purpose: Return the localized string for `settingsWebDAVSyncing`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get settingsWebDAVSyncing;

  /// Purpose: Return the localized string for `settingsWebDAVSyncSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sync completed'**
  String get settingsWebDAVSyncSuccess;

  /// Purpose: Return the localized string for `settingsWebDAVSyncFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get settingsWebDAVSyncFailed;

  /// Purpose: Return the localized string for `settingsWebDAVConflictTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync Conflicts'**
  String get settingsWebDAVConflictTitle;

  /// Purpose: Return the localized string for `settingsWebDAVConflictDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVConflictDesc.
  ///
  /// In en, this message translates to:
  /// **'Both local and remote have changes for the following records. Choose which version to keep for each:'**
  String get settingsWebDAVConflictDesc;

  /// Purpose: Return the localized string for `settingsWebDAVKeepLocal`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVKeepLocal.
  ///
  /// In en, this message translates to:
  /// **'Keep Local'**
  String get settingsWebDAVKeepLocal;

  /// Purpose: Return the localized string for `settingsWebDAVKeepRemote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVKeepRemote.
  ///
  /// In en, this message translates to:
  /// **'Keep Remote'**
  String get settingsWebDAVKeepRemote;

  /// Purpose: Return the localized string for `settingsWebDAVConflictApply`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVConflictApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get settingsWebDAVConflictApply;

  /// Purpose: Return the localized string for `settingsWebDAVNextcloud`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVNextcloud.
  ///
  /// In en, this message translates to:
  /// **'Nextcloud Preset'**
  String get settingsWebDAVNextcloud;

  /// Purpose: Return the localized string for `settingsWebDAVCustom`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom Server'**
  String get settingsWebDAVCustom;

  /// Purpose: Return the localized string for `settingsImportExport`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsImportExport.
  ///
  /// In en, this message translates to:
  /// **'Import / Export'**
  String get settingsImportExport;

  /// Purpose: Return the localized string for `settingsExportJSON`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsExportJSON.
  ///
  /// In en, this message translates to:
  /// **'Export ZIP'**
  String get settingsExportJSON;

  /// Purpose: Return the localized string for `settingsExportCSV`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsExportCSV.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get settingsExportCSV;

  /// Purpose: Return the localized string for `csvExportFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @csvExportFinance.
  ///
  /// In en, this message translates to:
  /// **'Export Finance CSV'**
  String get csvExportFinance;

  /// Purpose: Return the localized string for `csvExportFinanceDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @csvExportFinanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Finance transactions as plaintext'**
  String get csvExportFinanceDesc;

  /// Purpose: Return the localized string for `csvExportIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @csvExportIntimacy.
  ///
  /// In en, this message translates to:
  /// **'Export Intimacy CSV'**
  String get csvExportIntimacy;

  /// Purpose: Return the localized string for `csvExportIntimacyDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @csvExportIntimacyDesc.
  ///
  /// In en, this message translates to:
  /// **'Intimacy records as plaintext'**
  String get csvExportIntimacyDesc;

  /// Purpose: Return the localized string for `csvExportWeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @csvExportWeight.
  ///
  /// In en, this message translates to:
  /// **'Export Weight CSV'**
  String get csvExportWeight;

  /// Purpose: Return the localized string for `csvExportWeightDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @csvExportWeightDesc.
  ///
  /// In en, this message translates to:
  /// **'Weight records as plaintext'**
  String get csvExportWeightDesc;

  /// Purpose: Return the localized string for `settingsImport`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsImport.
  ///
  /// In en, this message translates to:
  /// **'Import from File'**
  String get settingsImport;

  /// Purpose: Return the localized string for `settingsExportSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported successfully'**
  String get settingsExportSuccess;

  /// Purpose: Return the localized string for `settingsExportFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get settingsExportFailed;

  /// Purpose: Return the localized string for `settingsImportSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Imported successfully'**
  String get settingsImportSuccess;

  /// Purpose: Return the localized string for `settingsImportFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get settingsImportFailed;

  /// Purpose: Return the localized string for `settingsImportConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsImportConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will replace all current data. Continue?'**
  String get settingsImportConfirm;

  /// Purpose: Return the localized string for `settingsExportCSVWarning`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsExportCSVWarning.
  ///
  /// In en, this message translates to:
  /// **'CSV data will be exported as plaintext. Continue?'**
  String get settingsExportCSVWarning;

  /// Purpose: Return the localized string for `settingsAbout`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// Purpose: Return the localized string for `settingsAboutTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About MyDay!!!!!'**
  String get settingsAboutTitle;

  /// Purpose: Return the localized string for `commonSave`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Purpose: Return the localized string for `commonDiscard`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get commonDiscard;

  /// Purpose: Return the localized string for `commonDiscardChangesTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonDiscardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get commonDiscardChangesTitle;

  /// Purpose: Return the localized string for `commonDiscardChangesMessage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonDiscardChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Discard them and close?'**
  String get commonDiscardChangesMessage;

  /// Purpose: Return the localized string for `commonCancel`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Purpose: Return the localized string for `commonDelete`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Purpose: Return the localized string for `commonEdit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// Purpose: Return the localized string for `commonAdd`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// Purpose: Return the localized string for `commonConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// Purpose: Return the localized string for `commonYes`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// Purpose: Return the localized string for `commonNo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// Purpose: Return the localized string for `commonOk`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// Purpose: Return the localized string for `commonClose`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Purpose: Return the localized string for `commonName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get commonName;

  /// Purpose: Return the localized string for `commonEmojiOptional`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonEmojiOptional.
  ///
  /// In en, this message translates to:
  /// **'Emoji (optional)'**
  String get commonEmojiOptional;

  /// Purpose: Return the localized string for `commonOptional`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonOptional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get commonOptional;

  /// Purpose: Implement the common delete confirm behavior for this file.
  /// Inputs: `item`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {item}?'**
  String commonDeleteConfirm(String item);

  /// Purpose: Implement the common minutes behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}min'**
  String commonMinutes(int count);

  /// Purpose: Return the localized string for `settingsExportSection`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsExportSection.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get settingsExportSection;

  /// Purpose: Return the localized string for `settingsImportSection`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsImportSection.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get settingsImportSection;

  /// Purpose: Return the localized string for `settingsExportFullBackup`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsExportFullBackup.
  ///
  /// In en, this message translates to:
  /// **'Full backup of all data'**
  String get settingsExportFullBackup;

  /// Purpose: Return the localized string for `settingsExportJSONPlaintext`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsExportJSONPlaintext.
  ///
  /// In en, this message translates to:
  /// **'All data will be exported as a ZIP archive'**
  String get settingsExportJSONPlaintext;

  /// Purpose: Return the localized string for `settingsExportCSVPlaintext`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsExportCSVPlaintext.
  ///
  /// In en, this message translates to:
  /// **'Finance transactions as plaintext'**
  String get settingsExportCSVPlaintext;

  /// Purpose: Return the localized string for `settingsImportRestore`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsImportRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore from ZIP backup'**
  String get settingsImportRestore;

  /// Purpose: Return the localized string for `settingsImportData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsImportData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get settingsImportData;

  /// Purpose: Return the localized string for `csvImportFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @csvImportFinance.
  ///
  /// In en, this message translates to:
  /// **'Import Finance CSV'**
  String get csvImportFinance;

  /// Purpose: Return the localized string for `csvImportFinanceDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @csvImportFinanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Merge transactions from CSV (will not overwrite existing data)'**
  String get csvImportFinanceDesc;

  /// Purpose: Return the localized string for `csvImportIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @csvImportIntimacy.
  ///
  /// In en, this message translates to:
  /// **'Import Intimacy CSV'**
  String get csvImportIntimacy;

  /// Purpose: Return the localized string for `csvImportIntimacyDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @csvImportIntimacyDesc.
  ///
  /// In en, this message translates to:
  /// **'Merge records from CSV (will not overwrite existing data)'**
  String get csvImportIntimacyDesc;

  /// Purpose: Return the localized string for `csvImportConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @csvImportConfirm.
  ///
  /// In en, this message translates to:
  /// **'CSV data will be merged into existing records. Continue?'**
  String get csvImportConfirm;

  /// Purpose: Implement the csv import success behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @csvImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} records successfully'**
  String csvImportSuccess(int count);

  /// Purpose: Return the localized string for `csvImportFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @csvImportFailed.
  ///
  /// In en, this message translates to:
  /// **'CSV import failed'**
  String get csvImportFailed;

  /// Purpose: Return the localized string for `csvImportEmpty`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @csvImportEmpty.
  ///
  /// In en, this message translates to:
  /// **'No valid records found in CSV'**
  String get csvImportEmpty;

  /// Purpose: Return the localized string for `csvTemplate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @csvTemplate.
  ///
  /// In en, this message translates to:
  /// **'CSV Templates'**
  String get csvTemplate;

  /// Purpose: Return the localized string for `csvTemplateFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @csvTemplateFinance.
  ///
  /// In en, this message translates to:
  /// **'Download Finance Template'**
  String get csvTemplateFinance;

  /// Purpose: Return the localized string for `csvTemplateIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @csvTemplateIntimacy.
  ///
  /// In en, this message translates to:
  /// **'Download Intimacy Template'**
  String get csvTemplateIntimacy;

  /// Purpose: Return the localized string for `csvTemplateSaved`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @csvTemplateSaved.
  ///
  /// In en, this message translates to:
  /// **'Template saved'**
  String get csvTemplateSaved;

  /// Purpose: Return the localized string for `settingsWebDAVDisconnect`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get settingsWebDAVDisconnect;

  /// Purpose: Return the localized string for `settingsWebDAVConfigSaved`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVConfigSaved.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved'**
  String get settingsWebDAVConfigSaved;

  /// Purpose: Return the localized string for `settingsWebDAVConfigRemoved`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsWebDAVConfigRemoved.
  ///
  /// In en, this message translates to:
  /// **'Configuration removed'**
  String get settingsWebDAVConfigRemoved;

  /// Purpose: Return the localized string for `commonDontAskMinutes`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonDontAskMinutes.
  ///
  /// In en, this message translates to:
  /// **'Don\'t ask for 5 minutes'**
  String get commonDontAskMinutes;

  /// Purpose: Return the localized string for `intimacyHideConfirm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyHideConfirm.
  ///
  /// In en, this message translates to:
  /// **'Hiding the module will not delete your data. You can re-enable it anytime.'**
  String get intimacyHideConfirm;

  /// Purpose: Return the localized string for `settingsLicense`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsLicense.
  ///
  /// In en, this message translates to:
  /// **'License (GPLv3)'**
  String get settingsLicense;

  /// Purpose: Return the localized string for `settingsLicenses`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get settingsLicenses;

  /// Purpose: Return the localized string for `settingsPrivacyPolicy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// Purpose: Return the localized string for `settingsDesktop`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsDesktop.
  ///
  /// In en, this message translates to:
  /// **'Desktop'**
  String get settingsDesktop;

  /// Purpose: Return the localized string for `settingsMinimizeToTray`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsMinimizeToTray.
  ///
  /// In en, this message translates to:
  /// **'Minimize to Tray'**
  String get settingsMinimizeToTray;

  /// Purpose: Return the localized string for `settingsCloseToTray`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsCloseToTray.
  ///
  /// In en, this message translates to:
  /// **'Close to Tray'**
  String get settingsCloseToTray;

  /// Purpose: Return the localized string for `financeBankPresets`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeBankPresets.
  ///
  /// In en, this message translates to:
  /// **'Bank Presets'**
  String get financeBankPresets;

  /// Purpose: Return the localized string for `financeBankSearch`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeBankSearch.
  ///
  /// In en, this message translates to:
  /// **'Search bank or app...'**
  String get financeBankSearch;

  /// Purpose: Return the localized string for `financeBankNoResults`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeBankNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching banks found'**
  String get financeBankNoResults;

  /// Purpose: Return the localized string for `financeSubscriptions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get financeSubscriptions;

  /// Purpose: Return the localized string for `financeSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get financeSubscription;

  /// Purpose: Return the localized string for `financeAddSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeAddSubscription.
  ///
  /// In en, this message translates to:
  /// **'Add Subscription'**
  String get financeAddSubscription;

  /// Purpose: Return the localized string for `financeEditSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeEditSubscription.
  ///
  /// In en, this message translates to:
  /// **'Edit Subscription'**
  String get financeEditSubscription;

  /// Purpose: Return the localized string for `financeStartDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get financeStartDate;

  /// Purpose: Return the localized string for `financeTrialDays`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeTrialDays.
  ///
  /// In en, this message translates to:
  /// **'Trial Days'**
  String get financeTrialDays;

  /// Purpose: Return the localized string for `financeBillingCycle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeBillingCycle.
  ///
  /// In en, this message translates to:
  /// **'Billing Cycle'**
  String get financeBillingCycle;

  /// Purpose: Return the localized string for `financeBillingCycleMonthly`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeBillingCycleMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get financeBillingCycleMonthly;

  /// Purpose: Return the localized string for `financeBillingCycleYearly`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeBillingCycleYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get financeBillingCycleYearly;

  /// Purpose: Implement the finance every x months behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeEveryXMonths.
  ///
  /// In en, this message translates to:
  /// **'Every {count} month(s)'**
  String financeEveryXMonths(int count);

  /// Purpose: Implement the finance every x years behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeEveryXYears.
  ///
  /// In en, this message translates to:
  /// **'Every {count} year(s)'**
  String financeEveryXYears(int count);

  /// Purpose: Return the localized string for `financeBillingDay`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeBillingDay.
  ///
  /// In en, this message translates to:
  /// **'Billing Day'**
  String get financeBillingDay;

  /// Purpose: Return the localized string for `financeBillingMonth`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeBillingMonth.
  ///
  /// In en, this message translates to:
  /// **'Billing Month'**
  String get financeBillingMonth;

  /// Purpose: Return the localized string for `financeMonthlyDue`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeMonthlyDue.
  ///
  /// In en, this message translates to:
  /// **'Monthly Due'**
  String get financeMonthlyDue;

  /// Purpose: Return the localized string for `financeMonthlyAvg`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeMonthlyAvg.
  ///
  /// In en, this message translates to:
  /// **'Monthly Avg'**
  String get financeMonthlyAvg;

  /// Purpose: Return the localized string for `financeYearlyAvg`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeYearlyAvg.
  ///
  /// In en, this message translates to:
  /// **'Yearly Avg'**
  String get financeYearlyAvg;

  /// Purpose: Return the localized string for `financeNoSubscriptions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeNoSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions'**
  String get financeNoSubscriptions;

  /// Purpose: Return the localized string for `financeActiveSubscriptions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeActiveSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get financeActiveSubscriptions;

  /// Purpose: Return the localized string for `financeHistoricalSubscriptions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeHistoricalSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get financeHistoricalSubscriptions;

  /// Purpose: Return the localized string for `financeCancelSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription'**
  String get financeCancelSubscription;

  /// Purpose: Return the localized string for `financeCancelImmediate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCancelImmediate.
  ///
  /// In en, this message translates to:
  /// **'Cancel Now'**
  String get financeCancelImmediate;

  /// Purpose: Return the localized string for `financeCancelAtExpiry`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCancelAtExpiry.
  ///
  /// In en, this message translates to:
  /// **'Cancel at Expiry'**
  String get financeCancelAtExpiry;

  /// Purpose: Return the localized string for `financeNextBilling`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeNextBilling.
  ///
  /// In en, this message translates to:
  /// **'Next Billing'**
  String get financeNextBilling;

  /// Purpose: Return the localized string for `financeExpiryDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get financeExpiryDate;

  /// Purpose: Return the localized string for `financeTotalSpent`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeTotalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get financeTotalSpent;

  /// Purpose: Return the localized string for `financeImportHistory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeImportHistory.
  ///
  /// In en, this message translates to:
  /// **'Import Historical Transactions'**
  String get financeImportHistory;

  /// Purpose: Return the localized string for `financeImportHistoryDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeImportHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Start date is before today. Import historical transactions?'**
  String get financeImportHistoryDesc;

  /// Purpose: Return the localized string for `financeThisSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeThisSubscription.
  ///
  /// In en, this message translates to:
  /// **'this subscription'**
  String get financeThisSubscription;

  /// Purpose: Implement the finance cancelled on behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCancelledOn.
  ///
  /// In en, this message translates to:
  /// **'Cancelled {date}'**
  String financeCancelledOn(String date);

  /// Purpose: Return the localized string for `financeInterval`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeInterval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get financeInterval;

  /// Purpose: Return the localized string for `financeImage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get financeImage;

  /// Purpose: Return the localized string for `financePickImage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financePickImage.
  ///
  /// In en, this message translates to:
  /// **'Pick Image'**
  String get financePickImage;

  /// Purpose: Return the localized string for `financeChangeImage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeChangeImage.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get financeChangeImage;

  /// Purpose: Return the localized string for `financeUpcomingRenewals`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeUpcomingRenewals.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Renewals'**
  String get financeUpcomingRenewals;

  /// Purpose: Return the localized string for `financeSubscriptionReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeSubscriptionReminder.
  ///
  /// In en, this message translates to:
  /// **'Subscription Reminder'**
  String get financeSubscriptionReminder;

  /// Purpose: Return the localized string for `financeReminderTime`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Notification Time'**
  String get financeReminderTime;

  /// Purpose: Return the localized string for `financeReminderEnabled`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeReminderEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notify upcoming renewals'**
  String get financeReminderEnabled;

  /// Purpose: Implement the finance subscription due soon behavior for this file.
  /// Inputs: `name`, `days`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeSubscriptionDueSoon.
  ///
  /// In en, this message translates to:
  /// **'{name} is due in {days} day(s)'**
  String financeSubscriptionDueSoon(String name, int days);

  /// Purpose: Implement the finance subscription due today behavior for this file.
  /// Inputs: `name`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeSubscriptionDueToday.
  ///
  /// In en, this message translates to:
  /// **'{name} is due today'**
  String financeSubscriptionDueToday(String name);

  /// Purpose: Return the localized string for `financeSortBy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get financeSortBy;

  /// Purpose: Return the localized string for `financeSortByRenewal`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeSortByRenewal.
  ///
  /// In en, this message translates to:
  /// **'By Renewal Date'**
  String get financeSortByRenewal;

  /// Purpose: Return the localized string for `financeSortByName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeSortByName.
  ///
  /// In en, this message translates to:
  /// **'By Name'**
  String get financeSortByName;

  /// Purpose: Return the localized string for `financeSortByBank`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeSortByBank.
  ///
  /// In en, this message translates to:
  /// **'By Bank / App'**
  String get financeSortByBank;

  /// Purpose: Return the localized string for `financeSortCustom`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeSortCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get financeSortCustom;

  /// Purpose: Return the localized string for `financeSortReorder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeSortReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get financeSortReorder;

  /// Purpose: Return the localized string for `financeSortDone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeSortDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get financeSortDone;

  /// Purpose: Return the localized string for `financeRestoreSubscription`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeRestoreSubscription.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get financeRestoreSubscription;

  /// Purpose: Return the localized string for `backupTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupTitle;

  /// Purpose: Return the localized string for `backupLocalOnlyNote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupLocalOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Backups are stored locally on this device only. Use WebDAV Sync for cloud backup.'**
  String get backupLocalOnlyNote;

  /// Purpose: Return the localized string for `backupSettings`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get backupSettings;

  /// Purpose: Return the localized string for `backupAutoDaily`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupAutoDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily Auto-Backup'**
  String get backupAutoDaily;

  /// Purpose: Return the localized string for `backupAutoDailyDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupAutoDailyDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically create backup once per day'**
  String get backupAutoDailyDesc;

  /// Purpose: Return the localized string for `backupRetention`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupRetention.
  ///
  /// In en, this message translates to:
  /// **'Keep backups'**
  String get backupRetention;

  /// Purpose: Return the localized string for `backupRetentionForever`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupRetentionForever.
  ///
  /// In en, this message translates to:
  /// **'Forever'**
  String get backupRetentionForever;

  /// Purpose: Implement the backup retention days behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupRetentionDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String backupRetentionDays(int count);

  /// Purpose: Return the localized string for `backupManual`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupManual.
  ///
  /// In en, this message translates to:
  /// **'Manual Backup'**
  String get backupManual;

  /// Purpose: Return the localized string for `backupCreateNow`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupCreateNow.
  ///
  /// In en, this message translates to:
  /// **'Create Backup Now'**
  String get backupCreateNow;

  /// Purpose: Implement the backup history behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupHistory.
  ///
  /// In en, this message translates to:
  /// **'Backups ({count})'**
  String backupHistory(int count);

  /// Purpose: Return the localized string for `backupEmpty`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupEmpty.
  ///
  /// In en, this message translates to:
  /// **'No backups yet'**
  String get backupEmpty;

  /// Purpose: Return the localized string for `backupCreated`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupCreated.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully'**
  String get backupCreated;

  /// Purpose: Return the localized string for `backupFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed'**
  String get backupFailed;

  /// Purpose: Return the localized string for `backupRestore`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupRestore;

  /// Purpose: Return the localized string for `backupRestoreConfirmTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupRestoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Restore'**
  String get backupRestoreConfirmTitle;

  /// Purpose: Return the localized string for `backupRestoreConfirmDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupRestoreConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'This will replace selected module data. Continue?'**
  String get backupRestoreConfirmDesc;

  /// Purpose: Return the localized string for `backupRestoreSelectModules`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupRestoreSelectModules.
  ///
  /// In en, this message translates to:
  /// **'Select Modules to Restore'**
  String get backupRestoreSelectModules;

  /// Purpose: Return the localized string for `backupRestoreAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupRestoreAll.
  ///
  /// In en, this message translates to:
  /// **'All Modules'**
  String get backupRestoreAll;

  /// Purpose: Return the localized string for `backupRestoreSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restore successful. Please restart the app.'**
  String get backupRestoreSuccess;

  /// Purpose: Return the localized string for `backupRestoreFailed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get backupRestoreFailed;

  /// Purpose: Return the localized string for `backupDeleteConfirmTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Backup'**
  String get backupDeleteConfirmTitle;

  /// Purpose: Return the localized string for `backupDeleteConfirmDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupDeleteConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'This backup will be permanently deleted.'**
  String get backupDeleteConfirmDesc;

  /// Purpose: Return the localized string for `backupModuleTodo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupModuleTodo.
  ///
  /// In en, this message translates to:
  /// **'Todo'**
  String get backupModuleTodo;

  /// Purpose: Return the localized string for `backupModuleFinance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupModuleFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get backupModuleFinance;

  /// Purpose: Return the localized string for `backupModuleRates`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupModuleRates.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rates'**
  String get backupModuleRates;

  /// Purpose: Return the localized string for `backupModuleIntimacy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @backupModuleIntimacy.
  ///
  /// In en, this message translates to:
  /// **'Intimacy'**
  String get backupModuleIntimacy;

  /// Purpose: Implement the intimacy record count behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyRecordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String intimacyRecordCount(int count);

  /// Purpose: Return the localized string for `weightTitle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightTitle;

  /// Purpose: Return the localized string for `weightSetHeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightSetHeight.
  ///
  /// In en, this message translates to:
  /// **'Set Height'**
  String get weightSetHeight;

  /// Purpose: Return the localized string for `weightNoRecords`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No weight records yet'**
  String get weightNoRecords;

  /// Purpose: Return the localized string for `weightAddRecord`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightAddRecord.
  ///
  /// In en, this message translates to:
  /// **'Add Record'**
  String get weightAddRecord;

  /// Purpose: Return the localized string for `weightKg`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKg;

  /// Purpose: Return the localized string for `weightHeightCm`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightHeightCm.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get weightHeightCm;

  /// Purpose: Return the localized string for `weightNote`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get weightNote;

  /// Purpose: Return the localized string for `weightNoteHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Optional note'**
  String get weightNoteHint;

  /// Purpose: Return the localized string for `weightChart`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightChart.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get weightChart;

  /// Purpose: Return the localized string for `weightAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get weightAll;

  /// Purpose: Return the localized string for `weightHistory`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get weightHistory;

  /// Purpose: Return the localized string for `weightShowAll`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all records'**
  String get weightShowAll;

  /// Purpose: Return the localized string for `weightDays`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get weightDays;

  /// Purpose: Return the localized string for `weightDaysAgo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String get weightDaysAgo;

  /// Purpose: Return the localized string for `weightWeeksAgo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'weeks ago'**
  String get weightWeeksAgo;

  /// Purpose: Return the localized string for `weightToday`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get weightToday;

  /// Purpose: Return the localized string for `weightYesterday`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get weightYesterday;

  /// Purpose: Return the localized string for `weightRecent`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get weightRecent;

  /// Purpose: Return the localized string for `weightExportCsv`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get weightExportCsv;

  /// Purpose: Return the localized string for `weightExportCsvSuccess`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightExportCsvSuccess.
  ///
  /// In en, this message translates to:
  /// **'Weight data exported successfully'**
  String get weightExportCsvSuccess;

  /// Purpose: Return the localized string for `weightExportCsvEmpty`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightExportCsvEmpty.
  ///
  /// In en, this message translates to:
  /// **'No weight records to export'**
  String get weightExportCsvEmpty;

  /// Purpose: Return the localized string for `csvImportWeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @csvImportWeight.
  ///
  /// In en, this message translates to:
  /// **'Import Weight CSV'**
  String get csvImportWeight;

  /// Purpose: Return the localized string for `csvImportWeightDesc`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @csvImportWeightDesc.
  ///
  /// In en, this message translates to:
  /// **'Merge weight records from CSV (Date, Time, Weight)'**
  String get csvImportWeightDesc;

  /// Purpose: Return the localized string for `csvTemplateWeight`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @csvTemplateWeight.
  ///
  /// In en, this message translates to:
  /// **'Download Weight Template'**
  String get csvTemplateWeight;

  /// Purpose: Return the localized string for `financeSubscriptionPresets`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeSubscriptionPresets.
  ///
  /// In en, this message translates to:
  /// **'Quick Fill'**
  String get financeSubscriptionPresets;

  /// Purpose: Return the localized string for `intimacyPurchaseLink`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyPurchaseLink.
  ///
  /// In en, this message translates to:
  /// **'Purchase Link'**
  String get intimacyPurchaseLink;

  /// Purpose: Return the localized string for `intimacyPrice`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get intimacyPrice;

  /// Purpose: Return the localized string for `intimacyPositions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyPositions.
  ///
  /// In en, this message translates to:
  /// **'Positions'**
  String get intimacyPositions;

  /// Purpose: Return the localized string for `intimacyAddPosition`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyAddPosition.
  ///
  /// In en, this message translates to:
  /// **'Add Position'**
  String get intimacyAddPosition;

  /// Purpose: Return the localized string for `intimacyEditPosition`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyEditPosition.
  ///
  /// In en, this message translates to:
  /// **'Edit Position'**
  String get intimacyEditPosition;

  /// Purpose: Return the localized string for `intimacyNoPositions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyNoPositions.
  ///
  /// In en, this message translates to:
  /// **'No positions yet'**
  String get intimacyNoPositions;

  /// Purpose: Return the localized string for `intimacyImportDefaults`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyImportDefaults.
  ///
  /// In en, this message translates to:
  /// **'Import Defaults'**
  String get intimacyImportDefaults;

  /// Purpose: Return the localized string for `intimacyTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get intimacyTrend;

  /// Purpose: Return the localized string for `intimacyFrequency`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get intimacyFrequency;

  /// Purpose: Return the localized string for `intimacyChartNoData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyChartNoData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data'**
  String get intimacyChartNoData;

  /// Purpose: Return the localized string for `weightTrend`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get weightTrend;

  /// Purpose: Return the localized string for `weightRaw`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightRaw.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get weightRaw;

  /// Purpose: Return the localized string for `weightReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightReminder.
  ///
  /// In en, this message translates to:
  /// **'Weight Reminder'**
  String get weightReminder;

  /// Purpose: Return the localized string for `weightReminderNone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightReminderNone.
  ///
  /// In en, this message translates to:
  /// **'No Reminder'**
  String get weightReminderNone;

  /// Purpose: Return the localized string for `weightReminderOnce`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightReminderOnce.
  ///
  /// In en, this message translates to:
  /// **'Once Daily'**
  String get weightReminderOnce;

  /// Purpose: Return the localized string for `weightReminderTwice`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightReminderTwice.
  ///
  /// In en, this message translates to:
  /// **'Twice Daily (Morning & Evening)'**
  String get weightReminderTwice;

  /// Purpose: Return the localized string for `weightReminderMorning`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightReminderMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get weightReminderMorning;

  /// Purpose: Return the localized string for `weightReminderEvening`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightReminderEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get weightReminderEvening;

  /// Purpose: Return the localized string for `weightReminderSkipWindow`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightReminderSkipWindow.
  ///
  /// In en, this message translates to:
  /// **'Skip if already logged'**
  String get weightReminderSkipWindow;

  /// Purpose: Implement the weight reminder skip window value behavior for this file.
  /// Inputs: `hours`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightReminderSkipWindowValue.
  ///
  /// In en, this message translates to:
  /// **'{hours} h before reminder'**
  String weightReminderSkipWindowValue(String hours);

  /// Purpose: Return the localized string for `weightReminderSkipWindowHours`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightReminderSkipWindowHours.
  ///
  /// In en, this message translates to:
  /// **'Hours before reminder'**
  String get weightReminderSkipWindowHours;

  /// Purpose: Return the localized string for `commonChange`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get commonChange;

  /// Purpose: Return the localized string for `commonPickImage`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonPickImage.
  ///
  /// In en, this message translates to:
  /// **'Pick Image'**
  String get commonPickImage;

  /// Purpose: Return the localized string for `commonRemoveIcon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonRemoveIcon.
  ///
  /// In en, this message translates to:
  /// **'Remove icon'**
  String get commonRemoveIcon;

  /// Purpose: Return the localized string for `commonPickIcon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonPickIcon.
  ///
  /// In en, this message translates to:
  /// **'Pick an icon'**
  String get commonPickIcon;

  /// Purpose: Return the localized string for `commonNoData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get commonNoData;

  /// Purpose: Implement the common week group behavior for this file.
  /// Inputs: `year`, `week`, `range`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonWeekGroup.
  ///
  /// In en, this message translates to:
  /// **'{year} Week {week} ({range})'**
  String commonWeekGroup(int year, int week, String range);

  /// Purpose: Return the localized string for `todoDailyReminders`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoDailyReminders.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminders'**
  String get todoDailyReminders;

  /// Purpose: Return the localized string for `todoRemindReviewHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoRemindReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Remind to review today\'s Todo list'**
  String get todoRemindReviewHint;

  /// Purpose: Return the localized string for `todoRemindUndoneHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoRemindUndoneHint.
  ///
  /// In en, this message translates to:
  /// **'Remind if tasks are still undone'**
  String get todoRemindUndoneHint;

  /// Purpose: Return the localized string for `todoTapReturnToday`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoTapReturnToday.
  ///
  /// In en, this message translates to:
  /// **'Tap to return to today'**
  String get todoTapReturnToday;

  /// Purpose: Return the localized string for `todoCalendar`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get todoCalendar;

  /// Purpose: Return the localized string for `todoWeekMon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoWeekMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get todoWeekMon;

  /// Purpose: Return the localized string for `todoWeekTue`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoWeekTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get todoWeekTue;

  /// Purpose: Return the localized string for `todoWeekWed`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoWeekWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get todoWeekWed;

  /// Purpose: Return the localized string for `todoWeekThu`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoWeekThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get todoWeekThu;

  /// Purpose: Return the localized string for `todoWeekFri`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoWeekFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get todoWeekFri;

  /// Purpose: Return the localized string for `todoWeekSat`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoWeekSat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get todoWeekSat;

  /// Purpose: Return the localized string for `todoWeekSun`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoWeekSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get todoWeekSun;

  /// Purpose: Return the localized string for `todoCalendarSomeDaily`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoCalendarSomeDaily.
  ///
  /// In en, this message translates to:
  /// **'Some daily'**
  String get todoCalendarSomeDaily;

  /// Purpose: Return the localized string for `todoCalendarAllDaily`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoCalendarAllDaily.
  ///
  /// In en, this message translates to:
  /// **'All daily'**
  String get todoCalendarAllDaily;

  /// Purpose: Return the localized string for `todoCalendarAllDone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoCalendarAllDone.
  ///
  /// In en, this message translates to:
  /// **'All done'**
  String get todoCalendarAllDone;

  /// Purpose: Return the localized string for `todoWhatNeedsDone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoWhatNeedsDone.
  ///
  /// In en, this message translates to:
  /// **'What needs to be done?'**
  String get todoWhatNeedsDone;

  /// Purpose: Implement the todo reminder at behavior for this file.
  /// Inputs: `time`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoReminderAt.
  ///
  /// In en, this message translates to:
  /// **'Reminder: {time}'**
  String todoReminderAt(String time);

  /// Purpose: Return the localized string for `todoAddReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoAddReminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder (optional)'**
  String get todoAddReminder;

  /// Purpose: Implement the todo scheduled at behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoScheduledAt.
  ///
  /// In en, this message translates to:
  /// **'Scheduled: {date}'**
  String todoScheduledAt(String date);

  /// Purpose: Return the localized string for `todoSetScheduledDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoSetScheduledDate.
  ///
  /// In en, this message translates to:
  /// **'Set scheduled date'**
  String get todoSetScheduledDate;

  /// Purpose: Implement the todo completed at behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoCompletedAt.
  ///
  /// In en, this message translates to:
  /// **'Completed: {date}'**
  String todoCompletedAt(String date);

  /// Purpose: Return the localized string for `todoSetCompletedDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoSetCompletedDate.
  ///
  /// In en, this message translates to:
  /// **'Set completed date'**
  String get todoSetCompletedDate;

  /// Purpose: Return the localized string for `todoSortBy`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get todoSortBy;

  /// Purpose: Return the localized string for `todoSortByAdded`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoSortByAdded.
  ///
  /// In en, this message translates to:
  /// **'By Added Time'**
  String get todoSortByAdded;

  /// Purpose: Return the localized string for `todoSortByDueDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoSortByDueDate.
  ///
  /// In en, this message translates to:
  /// **'By Due Date'**
  String get todoSortByDueDate;

  /// Purpose: Return the localized string for `todoSortByName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoSortByName.
  ///
  /// In en, this message translates to:
  /// **'By Name'**
  String get todoSortByName;

  /// Purpose: Return the localized string for `todoSortCustom`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoSortCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get todoSortCustom;

  /// Purpose: Return the localized string for `weightUnitKg`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightUnitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get weightUnitKg;

  /// Purpose: Implement the weight value kg behavior for this file.
  /// Inputs: `value`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @weightValueKg.
  ///
  /// In en, this message translates to:
  /// **'{value} kg'**
  String weightValueKg(String value);

  /// Purpose: Return the localized string for `positionMissionary`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @positionMissionary.
  ///
  /// In en, this message translates to:
  /// **'Missionary'**
  String get positionMissionary;

  /// Purpose: Return the localized string for `positionCowgirl`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @positionCowgirl.
  ///
  /// In en, this message translates to:
  /// **'Cowgirl'**
  String get positionCowgirl;

  /// Purpose: Return the localized string for `positionDoggyStyle`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @positionDoggyStyle.
  ///
  /// In en, this message translates to:
  /// **'Doggy Style'**
  String get positionDoggyStyle;

  /// Purpose: Return the localized string for `positionReverseCowgirl`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @positionReverseCowgirl.
  ///
  /// In en, this message translates to:
  /// **'Reverse Cowgirl'**
  String get positionReverseCowgirl;

  /// Purpose: Return the localized string for `positionSpooning`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @positionSpooning.
  ///
  /// In en, this message translates to:
  /// **'Spooning'**
  String get positionSpooning;

  /// Purpose: Return the localized string for `positionStanding`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @positionStanding.
  ///
  /// In en, this message translates to:
  /// **'Standing'**
  String get positionStanding;

  /// Purpose: Return the localized string for `position69`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @position69.
  ///
  /// In en, this message translates to:
  /// **'69'**
  String get position69;

  /// Purpose: Return the localized string for `positionLotus`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @positionLotus.
  ///
  /// In en, this message translates to:
  /// **'Lotus'**
  String get positionLotus;

  /// Purpose: Return the localized string for `positionProneBone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @positionProneBone.
  ///
  /// In en, this message translates to:
  /// **'Prone Bone'**
  String get positionProneBone;

  /// Purpose: Return the localized string for `notifTodoMorning`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @notifTodoMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning! Time to review and update your Todo list 📝'**
  String get notifTodoMorning;

  /// Purpose: Return the localized string for `notifTodoCompletion`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @notifTodoCompletion.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget to complete your remaining tasks today!'**
  String get notifTodoCompletion;

  /// Purpose: Implement the notif todo uncompleted behavior for this file.
  /// Inputs: `count`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @notifTodoUncompleted.
  ///
  /// In en, this message translates to:
  /// **'You still have {count} uncompleted tasks today!'**
  String notifTodoUncompleted(int count);

  /// Purpose: Return the localized string for `notifWeightReminder`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @notifWeightReminder.
  ///
  /// In en, this message translates to:
  /// **'Time to log your weight! ⚖️'**
  String get notifWeightReminder;

  /// Purpose: Implement the notif upcoming renewals behavior for this file.
  /// Inputs: `list`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @notifUpcomingRenewals.
  ///
  /// In en, this message translates to:
  /// **'Upcoming renewals: {list}'**
  String notifUpcomingRenewals(String list);

  /// Purpose: Implement the notif subscription today behavior for this file.
  /// Inputs: `name`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @notifSubscriptionToday.
  ///
  /// In en, this message translates to:
  /// **'{name}(today)'**
  String notifSubscriptionToday(String name);

  /// Purpose: Implement the notif subscription days behavior for this file.
  /// Inputs: `name`, `days`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @notifSubscriptionDays.
  ///
  /// In en, this message translates to:
  /// **'{name}({days}d)'**
  String notifSubscriptionDays(String name, int days);

  /// Purpose: Return the localized string for `trayShow`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @trayShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get trayShow;

  /// Purpose: Return the localized string for `trayQuit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @trayQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get trayQuit;

  /// Purpose: Return the localized string for `filePickerExportLocation`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @filePickerExportLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose export location'**
  String get filePickerExportLocation;

  /// Purpose: Return the localized string for `filePickerBackupFile`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @filePickerBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Choose backup file'**
  String get filePickerBackupFile;

  /// Purpose: Return the localized string for `filePickerCsvFile`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @filePickerCsvFile.
  ///
  /// In en, this message translates to:
  /// **'Choose CSV file'**
  String get filePickerCsvFile;

  /// Purpose: Return the localized string for `filePickerSaveTemplate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @filePickerSaveTemplate.
  ///
  /// In en, this message translates to:
  /// **'Save template to'**
  String get filePickerSaveTemplate;

  /// Purpose: Return the localized string for `financeBalance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get financeBalance;

  /// Purpose: Return the localized string for `financeNewAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeNewAccount.
  ///
  /// In en, this message translates to:
  /// **'New Account'**
  String get financeNewAccount;

  /// Purpose: Return the localized string for `financeAccountTypeFund`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeAccountTypeFund.
  ///
  /// In en, this message translates to:
  /// **'Fund'**
  String get financeAccountTypeFund;

  /// Purpose: Return the localized string for `financeAccountTypeCredit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeAccountTypeCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get financeAccountTypeCredit;

  /// Purpose: Return the localized string for `financeAccountTypeRecharge`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeAccountTypeRecharge.
  ///
  /// In en, this message translates to:
  /// **'Recharge'**
  String get financeAccountTypeRecharge;

  /// Purpose: Return the localized string for `financeAccountTypeFinancial`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeAccountTypeFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get financeAccountTypeFinancial;

  /// Purpose: Return the localized string for `financeAccountName`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeAccountName.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get financeAccountName;

  /// Purpose: Return the localized string for `financeBankAppHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeBankAppHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. ICBC, Alipay'**
  String get financeBankAppHint;

  /// Purpose: Return the localized string for `financeCardNumberHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCardNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Last 4 digits'**
  String get financeCardNumberHint;

  /// Purpose: Return the localized string for `financeFeeWaiverConditions`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeFeeWaiverConditions.
  ///
  /// In en, this message translates to:
  /// **'Monthly fee waiver'**
  String get financeFeeWaiverConditions;

  /// Purpose: Return the localized string for `financeFeeWaiverConditionsHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeFeeWaiverConditionsHint.
  ///
  /// In en, this message translates to:
  /// **'Optional criteria for avoiding monthly maintenance fees.'**
  String get financeFeeWaiverConditionsHint;

  /// Purpose: Return the localized string for `financeFeeWaiverMinimumBalance`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeFeeWaiverMinimumBalance.
  ///
  /// In en, this message translates to:
  /// **'Minimum balance'**
  String get financeFeeWaiverMinimumBalance;

  /// Purpose: Return the localized string for `financeFeeWaiverMinimumBalanceHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeFeeWaiverMinimumBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1500'**
  String get financeFeeWaiverMinimumBalanceHint;

  /// Purpose: Return the localized string for `financeFeeWaiverMonthlyDeposit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeFeeWaiverMonthlyDeposit.
  ///
  /// In en, this message translates to:
  /// **'Monthly incoming transfer'**
  String get financeFeeWaiverMonthlyDeposit;

  /// Purpose: Return the localized string for `financeFeeWaiverMonthlyDepositHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeFeeWaiverMonthlyDepositHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 500'**
  String get financeFeeWaiverMonthlyDepositHint;

  /// Purpose: Return the localized string for `financeFeeWaiverSeparator`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeFeeWaiverSeparator.
  ///
  /// In en, this message translates to:
  /// **' or '**
  String get financeFeeWaiverSeparator;

  /// Purpose: Return the localized string for `financeCurrentBalanceHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCurrentBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to calculate from transactions'**
  String get financeCurrentBalanceHint;

  /// Purpose: Return the localized string for `financeAsOfToday`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeAsOfToday.
  ///
  /// In en, this message translates to:
  /// **'As of today'**
  String get financeAsOfToday;

  /// Purpose: Return the localized string for `financeBalanceEffectiveDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeBalanceEffectiveDate.
  ///
  /// In en, this message translates to:
  /// **'Balance effective date'**
  String get financeBalanceEffectiveDate;

  /// Purpose: Return the localized string for `financeFetchIcon`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeFetchIcon.
  ///
  /// In en, this message translates to:
  /// **'Fetch Icon'**
  String get financeFetchIcon;

  /// Purpose: Return the localized string for `financeAccountsCategories`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeAccountsCategories.
  ///
  /// In en, this message translates to:
  /// **'Accounts & Categories'**
  String get financeAccountsCategories;

  /// Purpose: Return the localized string for `financeEditRate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeEditRate.
  ///
  /// In en, this message translates to:
  /// **'Edit Rate'**
  String get financeEditRate;

  /// Purpose: Return the localized string for `financeNewRate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeNewRate.
  ///
  /// In en, this message translates to:
  /// **'New Exchange Rate'**
  String get financeNewRate;

  /// Purpose: Return the localized string for `financeFrom`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get financeFrom;

  /// Purpose: Return the localized string for `financeTo`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get financeTo;

  /// Purpose: Return the localized string for `financeRate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get financeRate;

  /// Purpose: Implement the finance rate hint behavior for this file.
  /// Inputs: `from`, `to`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeRateHint.
  ///
  /// In en, this message translates to:
  /// **'1 {from} = ? {to}'**
  String financeRateHint(String from, String to);

  /// Purpose: Return the localized string for `financeNoRates`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeNoRates.
  ///
  /// In en, this message translates to:
  /// **'No exchange rates configured'**
  String get financeNoRates;

  /// Purpose: Return the localized string for `financeNoExpenseData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeNoExpenseData.
  ///
  /// In en, this message translates to:
  /// **'No expense data for this period'**
  String get financeNoExpenseData;

  /// Purpose: Return the localized string for `financeUncategorized`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get financeUncategorized;

  /// Purpose: Return the localized string for `financeTotal`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get financeTotal;

  /// Purpose: Return the localized string for `financeSelectDateRange`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeSelectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select a date range'**
  String get financeSelectDateRange;

  /// Purpose: Return the localized string for `financeNoTransactionData`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeNoTransactionData.
  ///
  /// In en, this message translates to:
  /// **'No transaction data for this period'**
  String get financeNoTransactionData;

  /// Purpose: Implement the finance received amount behavior for this file.
  /// Inputs: `currency`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeReceivedAmount.
  ///
  /// In en, this message translates to:
  /// **'Received Amount ({currency})'**
  String financeReceivedAmount(String currency);

  /// Purpose: Return the localized string for `financeReceivedAmountHelper`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeReceivedAmountHelper.
  ///
  /// In en, this message translates to:
  /// **'Amount received in target account currency'**
  String get financeReceivedAmountHelper;

  /// Purpose: Return the localized string for `financeNoteHint`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeNoteHint.
  ///
  /// In en, this message translates to:
  /// **'What was this for?'**
  String get financeNoteHint;

  /// Purpose: Return the localized string for `financeThisAccount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeThisAccount.
  ///
  /// In en, this message translates to:
  /// **'this account'**
  String get financeThisAccount;

  /// Purpose: Return the localized string for `commonThisRecord`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @commonThisRecord.
  ///
  /// In en, this message translates to:
  /// **'this record'**
  String get commonThisRecord;

  /// Purpose: Return the localized string for `financeBalanceAdjustment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeBalanceAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Balance Adjustment'**
  String get financeBalanceAdjustment;

  /// Purpose: Return the localized string for `financeCatCreditCardPayment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCatCreditCardPayment.
  ///
  /// In en, this message translates to:
  /// **'Credit Card Payment'**
  String get financeCatCreditCardPayment;

  /// Purpose: Return the localized string for `financeCatFixedDeposit`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCatFixedDeposit.
  ///
  /// In en, this message translates to:
  /// **'Fixed Deposit Maturity'**
  String get financeCatFixedDeposit;

  /// Purpose: Return the localized string for `financeCatInternalTransfer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCatInternalTransfer.
  ///
  /// In en, this message translates to:
  /// **'Internal Transfer'**
  String get financeCatInternalTransfer;

  /// Purpose: Return the localized string for `financeCatLoanRepayment`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCatLoanRepayment.
  ///
  /// In en, this message translates to:
  /// **'Loan Repayment'**
  String get financeCatLoanRepayment;

  /// Purpose: Return the localized string for `financeCatInvestmentTransfer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCatInvestmentTransfer.
  ///
  /// In en, this message translates to:
  /// **'Investment Transfer'**
  String get financeCatInvestmentTransfer;

  /// Purpose: Return the localized string for `financeCatReimburse`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @financeCatReimburse.
  ///
  /// In en, this message translates to:
  /// **'Reimbursement'**
  String get financeCatReimburse;

  /// Purpose: Return the localized string for `settingsAutoStart`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsAutoStart.
  ///
  /// In en, this message translates to:
  /// **'Launch at Startup'**
  String get settingsAutoStart;

  /// Purpose: Return the localized string for `settingsApiEnabled`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsApiEnabled.
  ///
  /// In en, this message translates to:
  /// **'Local API Server'**
  String get settingsApiEnabled;

  /// Purpose: Return the localized string for `settingsApiServer`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsApiServer.
  ///
  /// In en, this message translates to:
  /// **'API Server Settings'**
  String get settingsApiServer;

  /// Purpose: Implement the settings api running behavior for this file.
  /// Inputs: `port`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsApiRunning.
  ///
  /// In en, this message translates to:
  /// **'Running on port {port}'**
  String settingsApiRunning(int port);

  /// Purpose: Return the localized string for `settingsApiStopped`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsApiStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get settingsApiStopped;

  /// Purpose: Return the localized string for `settingsApiNeedCredentials`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsApiNeedCredentials.
  ///
  /// In en, this message translates to:
  /// **'Credentials required for non-localhost'**
  String get settingsApiNeedCredentials;

  /// Purpose: Implement the settings api restarted behavior for this file.
  /// Inputs: `port`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsApiRestarted.
  ///
  /// In en, this message translates to:
  /// **'API server restarted on port {port}'**
  String settingsApiRestarted(int port);

  /// Purpose: Return the localized string for `settingsApiListenAddress`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsApiListenAddress.
  ///
  /// In en, this message translates to:
  /// **'Listen Address'**
  String get settingsApiListenAddress;

  /// Purpose: Return the localized string for `settingsApiPort`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsApiPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get settingsApiPort;

  /// Purpose: Return the localized string for `settingsApiUsername`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsApiUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get settingsApiUsername;

  /// Purpose: Return the localized string for `settingsApiPassword`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @settingsApiPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get settingsApiPassword;

  /// Purpose: Return the localized string for `todoRecurrence`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoRecurrence.
  ///
  /// In en, this message translates to:
  /// **'Recurrence'**
  String get todoRecurrence;

  /// Purpose: Return the localized string for `todoRecurrenceNone`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoRecurrenceNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get todoRecurrenceNone;

  /// Purpose: Implement the todo recurrence every n days behavior for this file.
  /// Inputs: `n`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoRecurrenceEveryNDays.
  ///
  /// In en, this message translates to:
  /// **'Every {n} days'**
  String todoRecurrenceEveryNDays(int n);

  /// Purpose: Implement the todo recurrence monthly on day behavior for this file.
  /// Inputs: `n`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoRecurrenceMonthlyOnDay.
  ///
  /// In en, this message translates to:
  /// **'Every month on the {n}th'**
  String todoRecurrenceMonthlyOnDay(int n);

  /// Purpose: Implement the todo recurrence yearly on date behavior for this file.
  /// Inputs: `month`, `day`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoRecurrenceYearlyOnDate.
  ///
  /// In en, this message translates to:
  /// **'Every year on {month}/{day}'**
  String todoRecurrenceYearlyOnDate(int month, int day);

  /// Purpose: Return the localized string for `todoNextOccurrence`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @todoNextOccurrence.
  ///
  /// In en, this message translates to:
  /// **'Schedule Next Occurrence'**
  String get todoNextOccurrence;

  /// Purpose: Return the localized string for `intimacyActivePartners`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyActivePartners.
  ///
  /// In en, this message translates to:
  /// **'Active Partners'**
  String get intimacyActivePartners;

  /// Purpose: Return the localized string for `intimacyPastPartners`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyPastPartners.
  ///
  /// In en, this message translates to:
  /// **'Past Partners'**
  String get intimacyPastPartners;

  /// Purpose: Return the localized string for `intimacyActiveToys`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyActiveToys.
  ///
  /// In en, this message translates to:
  /// **'Active Toys'**
  String get intimacyActiveToys;

  /// Purpose: Return the localized string for `intimacyRetiredToys`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacyRetiredToys.
  ///
  /// In en, this message translates to:
  /// **'Retired Toys'**
  String get intimacyRetiredToys;

  /// Purpose: Return the localized string for `intimacySortByRelationshipDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacySortByRelationshipDate.
  ///
  /// In en, this message translates to:
  /// **'By Relationship Date'**
  String get intimacySortByRelationshipDate;

  /// Purpose: Return the localized string for `intimacySortByPurchaseDate`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacySortByPurchaseDate.
  ///
  /// In en, this message translates to:
  /// **'By Purchase Date'**
  String get intimacySortByPurchaseDate;

  /// Purpose: Return the localized string for `intimacySortByUseCount`.
  /// Inputs: None.
  /// Returns: A localized `String`.
  /// Side effects: None.
  /// Notes: Generated localization accessor or override.
  /// No description provided for @intimacySortByUseCount.
  ///
  /// In en, this message translates to:
  /// **'By Use Count'**
  String get intimacySortByUseCount;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  /// Purpose: Implement the load behavior for this file.
  /// Inputs: `locale`.
  /// Returns: `Future<AppLocalizations>`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  /// Purpose: Implement the is supported behavior for this file.
  /// Inputs: `locale`.
  /// Returns: `bool`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  /// Purpose: Implement the should reload behavior for this file.
  /// Inputs: `old`.
  /// Returns: `bool`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Generated localization accessor or override.
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Purpose: Implement the lookup app localizations behavior for this file.
/// Inputs: `locale`.
/// Returns: `AppLocalizations`.
/// Side effects: May create, transform, or mutate data used by callers.
/// Notes: Generated localization accessor or override.
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
