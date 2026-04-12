// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'MyDay!!!!!';

  @override
  String get navTodo => 'ToDo';

  @override
  String get navFinance => '家計';

  @override
  String get navWeight => '体重';

  @override
  String get navIntimacy => 'プライベート';

  @override
  String get navSettings => '設定';

  @override
  String get todoSectionDaily => '毎日';

  @override
  String get todoSectionRoutine => '日課';

  @override
  String get todoSectionWork => '仕事';

  @override
  String get todoAddTask => 'タスクを追加';

  @override
  String get todoEditTask => 'タスクを編集';

  @override
  String get todoTitle => 'タイトル';

  @override
  String get todoSubtasks => 'サブタスク';

  @override
  String get todoAddSubtask => 'サブタスクを追加';

  @override
  String get todoReminderTime => 'リマインダー時間';

  @override
  String get todoNoTasks => 'タスクなし';

  @override
  String get todoType => '種類';

  @override
  String get todoEmoji => '絵文字';

  @override
  String get todoDailyTask => '毎日';

  @override
  String get todoRoutineTask => '日課（1回）';

  @override
  String get todoWorkTask => '仕事（1回）';

  @override
  String todoCreatedDate(String date) {
    return '作成日：$date';
  }

  @override
  String todoStartDate(String date) {
    return '開始日：$date';
  }

  @override
  String todoDeletedDate(String date) {
    return '削除日：$date';
  }

  @override
  String get todoPermanentDelete => '完全に削除';

  @override
  String get todoPermanentDeleteConfirm => 'このタスクとその履歴を完全に削除します。続行しますか？';

  @override
  String get todoMorningReminder => '朝のプランリマインダー';

  @override
  String get todoCompletionReminder => '完了チェックリマインダー';

  @override
  String get todoSetReminder => 'リマインダーを設定';

  @override
  String get todoClearReminder => 'クリア';

  @override
  String todoReminderSet(String time) {
    return 'リマインダー設定済み：$time';
  }

  @override
  String get todoCompleted => '完了';

  @override
  String get todoDueDate => '期限';

  @override
  String get todoSetDueDate => '期限を設定（任意）';

  @override
  String get todoCustomEmoji => 'カスタム絵文字';

  @override
  String get todoCustomEmojiHint => '絵文字を入力';

  @override
  String get todoEditSubtask => 'サブタスクを編集';

  @override
  String todoSubtasksProgress(int done, int total) {
    return 'サブタスク：$done/$total';
  }

  @override
  String todoTaskDue(String date) {
    return '締切：$date';
  }

  @override
  String get todoThisTask => 'このタスク';

  @override
  String get financeTitle => '家計';

  @override
  String get financeMonthlyExpense => '月間支出';

  @override
  String get financeTotalAssets => '総資産';

  @override
  String get financeAccounts => '口座';

  @override
  String get financeCategories => 'カテゴリ';

  @override
  String get financeTrends => 'トレンド';

  @override
  String get financeAnalysis => '分析';

  @override
  String get financeExchangeRates => '為替レート';

  @override
  String get financeRefreshRates => 'レートを更新';

  @override
  String get financeAddTransaction => '取引を追加';

  @override
  String get financeEditTransaction => '取引を編集';

  @override
  String get financeExpense => '支出';

  @override
  String get financeIncome => '収入';

  @override
  String get financeTransfer => '振替';

  @override
  String get financeAmount => '金額';

  @override
  String get financeNote => 'メモ';

  @override
  String get financeCategory => 'カテゴリ';

  @override
  String get financeAccount => '口座';

  @override
  String get financeFromAccount => '振替元口座';

  @override
  String get financeToAccount => '振替先口座';

  @override
  String get financeCurrency => '通貨';

  @override
  String get financeDate => '日付';

  @override
  String get financeNoTransactions => '取引なし';

  @override
  String get financeForceBalance => '残高を固定';

  @override
  String get financeCurrentBalance => '現在の残高';

  @override
  String get financeAddAccount => '口座を追加';

  @override
  String get financeEditAccount => '口座を編集';

  @override
  String get financeAddCategory => 'カテゴリを追加';

  @override
  String get financeEditCategory => 'カテゴリを編集';

  @override
  String get financeName => '名前';

  @override
  String get financeBankApp => '銀行 / アプリ';

  @override
  String get financeCardNumber => 'カード番号（任意）';

  @override
  String get financeExpiry => '有効期限';

  @override
  String get financeSecurityCode => 'セキュリティコード';

  @override
  String get financeIcon => 'アイコン';

  @override
  String get financeEmoji => '絵文字';

  @override
  String get financeCategoryHintExpense => '例: 食費、交通費';

  @override
  String get financeCategoryHintIncome => '例: 給料、投資';

  @override
  String get financeThisTransaction => 'この取引';

  @override
  String get financeNoAccounts => '口座なし';

  @override
  String get financeNoCategories => 'カテゴリなし';

  @override
  String get financeByYear => '年別';

  @override
  String get financeByMonth => '月別';

  @override
  String get financeByDay => '日別';

  @override
  String get financeCustomRange => 'カスタム範囲';

  @override
  String get financeExpenseTrend => '支出推移';

  @override
  String get financeIncomeTrend => '収入推移';

  @override
  String get financeAssetsTrend => '資産推移';

  @override
  String get financeThisCategory => 'このカテゴリ';

  @override
  String financeNoCategoriesOfType(String type) {
    return '$typeカテゴリなし';
  }

  @override
  String get financeImportDefaults => 'デフォルトをインポート';

  @override
  String get financeCatFood => '食費';

  @override
  String get financeCatTransport => '交通費';

  @override
  String get financeCatShopping => '買い物';

  @override
  String get financeCatRent => '家賃';

  @override
  String get financeCatDigital => 'デジタル';

  @override
  String get financeCatEntertainment => '娯楽';

  @override
  String get financeCatHealthcare => '医療';

  @override
  String get financeCatEducation => '教育';

  @override
  String get financeCatSalary => '給料';

  @override
  String get financeCatBonus => 'ボーナス';

  @override
  String get financeCatInvestment => '投資';

  @override
  String get financeCatFreelance => 'フリーランス';

  @override
  String get intimacyTitle => 'プライベート記録';

  @override
  String get intimacyNewRecord => '新規記録';

  @override
  String get intimacyEditRecord => '記録を編集';

  @override
  String get intimacySolo => 'ソロ';

  @override
  String get intimacyPartner => 'パートナー';

  @override
  String get intimacyPartners => 'パートナー';

  @override
  String get intimacyAddPartner => 'パートナーを追加';

  @override
  String get intimacyEditPartner => 'パートナーを編集';

  @override
  String get intimacyToys => 'トイ';

  @override
  String get intimacyAddToy => 'トイを追加';

  @override
  String get intimacyEditToy => 'トイを編集';

  @override
  String get intimacyPleasure => '満足度';

  @override
  String get intimacyDuration => '時間';

  @override
  String get intimacyLocation => '場所（任意）';

  @override
  String get intimacyNotes => 'メモ（任意）';

  @override
  String get intimacyOrgasm => 'オーガズムあり？';

  @override
  String get intimacyWatchedPorn => 'ポルノ視聴？';

  @override
  String get intimacyTimer => 'タイマー';

  @override
  String get intimacyNoRecords => '記録なし';

  @override
  String get intimacyNoPartners => 'パートナーなし';

  @override
  String get intimacyNoToys => 'トイなし';

  @override
  String get intimacyNoPartnersHint => 'パートナーなし — 設定から追加してください';

  @override
  String get intimacyShowAll => 'すべて表示';

  @override
  String get intimacyAllRecords => '全記録';

  @override
  String get intimacyStart => '開始';

  @override
  String get intimacyPause => '一時停止';

  @override
  String get intimacyResume => '再開';

  @override
  String get intimacyStopSave => '停止して保存';

  @override
  String get intimacyReset => 'リセット';

  @override
  String get intimacyTimerStartedAt => '開始時刻';

  @override
  String get intimacyTimerHistory => '履歴';

  @override
  String get intimacyTimerClearHistory => 'クリア';

  @override
  String get intimacyTimerRetention3d => '3日間';

  @override
  String get intimacyTimerRetention7d => '7日間';

  @override
  String get intimacyTimerRetention14d => '14日間';

  @override
  String get intimacyTimerRetentionForever => '永久';

  @override
  String get intimacyManage => '管理';

  @override
  String get intimacyModuleVisible => '表示中';

  @override
  String get intimacyModuleHidden => '非表示';

  @override
  String get intimacySortNewest => '新しい順';

  @override
  String get intimacySortOldest => '古い順';

  @override
  String get intimacySortPleasure => '快感度順';

  @override
  String get intimacySortDuration => '時間順';

  @override
  String get intimacyFilterAll => 'すべて';

  @override
  String get intimacyFilterSolo => 'ソロ';

  @override
  String get intimacyFilterPartnered => 'パートナーと';

  @override
  String get intimacyFilterOrgasm => 'オーガズムあり';

  @override
  String get intimacyFilterNoOrgasm => 'オーガズムなし';

  @override
  String get intimacyExportCsv => 'CSVエクスポート';

  @override
  String get intimacyExportCsvSuccess => 'CSVエクスポート完了';

  @override
  String get intimacyExportCsvEmpty => 'エクスポートする記録がありません';

  @override
  String get intimacyStartDate => '交際開始';

  @override
  String get intimacyEndDate => '交際終了';

  @override
  String get intimacyPurchaseDate => '購入日';

  @override
  String get intimacyRetiredDate => '引退日';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsGeneral => '一般';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get settingsThemeSystem => 'システム';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get settingsPrivacy => 'プライバシー';

  @override
  String get settingsIntimacyModule => 'プライベートモジュール';

  @override
  String get settingsData => 'データ';

  @override
  String get settingsStorageLocation => '保存場所';

  @override
  String get settingsStoragePathHint => 'データ保存先のディレクトリパスを入力。空欄でデフォルトを使用。';

  @override
  String get settingsDirectoryPath => 'ディレクトリパス';

  @override
  String get settingsResetDefault => 'デフォルトに戻す';

  @override
  String get settingsResetDefaultLocation => 'デフォルトの保存場所に戻しました';

  @override
  String get settingsStoragePathUpdated => '保存パスを更新しました';

  @override
  String get settingsOpenDataFolder => 'データフォルダを開く';

  @override
  String get settingsOpenDataFolderDesc => 'アプリケーションデータディレクトリを開く';

  @override
  String get settingsWebDAVSync => 'WebDAV 同期';

  @override
  String get settingsWebDAVNotConfigured => '未設定';

  @override
  String get settingsWebDAVConfigured => '設定済み';

  @override
  String get settingsWebDAVServerURL => 'サーバーURL';

  @override
  String get settingsWebDAVUsername => 'ユーザー名';

  @override
  String get settingsWebDAVPassword => 'パスワード';

  @override
  String get settingsWebDAVRemotePath => 'リモートパス';

  @override
  String get settingsWebDAVTestConnection => '接続テスト';

  @override
  String get settingsWebDAVConnectionSuccess => '接続成功';

  @override
  String get settingsWebDAVConnectionFailed => '接続失敗';

  @override
  String get settingsWebDAVSyncNow => '今すぐ同期';

  @override
  String get settingsWebDAVAutoSync => '自動同期';

  @override
  String get settingsWebDAVAutoSyncDesc => '編集後やアプリ復帰時に自動で同期します';

  @override
  String get settingsWebDAVSyncing => '同期中...';

  @override
  String get settingsWebDAVSyncSuccess => '同期完了';

  @override
  String get settingsWebDAVSyncFailed => '同期失敗';

  @override
  String get settingsWebDAVConflictTitle => '同期の競合';

  @override
  String get settingsWebDAVConflictDesc =>
      '以下のレコードがローカルとリモートの両方で変更されています。それぞれ保持するバージョンを選択してください：';

  @override
  String get settingsWebDAVKeepLocal => 'ローカルを保持';

  @override
  String get settingsWebDAVKeepRemote => 'リモートを保持';

  @override
  String get settingsWebDAVConflictApply => '適用';

  @override
  String get settingsWebDAVNextcloud => 'Nextcloud プリセット';

  @override
  String get settingsWebDAVCustom => 'カスタムサーバー';

  @override
  String get settingsImportExport => 'インポート/エクスポート';

  @override
  String get settingsExportJSON => 'ZIP エクスポート';

  @override
  String get settingsExportCSV => 'CSV エクスポート';

  @override
  String get csvExportFinance => '財務 CSV エクスポート';

  @override
  String get csvExportFinanceDesc => '財務取引を平文で出力';

  @override
  String get csvExportIntimacy => 'プライベート CSV エクスポート';

  @override
  String get csvExportIntimacyDesc => 'プライベート記録を平文で出力';

  @override
  String get csvExportWeight => '体重 CSV エクスポート';

  @override
  String get csvExportWeightDesc => '体重記録を平文で出力';

  @override
  String get settingsImport => 'ファイルからインポート';

  @override
  String get settingsExportSuccess => 'エクスポート成功';

  @override
  String get settingsExportFailed => 'エクスポート失敗';

  @override
  String get settingsImportSuccess => 'インポート成功';

  @override
  String get settingsImportFailed => 'インポート失敗';

  @override
  String get settingsImportConfirm => 'すべてのデータが置き換えられます。続行しますか？';

  @override
  String get settingsExportCSVWarning => 'CSVデータは平文でエクスポートされます。続行しますか？';

  @override
  String get settingsAbout => '情報';

  @override
  String get settingsAboutTitle => 'MyDay!!!!! について';

  @override
  String get commonSave => '保存';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonDelete => '削除';

  @override
  String get commonEdit => '編集';

  @override
  String get commonAdd => '追加';

  @override
  String get commonConfirm => '確認';

  @override
  String get commonYes => 'はい';

  @override
  String get commonNo => 'いいえ';

  @override
  String get commonOk => 'OK';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonName => '名前';

  @override
  String get commonEmojiOptional => '絵文字（任意）';

  @override
  String get commonOptional => '任意';

  @override
  String commonDeleteConfirm(String item) {
    return '$itemを削除しますか？';
  }

  @override
  String commonMinutes(int count) {
    return '$count分';
  }

  @override
  String get settingsExportSection => 'エクスポート';

  @override
  String get settingsImportSection => 'インポート';

  @override
  String get settingsExportFullBackup => '全データの完全バックアップ';

  @override
  String get settingsExportJSONPlaintext => '全データがZIPアーカイブとしてエクスポートされます';

  @override
  String get settingsExportCSVPlaintext => '財務取引を平文で出力';

  @override
  String get settingsImportRestore => 'ZIPバックアップから復元';

  @override
  String get settingsImportData => 'データをインポート';

  @override
  String get csvImportFinance => '財務 CSV インポート';

  @override
  String get csvImportFinanceDesc => 'CSV から取引をマージ（既存データは上書きされません）';

  @override
  String get csvImportIntimacy => 'プライベート CSV インポート';

  @override
  String get csvImportIntimacyDesc => 'CSV から記録をマージ（既存データは上書きされません）';

  @override
  String get csvImportConfirm => 'CSV データは既存の記録にマージされます。続行しますか？';

  @override
  String csvImportSuccess(int count) {
    return '$count 件のレコードをインポートしました';
  }

  @override
  String get csvImportFailed => 'CSV インポート失敗';

  @override
  String get csvImportEmpty => 'CSV に有効なレコードが見つかりません';

  @override
  String get csvTemplate => 'CSV テンプレート';

  @override
  String get csvTemplateFinance => '財務テンプレートをダウンロード';

  @override
  String get csvTemplateIntimacy => 'プライベートテンプレートをダウンロード';

  @override
  String get csvTemplateSaved => 'テンプレートを保存しました';

  @override
  String get settingsWebDAVDisconnect => '接続解除';

  @override
  String get settingsWebDAVConfigSaved => '設定を保存しました';

  @override
  String get settingsWebDAVConfigRemoved => '設定を削除しました';

  @override
  String get commonDontAskMinutes => '5分間確認しない';

  @override
  String get intimacyHideConfirm => 'モジュールを非表示にしてもデータは削除されません。いつでも再度有効にできます。';

  @override
  String get settingsLicense => 'ライセンス (GPLv3)';

  @override
  String get settingsLicenses => 'オープンソースライセンス';

  @override
  String get settingsPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get settingsDesktop => 'デスクトップ';

  @override
  String get settingsMinimizeToTray => 'トレイに最小化';

  @override
  String get settingsCloseToTray => 'トレイに閉じる';

  @override
  String get financeBankPresets => '銀行プリセット';

  @override
  String get financeBankSearch => '銀行またはアプリを検索...';

  @override
  String get financeBankNoResults => '該当する銀行が見つかりません';

  @override
  String get financeSubscriptions => 'サブスクリプション';

  @override
  String get financeSubscription => 'サブスク';

  @override
  String get financeAddSubscription => 'サブスクを追加';

  @override
  String get financeEditSubscription => 'サブスクを編集';

  @override
  String get financeStartDate => '開始日';

  @override
  String get financeTrialDays => '試用日数';

  @override
  String get financeBillingCycle => '請求サイクル';

  @override
  String get financeBillingCycleMonthly => '月次';

  @override
  String get financeBillingCycleYearly => '年次';

  @override
  String financeEveryXMonths(int count) {
    return '$count ヶ月ごと';
  }

  @override
  String financeEveryXYears(int count) {
    return '$count 年ごと';
  }

  @override
  String get financeBillingDay => '請求日';

  @override
  String get financeBillingMonth => '請求月';

  @override
  String get financeMonthlyDue => '月額';

  @override
  String get financeMonthlyAvg => '月平均';

  @override
  String get financeYearlyAvg => '年平均';

  @override
  String get financeNoSubscriptions => 'サブスクなし';

  @override
  String get financeActiveSubscriptions => '有効';

  @override
  String get financeHistoricalSubscriptions => '履歴';

  @override
  String get financeCancelSubscription => 'サブスクを解約';

  @override
  String get financeCancelImmediate => '今すぐ解約';

  @override
  String get financeCancelAtExpiry => '期限で解約';

  @override
  String get financeNextBilling => '次の請求';

  @override
  String get financeExpiryDate => '有効期限';

  @override
  String get financeTotalSpent => '累計支出';

  @override
  String get financeImportHistory => '過去の取引をインポート';

  @override
  String get financeImportHistoryDesc => '開始日が今日より前です。過去の取引をインポートしますか？';

  @override
  String get financeThisSubscription => 'このサブスク';

  @override
  String financeCancelledOn(String date) {
    return '$date に解約済み';
  }

  @override
  String get financeInterval => '間隔';

  @override
  String get financeImage => '画像';

  @override
  String get financePickImage => '画像を選択';

  @override
  String get financeChangeImage => '変更';

  @override
  String get financeUpcomingRenewals => '更新予定';

  @override
  String get financeSubscriptionReminder => 'サブスクリプションリマインダー';

  @override
  String get financeReminderTime => '通知時刻';

  @override
  String get financeReminderEnabled => '更新予定のサブスクリプションを通知';

  @override
  String financeSubscriptionDueSoon(String name, int days) {
    return '$name は$days日後に更新予定';
  }

  @override
  String financeSubscriptionDueToday(String name) {
    return '$name は今日更新予定';
  }

  @override
  String get financeSortBy => '並べ替え';

  @override
  String get financeSortByRenewal => '更新日順';

  @override
  String get financeSortByName => '名前順';

  @override
  String get financeSortCustom => 'カスタム';

  @override
  String get financeSortReorder => '並べ替え';

  @override
  String get financeSortDone => '完了';

  @override
  String get financeRestoreSubscription => 'サブスクリプションを復元';

  @override
  String get backupTitle => 'バックアップ';

  @override
  String get backupLocalOnlyNote =>
      'バックアップはこのデバイスのみに保存されます。クラウドバックアップにはWebDAV同期をご利用ください。';

  @override
  String get backupSettings => '設定';

  @override
  String get backupAutoDaily => '毎日自動バックアップ';

  @override
  String get backupAutoDailyDesc => '毎日自動的にバックアップを作成';

  @override
  String get backupRetention => 'バックアップ保持';

  @override
  String get backupRetentionForever => '永久保存';

  @override
  String backupRetentionDays(int count) {
    return '$count日間';
  }

  @override
  String get backupManual => '手動バックアップ';

  @override
  String get backupCreateNow => '今すぐバックアップ';

  @override
  String backupHistory(int count) {
    return 'バックアップ履歴 ($count)';
  }

  @override
  String get backupEmpty => 'バックアップなし';

  @override
  String get backupCreated => 'バックアップ作成成功';

  @override
  String get backupFailed => 'バックアップ失敗';

  @override
  String get backupRestore => '復元';

  @override
  String get backupRestoreConfirmTitle => '復元確認';

  @override
  String get backupRestoreConfirmDesc => '選択したモジュールのデータが置き換えられます。続行しますか？';

  @override
  String get backupRestoreSelectModules => '復元するモジュールを選択';

  @override
  String get backupRestoreAll => '全モジュール';

  @override
  String get backupRestoreSuccess => '復元成功。アプリを再起動してください。';

  @override
  String get backupRestoreFailed => '復元失敗';

  @override
  String get backupDeleteConfirmTitle => 'バックアップ削除';

  @override
  String get backupDeleteConfirmDesc => 'このバックアップは完全に削除されます。';

  @override
  String get backupModuleTodo => 'Todo';

  @override
  String get backupModuleFinance => '財務';

  @override
  String get backupModuleRates => '為替レート';

  @override
  String get backupModuleIntimacy => '親密';

  @override
  String intimacyRecordCount(int count) {
    return '$count 件の記録';
  }

  @override
  String get weightTitle => '体重';

  @override
  String get weightSetHeight => '身長を設定';

  @override
  String get weightNoRecords => '体重記録がありません';

  @override
  String get weightAddRecord => '記録を追加';

  @override
  String get weightKg => '体重（kg）';

  @override
  String get weightHeightCm => '身長（cm）';

  @override
  String get weightNote => 'メモ';

  @override
  String get weightNoteHint => '任意のメモ';

  @override
  String get weightChart => '推移';

  @override
  String get weightAll => '全期間';

  @override
  String get weightHistory => '履歴';

  @override
  String get weightShowAll => 'すべての記録を表示';

  @override
  String get weightDays => '日';

  @override
  String get weightDaysAgo => '日前';

  @override
  String get weightWeeksAgo => '週間前';

  @override
  String get weightToday => '今日';

  @override
  String get weightYesterday => '昨日';

  @override
  String get weightRecent => '最近';

  @override
  String get weightExportCsv => 'CSVエクスポート';

  @override
  String get weightExportCsvSuccess => '体重データをエクスポートしました';

  @override
  String get weightExportCsvEmpty => 'エクスポートする体重記録がありません';

  @override
  String get csvImportWeight => '体重 CSV インポート';

  @override
  String get csvImportWeightDesc => 'CSVから体重記録を統合（日付、時刻、体重）';

  @override
  String get csvTemplateWeight => '体重テンプレートをダウンロード';

  @override
  String get financeSubscriptionPresets => 'クイック入力';

  @override
  String get intimacyPurchaseLink => '購入リンク';

  @override
  String get intimacyPrice => '価格';

  @override
  String get intimacyPositions => '体位';

  @override
  String get intimacyAddPosition => '体位を追加';

  @override
  String get intimacyEditPosition => '体位を編集';

  @override
  String get intimacyNoPositions => '体位がありません';

  @override
  String get intimacyImportDefaults => 'デフォルトをインポート';

  @override
  String get intimacyTrend => 'トレンド';

  @override
  String get intimacyFrequency => '頻度';

  @override
  String get intimacyChartNoData => 'データ不足';

  @override
  String get weightTrend => 'トレンド';

  @override
  String get weightRaw => '実測';

  @override
  String get weightReminder => '体重リマインダー';

  @override
  String get weightReminderNone => 'リマインダーなし';

  @override
  String get weightReminderOnce => '1日１回';

  @override
  String get weightReminderTwice => '1日２回（朝・夜）';

  @override
  String get weightReminderMorning => '朝';

  @override
  String get weightReminderEvening => '夜';

  @override
  String get commonChange => '変更';

  @override
  String get commonPickImage => '画像を選択';

  @override
  String get commonRemoveIcon => 'アイコンを削除';

  @override
  String get commonPickIcon => 'アイコンを選択';

  @override
  String get commonNoData => 'データなし';

  @override
  String get todoDailyReminders => '毎日リマインダー';

  @override
  String get todoRemindReviewHint => 'Todoリストを確認するリマインダー';

  @override
  String get todoRemindUndoneHint => '未完了タスクのリマインダー';

  @override
  String get todoTapReturnToday => 'タップで今日に戻る';

  @override
  String get todoCalendar => 'カレンダー';

  @override
  String get todoWeekMon => '月';

  @override
  String get todoWeekTue => '火';

  @override
  String get todoWeekWed => '水';

  @override
  String get todoWeekThu => '木';

  @override
  String get todoWeekFri => '金';

  @override
  String get todoWeekSat => '土';

  @override
  String get todoWeekSun => '日';

  @override
  String get todoCalendarSomeDaily => '一部完了';

  @override
  String get todoCalendarAllDaily => '日課全完了';

  @override
  String get todoCalendarAllDone => '全完了';

  @override
  String get todoWhatNeedsDone => '何をする必要がありますか？';

  @override
  String todoReminderAt(String time) {
    return 'リマインダー：$time';
  }

  @override
  String get todoAddReminder => 'リマインダーを追加（任意）';

  @override
  String todoScheduledAt(String date) {
    return '予定：$date';
  }

  @override
  String get todoSetScheduledDate => '予定日を設定';

  @override
  String todoCompletedAt(String date) {
    return '完了：$date';
  }

  @override
  String get todoSetCompletedDate => '完了日を設定';

  @override
  String get weightUnitKg => 'kg';

  @override
  String weightValueKg(String value) {
    return '$value kg';
  }

  @override
  String get positionMissionary => '正常位';

  @override
  String get positionCowgirl => '騎乗位';

  @override
  String get positionDoggyStyle => 'バック';

  @override
  String get positionReverseCowgirl => '背面騎乗位';

  @override
  String get positionSpooning => '横向き';

  @override
  String get positionStanding => '立位';

  @override
  String get position69 => '69';

  @override
  String get positionLotus => '蓮華座';

  @override
  String get positionProneBone => 'うつ伏せ';

  @override
  String get notifTodoMorning => 'おはようございます！Todoリストを確認しましょう 📝';

  @override
  String get notifTodoCompletion => '今日の残りのタスクを完了しましょう！';

  @override
  String notifTodoUncompleted(int count) {
    return '今日はまだ $count 件のタスクが未完了です！';
  }

  @override
  String get notifWeightReminder => '体重を記録しましょう！⚖️';

  @override
  String notifUpcomingRenewals(String list) {
    return '更新予定：$list';
  }

  @override
  String notifSubscriptionToday(String name) {
    return '$name（今日）';
  }

  @override
  String notifSubscriptionDays(String name, int days) {
    return '$name（$days日後）';
  }

  @override
  String get trayShow => '表示';

  @override
  String get trayQuit => '終了';

  @override
  String get filePickerExportLocation => 'エクスポート先を選択';

  @override
  String get filePickerBackupFile => 'バックアップファイルを選択';

  @override
  String get filePickerCsvFile => 'CSVファイルを選択';

  @override
  String get filePickerSaveTemplate => 'テンプレートの保存先';

  @override
  String get financeBalance => '残高';

  @override
  String get financeNewAccount => '新規口座';

  @override
  String get financeAccountTypeFund => '普通';

  @override
  String get financeAccountTypeCredit => 'クレジット';

  @override
  String get financeAccountTypeRecharge => 'チャージ';

  @override
  String get financeAccountTypeFinancial => '投資';

  @override
  String get financeAccountName => '口座名';

  @override
  String get financeBankAppHint => '例：三菱UFJ、PayPay';

  @override
  String get financeCardNumberHint => '下4桁';

  @override
  String get financeCurrentBalanceHint => '空欄の場合取引から計算';

  @override
  String get financeAsOfToday => '今日時点';

  @override
  String get financeBalanceEffectiveDate => '残高基準日';

  @override
  String get financeFetchIcon => 'アイコンを取得';

  @override
  String get financeAccountsCategories => '口座とカテゴリ';

  @override
  String get financeEditRate => '為替レートを編集';

  @override
  String get financeNewRate => '新規為替レート';

  @override
  String get financeFrom => '変換元';

  @override
  String get financeTo => '変換先';

  @override
  String get financeRate => 'レート';

  @override
  String financeRateHint(String from, String to) {
    return '1 $from = ? $to';
  }

  @override
  String get financeNoRates => '為替レート未設定';

  @override
  String get financeNoExpenseData => 'この期間の支出データなし';

  @override
  String get financeUncategorized => '未分類';

  @override
  String get financeTotal => '合計';

  @override
  String get financeSelectDateRange => '日付範囲を選択';

  @override
  String get financeNoTransactionData => 'この期間の取引データなし';

  @override
  String financeReceivedAmount(String currency) {
    return '入金額 ($currency)';
  }

  @override
  String get financeReceivedAmountHelper => '先方口座の通貨での入金額';

  @override
  String get financeNoteHint => '何のため？';

  @override
  String get financeThisAccount => 'この口座';

  @override
  String get commonThisRecord => 'この記録';

  @override
  String get financeBalanceAdjustment => '残高調整';

  @override
  String get financeCatCreditCardPayment => 'クレジットカード決済';

  @override
  String get financeCatFixedDeposit => '定期預金満期';

  @override
  String get financeCatInternalTransfer => '内部振替';

  @override
  String get financeCatLoanRepayment => 'ローン返済';

  @override
  String get financeCatInvestmentTransfer => '投資振替';

  @override
  String get financeCatReimburse => '立替精算';

  @override
  String get settingsAutoStart => '起動時に自動起動';

  @override
  String get settingsApiEnabled => 'ローカル API サーバー';

  @override
  String get settingsApiServer => 'API サーバー設定';

  @override
  String settingsApiRunning(int port) {
    return 'ポート $port で実行中';
  }

  @override
  String get settingsApiStopped => '停止中';

  @override
  String get settingsApiNeedCredentials => 'ローカル以外のアクセスには認証が必要';

  @override
  String settingsApiRestarted(int port) {
    return 'API サーバーをポート $port で再起動しました';
  }

  @override
  String get settingsApiListenAddress => 'リッスンアドレス';

  @override
  String get settingsApiPort => 'ポート';

  @override
  String get settingsApiUsername => 'ユーザー名';

  @override
  String get settingsApiPassword => 'パスワード';
}
