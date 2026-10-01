import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/adaptive_layout.dart';
import '../../../shared/widgets/adaptive_tile_grid.dart';

class PrivacyPolicyPage extends StatelessWidget {
  /// Purpose: Create a privacy policy page instance.
  /// Inputs: None.
  /// Returns: A new `PrivacyPolicyPage` instance.
  /// Side effects: None.
  /// Notes: None.
  const PrivacyPolicyPage({super.key});

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final text = _getText(locale);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsPrivacyPolicy)),
      body: AdaptiveContentWidth(
        maxWidth: readingMaxContentWidth,
        child: SingleChildScrollView(
          padding: navBarAwarePadding(context, const EdgeInsets.all(16)),
          child: SelectableText(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }

  /// Purpose: Provide the internal get text helper for this file.
  /// Inputs: `locale`.
  /// Returns: `String`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  String _getText(Locale locale) {
    if (locale.languageCode == 'zh' && locale.countryCode == 'TW') {
      return _zhTW;
    }
    switch (locale.languageCode) {
      case 'zh':
        return _zh;
      case 'ja':
        return _ja;
      default:
        return _en;
    }
  }

  static const _en = '''Privacy Policy

Thank you for using MyDay!!!!!. We take your privacy seriously. This privacy policy explains how the app handles your data.

Data Collection

MyDay!!!!! does not collect, upload, or share any personal information. The app contains no analytics, advertising trackers, or data collection of any kind.

Data Storage

All data you enter in the app — tasks, financial records, intimate life records, weight records, and settings — is stored locally on your device. You may change this to a custom path at any time (Desktop only).

Network Access

MyDay!!!!! accesses the internet only in the following situations:

• Exchange rate updates: The app periodically fetches currency exchange rates from open.er-api.com to keep your multi-currency financial records up to date. Only the base currency code is sent in the request; no personal or financial data is transmitted.

• WebDAV sync: If you enable WebDAV cloud sync, the app sends your data to a WebDAV server that you configure yourself. The app does not send data to any other server.

• Bank logo fetching: When you add a financial account with a bank association, the app may fetch the bank's logo from Google Favicon, Icon Horse, DuckDuckGo, or Clearbit using the bank's public website URL. No personal data is sent.

No other network communication takes place.

Third-Party Services

The app uses the following third-party services:

• open.er-api.com — for currency exchange rates
• Google Favicon / Icon Horse / DuckDuckGo / Clearbit — for bank logo images

These services have their own privacy policies, which we encourage you to review. MyDay!!!!! only sends minimal, non-personal data (currency codes or public bank URLs) to these services.

On-Device AI (optional, since 1.5.0)

The Todo, Finance, Weight and Intimacy pages can optionally show short summaries and suggestions written by the language model built into your device — Gemini Nano through Android AICore, or the model that is part of Apple Intelligence on iOS 26 and macOS 26 or later. This is off by default and runs only after you turn on "Use on-device AI" in Settings. It is not available on Windows.

• Everything the model does happens on your device. It is given only figures the app has already calculated: for Todo, today's and tomorrow's task titles and whether they are done; for Finance, monthly totals, category and subscription names and subscription costs; for Weight, your weight trend and measurements; for Intimacy, counts and averages and your body measurements and estimated cycle phase. Notes, card numbers, security codes, bank names, locations and the names of partners, toys and positions are never given to it.

• On Android, the model is downloaded by the AICore system service from Google, and only when you tap Download in Settings. On Apple devices the model is part of Apple Intelligence and is managed by the system.

• Generated results stay on your device: they are neither synced, backed up nor exported, and you can clear them in Settings. No cloud model is used, including Apple's Private Cloud Compute.

Data Backup

The app provides a local backup feature. Backup files are stored on your device and include all your data and images. The storage and management of backup files is entirely under your control.

Changes to This Policy

This privacy policy may be updated from time to time. Updated versions will be published within the app or on the relevant distribution channels.''';

  static const _zh = '''隐私政策

感谢您使用 MyDay!!!!!。我们非常重视您的隐私。本隐私政策说明了应用如何处理您的数据。

数据收集

MyDay!!!!! 不收集、上传或共享任何个人信息。应用不包含任何分析工具、广告追踪器或数据收集功能。

数据存储

您在应用中输入的所有数据——任务、财务记录、亲密生活记录、体重记录和设置——均存储在您的设备本地。您可以随时更改存储路径（仅桌面版）。

网络访问

MyDay!!!!! 仅在以下情况下访问互联网：

• 汇率更新：应用会定期从 open.er-api.com 获取货币汇率，以保持您的多币种财务记录准确。请求中仅发送基准货币代码，不传输任何个人或财务数据。

• WebDAV 同步：如果您启用了 WebDAV 云同步，应用会将您的数据发送到您自行配置的 WebDAV 服务器。应用不会向其他任何服务器发送数据。

• 银行图标获取：当您添加关联银行的财务账户时，应用可能会通过银行的公开网址从 Google Favicon、Icon Horse、DuckDuckGo 或 Clearbit 获取银行图标。不会发送任何个人数据。

除此之外不进行任何网络通信。

第三方服务

应用使用以下第三方服务：

• open.er-api.com ——用于货币汇率
• Google Favicon / Icon Horse / DuckDuckGo / Clearbit ——用于银行图标

这些服务有各自的隐私政策，建议您查阅。MyDay!!!!! 仅向这些服务发送最少的非个人数据（货币代码或公开的银行网址）。

端侧 AI（可选，自 1.5.0 起）

待办、财务、体重和性生活页面可以选择显示由您设备内置的语言模型写出的简短总结与建议——Android 上通过 AICore 使用 Gemini Nano，iOS 26 和 macOS 26 及以上使用 Apple Intelligence 的模型。此功能默认关闭，只有在您于设置中开启「使用端侧 AI」后才会运行。Windows 上不提供。

• 模型的所有处理都在您的设备上完成。它只会拿到应用已经算好的数字：待办为今天和明天的任务标题及完成情况；财务为每月合计、分类名称、订阅名称和订阅费用；体重为体重趋势和身体围度；性生活为次数和平均值，以及您的身体围度和估算的周期阶段。备注、卡号、安全码、银行名称、地点，以及伴侣、玩具和姿势的名称永远不会交给模型。

• 在 Android 上，模型由系统服务 AICore 从 Google 下载，并且只在您于设置中点「下载」时才开始。在 Apple 设备上，模型属于 Apple Intelligence，由系统管理。

• 生成的结果只保存在您的设备上：不会同步、备份或导出，您可以在设置中清除。不使用任何云端模型，包括 Apple 的私有云计算（Private Cloud Compute）。

数据备份

应用提供本地备份功能。备份文件存储在您的设备上，包含您的所有数据和图片。备份文件的存储和管理完全由您掌控。

政策变更

本隐私政策可能会不时更新。更新版本将在应用内或相关分发渠道发布。''';

  static const _zhTW = '''隱私政策

感謝您使用 MyDay!!!!!。我們非常重視您的隱私。本隱私政策說明了應用程式如何處理您的資料。

資料收集

MyDay!!!!! 不收集、上傳或分享任何個人資訊。應用程式不包含任何分析工具、廣告追蹤器或資料收集功能。

資料儲存

您在應用程式中輸入的所有資料——任務、財務記錄、親密生活記錄、體重記錄和設定——均儲存在您的裝置本機。您可以隨時更改儲存路徑（僅桌面版）。

網路存取

MyDay!!!!! 僅在以下情況下存取網際網路：

• 匯率更新：應用程式會定期從 open.er-api.com 取得貨幣匯率，以保持您的多幣種財務記錄準確。請求中僅發送基準貨幣代碼，不傳輸任何個人或財務資料。

• WebDAV 同步：如果您啟用了 WebDAV 雲端同步，應用程式會將您的資料傳送到您自行設定的 WebDAV 伺服器。應用程式不會向其他任何伺服器傳送資料。

• 銀行圖示取得：當您新增關聯銀行的財務帳戶時，應用程式可能會透過銀行的公開網址從 Google Favicon、Icon Horse、DuckDuckGo 或 Clearbit 取得銀行圖示。不會傳送任何個人資料。

除此之外不進行任何網路通訊。

第三方服務

應用程式使用以下第三方服務：

• open.er-api.com ——用於貨幣匯率
• Google Favicon / Icon Horse / DuckDuckGo / Clearbit ——用於銀行圖示

這些服務有各自的隱私政策，建議您查閱。MyDay!!!!! 僅向這些服務傳送最少的非個人資料（貨幣代碼或公開的銀行網址）。

裝置端 AI（選用，自 1.5.0 起）

待辦、財務、體重和性生活頁面可以選擇顯示由您裝置內建的語言模型寫出的簡短總結與建議——Android 上透過 AICore 使用 Gemini Nano，iOS 26 和 macOS 26 及以上使用 Apple Intelligence 的模型。此功能預設關閉，只有在您於設定中開啟「使用裝置端 AI」後才會執行。Windows 上不提供。

• 模型的所有處理都在您的裝置上完成。它只會拿到應用程式已經算好的數字：待辦為今天和明天的任務標題及完成情況；財務為每月合計、分類名稱、訂閱名稱和訂閱費用；體重為體重趨勢和身體圍度；性生活為次數和平均值，以及您的身體圍度和估算的週期階段。備註、卡號、安全碼、銀行名稱、地點，以及伴侶、玩具和姿勢的名稱永遠不會交給模型。

• 在 Android 上，模型由系統服務 AICore 從 Google 下載，而且只在您於設定中點「下載」時才開始。在 Apple 裝置上，模型屬於 Apple Intelligence，由系統管理。

• 產生的結果只儲存在您的裝置上：不會同步、備份或匯出，您可以在設定中清除。不使用任何雲端模型，包括 Apple 的私有雲端運算（Private Cloud Compute）。

資料備份

應用程式提供本機備份功能。備份檔案儲存在您的裝置上，包含您的所有資料和圖片。備份檔案的儲存和管理完全由您掌控。

政策變更

本隱私政策可能會不時更新。更新版本將在應用程式內或相關分發管道發布。''';

  static const _ja = '''プライバシーポリシー

MyDay!!!!! をご利用いただきありがとうございます。私たちはお客様のプライバシーを重視しています。このプライバシーポリシーは、アプリがお客様のデータをどのように取り扱うかを説明します。

データ収集

MyDay!!!!! は個人情報の収集、アップロード、共有を一切行いません。アプリにはアナリティクス、広告トラッカー、データ収集機能は含まれていません。

データ保存

アプリに入力されたすべてのデータ（タスク、財務記録、親密な生活の記録、体重記録、設定）は、お客様のデバイスにローカルで保存されます。保存先はいつでも変更できます（デスクトップ版のみ）。

ネットワークアクセス

MyDay!!!!! は以下の場合にのみインターネットにアクセスします：

• 為替レートの更新：アプリは open.er-api.com から定期的に為替レートを取得し、複数通貨の財務記録を最新に保ちます。リクエストには基準通貨コードのみが送信され、個人情報や財務データは送信されません。

• WebDAV同期：WebDAVクラウド同期を有効にした場合、アプリはお客様が設定したWebDAVサーバーにデータを送信します。それ以外のサーバーにデータを送信することはありません。

• 銀行ロゴの取得：銀行に関連付けられた金融口座を追加する際、アプリは銀行の公開ウェブサイトURLを使用して Google Favicon、Icon Horse、DuckDuckGo、または Clearbit から銀行のロゴを取得する場合があります。個人データは送信されません。

上記以外のネットワーク通信は行われません。

サードパーティサービス

アプリは以下のサードパーティサービスを使用しています：

• open.er-api.com ——為替レート用
• Google Favicon / Icon Horse / DuckDuckGo / Clearbit ——銀行ロゴ画像用

これらのサービスには独自のプライバシーポリシーがあります。ご確認をお勧めします。MyDay!!!!! はこれらのサービスに最小限の非個人データ（通貨コードまたは公開の銀行URL）のみを送信します。

オンデバイスAI（任意、1.5.0 以降）

ToDo・家計・体重・性生活の各ページでは、端末に内蔵された言語モデル（Android では AICore 経由の Gemini Nano、iOS 26 / macOS 26 以降では Apple Intelligence のモデル）が書いた短い要約と提案を表示できます。初期状態ではオフで、設定で「オンデバイスAIを使う」をオンにした後にのみ動作します。Windows では利用できません。

• モデルの処理はすべて端末内で行われます。モデルに渡されるのは、アプリが計算済みの数値だけです：ToDo では今日と明日のタスク名と完了状況、家計では月ごとの合計・カテゴリ名・サブスクリプション名と費用、体重では体重の推移と各部のサイズ、性生活では回数と平均値、体のサイズと推定の周期フェーズです。メモ、カード番号、セキュリティコード、銀行名、場所、パートナー・おもちゃ・体位の名前がモデルに渡されることはありません。

• Android では、モデルは AICore システムサービスが Google からダウンロードし、設定で「ダウンロード」をタップしたときだけ行われます。Apple のデバイスでは、モデルは Apple Intelligence の一部としてシステムが管理します。

• 生成された結果は端末内にのみ保存され、同期・バックアップ・エクスポートされることはなく、設定から消去できます。Apple の Private Cloud Compute を含め、クラウドのモデルは一切使用しません。

データバックアップ

アプリはローカルバックアップ機能を提供しています。バックアップファイルはお客様のデバイスに保存され、すべてのデータと画像が含まれます。バックアップファイルの保存と管理は完全にお客様の管理下にあります。

ポリシーの変更

このプライバシーポリシーは随時更新される場合があります。更新版はアプリ内または関連する配信チャネルで公開されます。''';
}
