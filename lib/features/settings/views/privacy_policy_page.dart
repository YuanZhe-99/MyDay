import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final text = _getText(locale);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsPrivacyPolicy)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          text,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

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

データバックアップ

アプリはローカルバックアップ機能を提供しています。バックアップファイルはお客様のデバイスに保存され、すべてのデータと画像が含まれます。バックアップファイルの保存と管理は完全にお客様の管理下にあります。

ポリシーの変更

このプライバシーポリシーは随時更新される場合があります。更新版はアプリ内または関連する配信チャネルで公開されます。''';
}
