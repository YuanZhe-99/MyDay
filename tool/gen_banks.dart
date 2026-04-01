// Regenerate assets/banks.json from banks-db with correct UTF-8 encoding.
// Run: dart run tool/gen_banks.dart

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

void main() async {
  final banksDbDir = p.join(Platform.environment['TEMP']!, 'banks-db', 'banks');
  final outFile = File('assets/banks.json');

  final entries = <Map<String, String>>[];

  final dir = Directory(banksDbDir);
  if (!dir.existsSync()) {
    print('banks-db not found at $banksDbDir');
    exit(1);
  }

  for (final countryDir in dir.listSync().whereType<Directory>()) {
    for (final file in countryDir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;
      final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final url = (raw['url'] as String?) ?? '';
      var domain = url
          .replaceFirst(RegExp(r'https?://(www\.)?'), '')
          .replaceFirst(RegExp(r'/.*$'), '');

      entries.add({
        'id': raw['name'] as String,
        'country': raw['country'] as String,
        'localTitle': (raw['localTitle'] as String?) ?? (raw['engTitle'] as String),
        'engTitle': raw['engTitle'] as String,
        'color': (raw['color'] as String?) ?? '#888888',
        'domain': domain,
      });
    }
  }

  // Sort by country then localTitle
  entries.sort((a, b) {
    final c = a['country']!.compareTo(b['country']!);
    if (c != 0) return c;
    return a['localTitle']!.compareTo(b['localTitle']!);
  });

  // Add manually curated entries not in banks-db
  final extras = <Map<String, String>>[
    // Japanese major banks
    {'id': 'mufg', 'country': 'jp', 'localTitle': '三菱UFJ銀行', 'engTitle': 'MUFG Bank', 'color': '#cc0033', 'domain': 'bk.mufg.jp'},
    {'id': 'smbc', 'country': 'jp', 'localTitle': '三井住友銀行', 'engTitle': 'Sumitomo Mitsui Banking', 'color': '#4caf50', 'domain': 'smbc.co.jp'},
    {'id': 'mizuho', 'country': 'jp', 'localTitle': 'みずほ銀行', 'engTitle': 'Mizuho Bank', 'color': '#003399', 'domain': 'mizuhobank.co.jp'},
    {'id': 'resona', 'country': 'jp', 'localTitle': 'りそな銀行', 'engTitle': 'Resona Bank', 'color': '#009e60', 'domain': 'resonabank.co.jp'},
    {'id': 'japan-post', 'country': 'jp', 'localTitle': 'ゆうちょ銀行', 'engTitle': 'Japan Post Bank', 'color': '#ff6600', 'domain': 'jp-bank.japanpost.jp'},
    {'id': 'rakuten-bank', 'country': 'jp', 'localTitle': '楽天銀行', 'engTitle': 'Rakuten Bank', 'color': '#bf0000', 'domain': 'rakuten-bank.co.jp'},
    {'id': 'sbi-shinsei', 'country': 'jp', 'localTitle': 'SBI新生銀行', 'engTitle': 'SBI Shinsei Bank', 'color': '#0066cc', 'domain': 'sbishinseibank.co.jp'},
    {'id': 'aeon-bank', 'country': 'jp', 'localTitle': 'イオン銀行', 'engTitle': 'AEON Bank', 'color': '#9c27b0', 'domain': 'aeonbank.co.jp'},
    // Popular fintech / payment apps
    {'id': 'alipay', 'country': 'cn', 'localTitle': '支付宝', 'engTitle': 'Alipay', 'color': '#1677ff', 'domain': 'alipay.com'},
    {'id': 'wechat-pay', 'country': 'cn', 'localTitle': '微信支付', 'engTitle': 'WeChat Pay', 'color': '#07c160', 'domain': 'pay.weixin.qq.com'},
    {'id': 'paypal', 'country': 'us', 'localTitle': 'PayPal', 'engTitle': 'PayPal', 'color': '#003087', 'domain': 'paypal.com'},
    {'id': 'wise', 'country': 'gb', 'localTitle': 'Wise', 'engTitle': 'Wise', 'color': '#9fe870', 'domain': 'wise.com'},
    {'id': 'revolut', 'country': 'gb', 'localTitle': 'Revolut', 'engTitle': 'Revolut', 'color': '#0075eb', 'domain': 'revolut.com'},
    {'id': 'line-pay', 'country': 'jp', 'localTitle': 'LINE Pay', 'engTitle': 'LINE Pay', 'color': '#06c755', 'domain': 'pay.line.me'},
    {'id': 'paypay', 'country': 'jp', 'localTitle': 'PayPay', 'engTitle': 'PayPay', 'color': '#ff0033', 'domain': 'paypay.ne.jp'},
  ];

  entries.addAll(extras);

  // Write with proper UTF-8 (no BOM)
  const encoder = JsonEncoder.withIndent('  ');
  final json = encoder.convert(entries);
  outFile.writeAsStringSync(json, encoding: utf8);

  print('Written ${entries.length} banks to ${outFile.path}');
}
