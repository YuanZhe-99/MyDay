import 'dart:io';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../features/finance/models/finance.dart';
import '../../features/finance/services/finance_storage.dart';
import '../../features/intimacy/models/intimacy_record.dart';
import '../../features/intimacy/services/intimacy_storage.dart';
import '../../features/weight/models/weight_record.dart';
import '../../features/weight/services/weight_storage.dart';
import '../../features/todo/services/todo_storage.dart';

class ImportExportService {
  static const _dataFileNames = [
    'todo_data.json',
    'finance_data.json',
    'exchange_rates.json',
    'intimacy_data.json',
    'weight_data.json',
  ];

  /// Export all data as a ZIP file containing JSON data files and images.
  /// Returns the exported file path, or null on failure.
  static Future<String?> exportZIP(String destDir) async {
    try {
      final appDir = await TodoStorage.getAppDir();
      final archive = Archive();

      for (final name in _dataFileNames) {
        final file = File('${appDir.path}/$name');
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          archive.addFile(ArchiveFile(name, bytes.length, bytes));
        }
      }

      // Include images
      final imgDir = Directory(p.join(appDir.path, 'images'));
      if (await imgDir.exists()) {
        await for (final entity in imgDir.list()) {
          if (entity is File) {
            final bytes = await entity.readAsBytes();
            final name = 'images/${p.basename(entity.path)}';
            archive.addFile(ArchiveFile(name, bytes.length, bytes));
          }
        }
      }

      final zipData = ZipEncoder().encode(archive);

      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final outFile = File(p.join(destDir, 'myday_backup_$stamp.zip'));
      await outFile.writeAsBytes(zipData);
      return outFile.path;
    } catch (_) {
      return null;
    }
  }

  /// Export finance transactions as CSV.
  /// Returns the exported file path, or null on failure.
  static Future<String?> exportCSV(String destDir) async {
    try {
      final data = await FinanceStorage.load();
      if (data == null) return null;

      final buf = StringBuffer();
      buf.writeln('Date,Type,Category,Amount,Currency,Account,Note');
      for (final tx in data.transactions) {
        final date = DateFormat('yyyy-MM-dd HH:mm').format(tx.date);
        final cat = data.categories
                .where((c) => c.id == tx.categoryId)
                .firstOrNull
                ?.name ??
            '';
        final acct =
            data.accounts.where((a) => a.id == tx.accountId).firstOrNull;
        final acctName = acct?.name ?? '';
        final note = tx.note.replaceAll('"', '""');
        buf.writeln(
            '$date,${tx.type.name},"$cat",${tx.amount},${tx.currency},"$acctName","$note"');
      }

      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final outFile = File('$destDir/myday_finance_$stamp.csv');
      await outFile.writeAsString(buf.toString());
      return outFile.path;
    } catch (_) {
      return null;
    }
  }

  /// Export intimacy records as CSV.
  /// Returns the exported file path, or null on failure.
  static Future<String?> exportIntimacyCSV(String destDir) async {
    try {
      final data = await IntimacyStorage.load();
      if (data == null) return null;

      final buf = StringBuffer();
      buf.writeln('Date,Type,IsSolo,Partner,Toys,PleasureLevel,Duration(min),HadOrgasm,WatchedPorn,Location,Notes');
      for (final r in data.records) {
        final date = DateFormat('yyyy-MM-dd HH:mm').format(r.datetime);
        final partner = r.partnerId != null
            ? data.partners.where((p) => p.id == r.partnerId).firstOrNull?.name ?? ''
            : '';
        final toyNames = r.toyIds
            .map((id) => data.toys.where((t) => t.id == id).firstOrNull?.name ?? '')
            .where((n) => n.isNotEmpty)
            .join(';');
        final durMin = (r.duration.inSeconds / 60.0).toStringAsFixed(1);
        final location = (r.location ?? '').replaceAll('"', '""');
        final notes = (r.notes ?? '').replaceAll('"', '""');
        final partnerEscaped = partner.replaceAll('"', '""');
        buf.writeln(
            '$date,${r.type},${r.isSolo},"$partnerEscaped","$toyNames",${r.pleasureLevel},$durMin,${r.hadOrgasm},${r.watchedPorn},"$location","$notes"');
      }

      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final outFile = File('$destDir/myday_intimacy_$stamp.csv');
      await outFile.writeAsString(buf.toString());
      return outFile.path;
    } catch (_) {
      return null;
    }
  }

  /// Export weight records as CSV.
  /// Format matches MyWeight² CSV: Date, Time, Weight (kg)
  static Future<String?> exportWeightCSV(String destDir) async {
    try {
      final data = await WeightStorage.load();
      if (data == null || data.records.isEmpty) return null;

      final sorted = List<WeightRecord>.from(data.records)
        ..sort((a, b) => a.datetime.compareTo(b.datetime));

      final buf = StringBuffer();
      buf.writeln('Date, Time, Weight (kg)');
      for (final r in sorted) {
        final date = DateFormat('M/d/yyyy').format(r.datetime);
        final time = DateFormat('HH:mm').format(r.datetime);
        buf.writeln('$date, $time, ${r.weight.toStringAsFixed(2)}');
      }

      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final outFile = File('$destDir/myday_weight_$stamp.csv');
      await outFile.writeAsString(buf.toString());
      return outFile.path;
    } catch (_) {
      return null;
    }
  }

  /// Import data from a previously exported ZIP file.
  /// Returns true on success.
  static Future<bool> importZIP(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final appDir = await TodoStorage.getAppDir();

      for (final entry in archive) {
        if (entry.isFile) {
          // Prevent path traversal attacks
          final normalized = p.normalize(entry.name);
          if (p.isAbsolute(normalized) || normalized.startsWith('..')) continue;

          final outPath = p.join(appDir.path, normalized);
          final parent = Directory(p.dirname(outPath));
          if (!await parent.exists()) {
            await parent.create(recursive: true);
          }
          final outFile = File(outPath);
          await outFile.writeAsBytes(entry.content as List<int>);
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  // ── CSV helpers ──

  /// Parse a CSV line handling quoted fields with commas and escaped quotes.
  static List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    final buf = StringBuffer();
    var inQuote = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (inQuote) {
        if (c == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            buf.write('"');
            i++;
          } else {
            inQuote = false;
          }
        } else {
          buf.write(c);
        }
      } else {
        if (c == '"') {
          inQuote = true;
        } else if (c == ',') {
          fields.add(buf.toString());
          buf.clear();
        } else {
          buf.write(c);
        }
      }
    }
    fields.add(buf.toString());
    return fields;
  }

  /// Import finance transactions from CSV and merge into existing data.
  /// CSV columns: Date,Type,Category,Amount,Currency,Account,Note
  /// Returns (success, importedCount) tuple.
  static Future<(bool, int)> importFinanceCSV(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return (false, 0);

      final lines = (await file.readAsString())
          .split(RegExp(r'\r?\n'))
          .where((l) => l.trim().isNotEmpty)
          .toList();
      if (lines.length < 2) return (true, 0); // header only

      final data = await FinanceStorage.load();
      final accounts = List<Account>.from(data?.accounts ?? []);
      final categories = List<Category>.from(data?.categories ?? []);
      final transactions = List<Transaction>.from(data?.transactions ?? []);
      final existingIds = transactions.map((t) => t.id).toSet();

      var imported = 0;
      for (var i = 1; i < lines.length; i++) {
        final fields = _parseCsvLine(lines[i]);
        if (fields.length < 7) continue;

        final dateStr = fields[0].trim();
        final typeStr = fields[1].trim().toLowerCase();
        final catName = fields[2].trim();
        final amountStr = fields[3].trim();
        final currency = fields[4].trim();
        final acctName = fields[5].trim();
        final note = fields[6].trim();

        // Parse date
        DateTime date;
        try {
          date = DateFormat('yyyy-MM-dd HH:mm').parse(dateStr);
        } catch (_) {
          try {
            date = DateTime.parse(dateStr);
          } catch (_) {
            continue; // skip unparseable rows
          }
        }

        // Parse type
        TransactionType txType;
        switch (typeStr) {
          case 'expense':
            txType = TransactionType.expense;
          case 'income':
            txType = TransactionType.income;
          case 'transfer':
            txType = TransactionType.transfer;
          default:
            continue;
        }

        // Parse amount
        final amount = double.tryParse(amountStr);
        if (amount == null) continue;

        // Resolve account by name (must exist)
        final acct = accounts
            .where((a) => a.name == acctName)
            .firstOrNull;
        if (acct == null) continue; // skip if account not found

        // Resolve or create category by name
        String? categoryId;
        if (catName.isNotEmpty) {
          var cat = categories
              .where((c) => c.name == catName && c.type == txType)
              .firstOrNull;
          if (cat == null && txType != TransactionType.transfer) {
            cat = Category(
              name: catName,
              icon: const IconRef(codePoint: 0xe5d2), // label icon
              type: txType,
            );
            categories.add(cat);
          }
          categoryId = cat?.id;
        }

        final tx = Transaction(
          type: txType,
          amount: amount,
          currency: currency.isEmpty ? (data?.defaultCurrency ?? 'CNY') : currency,
          accountId: acct.id,
          categoryId: categoryId,
          note: note,
          date: date,
        );

        if (!existingIds.contains(tx.id)) {
          transactions.add(tx);
          imported++;
        }
      }

      // Save merged data
      await FinanceStorage.save(FinanceData(
        accounts: accounts,
        categories: categories,
        transactions: transactions,
        subscriptions: data?.subscriptions ?? [],
        defaultCurrency: data?.defaultCurrency ?? 'CNY',
        subscriptionReminderHour: data?.subscriptionReminderHour,
        subscriptionReminderMinute: data?.subscriptionReminderMinute,
        subscriptionSortMode: data?.subscriptionSortMode,
        subscriptionCustomOrder: data?.subscriptionCustomOrder,
      ));

      return (true, imported);
    } catch (_) {
      return (false, 0);
    }
  }

  /// Import intimacy records from CSV and merge into existing data.
  /// CSV columns: Date,Type,IsSolo,Partner,Toys,PleasureLevel,Duration(min),
  ///              HadOrgasm,WatchedPorn,Location,Notes
  /// Returns (success, importedCount) tuple.
  static Future<(bool, int)> importIntimacyCSV(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return (false, 0);

      final lines = (await file.readAsString())
          .split(RegExp(r'\r?\n'))
          .where((l) => l.trim().isNotEmpty)
          .toList();
      if (lines.length < 2) return (true, 0);

      final data = await IntimacyStorage.load();
      final partners = List<Partner>.from(data?.partners ?? []);
      final toys = List<Toy>.from(data?.toys ?? []);
      final records = List<IntimacyRecord>.from(data?.records ?? []);

      var imported = 0;
      for (var i = 1; i < lines.length; i++) {
        final fields = _parseCsvLine(lines[i]);
        if (fields.length < 11) continue;

        final dateStr = fields[0].trim();
        final type = fields[1].trim();
        final isSoloStr = fields[2].trim().toLowerCase();
        final partnerName = fields[3].trim();
        final toysStr = fields[4].trim();
        final plStr = fields[5].trim();
        final durStr = fields[6].trim();
        final orgasmStr = fields[7].trim().toLowerCase();
        final pornStr = fields[8].trim().toLowerCase();
        final location = fields[9].trim();
        final notes = fields[10].trim();

        // Parse date
        DateTime datetime;
        try {
          datetime = DateFormat('yyyy-MM-dd HH:mm').parse(dateStr);
        } catch (_) {
          try {
            datetime = DateTime.parse(dateStr);
          } catch (_) {
            continue;
          }
        }

        final isSolo = isSoloStr == 'true' || isSoloStr == '1';
        final pleasureLevel = int.tryParse(plStr) ?? 0;
        if (pleasureLevel < 0 || pleasureLevel > 5) continue;

        final durationMin = double.tryParse(durStr) ?? 0;

        final hadOrgasm = orgasmStr == 'true' || orgasmStr == '1';
        final watchedPorn = pornStr == 'true' || pornStr == '1';

        // Resolve or create partner
        String? partnerId;
        if (!isSolo && partnerName.isNotEmpty) {
          var partner = partners.where((p) => p.name == partnerName).firstOrNull;
          if (partner == null) {
            partner = Partner(name: partnerName);
            partners.add(partner);
          }
          partnerId = partner.id;
        }

        // Resolve or create toys (semicolon-separated)
        final toyIds = <String>[];
        if (toysStr.isNotEmpty) {
          for (final toyName in toysStr.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty)) {
            var toy = toys.where((t) => t.name == toyName).firstOrNull;
            if (toy == null) {
              toy = Toy(name: toyName);
              toys.add(toy);
            }
            toyIds.add(toy.id);
          }
        }

        final record = IntimacyRecord(
          type: type.isEmpty ? (isSolo ? 'Solo' : 'Regular') : type,
          isSolo: isSolo,
          partnerId: partnerId,
          toyIds: toyIds,
          pleasureLevel: pleasureLevel,
          duration: Duration(seconds: (durationMin * 60).round()),
          datetime: datetime,
          hadOrgasm: hadOrgasm,
          watchedPorn: watchedPorn,
          location: location.isEmpty ? null : location,
          notes: notes.isEmpty ? null : notes,
        );

        records.add(record);
        imported++;
      }

      // Save merged data
      await IntimacyStorage.save(IntimacyData(
        partners: partners,
        toys: toys,
        records: records,
      ));

      return (true, imported);
    } catch (_) {
      return (false, 0);
    }
  }

  /// Import weight records from CSV and merge into existing data.
  /// Supports format: Date, Time, Weight (kg)
  /// Also supports: Date,Time,Weight (kg) (no spaces after comma)
  /// Returns (success, importedCount) tuple.
  static Future<(bool, int)> importWeightCSV(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return (false, 0);

      final lines = (await file.readAsString())
          .split(RegExp(r'\r?\n'))
          .where((l) => l.trim().isNotEmpty)
          .toList();
      if (lines.length < 2) return (true, 0);

      final data = await WeightStorage.load();
      final records = List<WeightRecord>.from(data?.records ?? []);
      final existingIds = records.map((r) => r.id).toSet();

      var imported = 0;
      for (var i = 1; i < lines.length; i++) {
        final fields = _parseCsvLine(lines[i]);
        if (fields.length < 3) continue;

        final dateStr = fields[0].trim();
        final timeStr = fields[1].trim();
        final weightStr = fields[2].trim();

        // Parse date and time
        DateTime datetime;
        try {
          // Try M/d/yyyy format first (MyWeight² style)
          final datePart = DateFormat('M/d/yyyy').parse(dateStr);
          final timeParts = timeStr.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          datetime = DateTime(
            datePart.year,
            datePart.month,
            datePart.day,
            hour,
            minute,
          );
        } catch (_) {
          try {
            // Try yyyy-MM-dd format
            final datePart = DateFormat('yyyy-MM-dd').parse(dateStr);
            final timeParts = timeStr.split(':');
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);
            datetime = DateTime(
              datePart.year,
              datePart.month,
              datePart.day,
              hour,
              minute,
            );
          } catch (_) {
            try {
              // Try combined as a single datetime string
              datetime = DateTime.parse('$dateStr $timeStr');
            } catch (_) {
              continue;
            }
          }
        }

        // Parse weight
        final weight = double.tryParse(weightStr);
        if (weight == null || weight <= 0) continue;

        final record = WeightRecord(
          weight: weight,
          datetime: datetime,
        );

        if (!existingIds.contains(record.id)) {
          records.add(record);
          imported++;
        }
      }

      await WeightStorage.save(WeightData(
        height: data?.height,
        records: records,
      ));

      return (true, imported);
    } catch (_) {
      return (false, 0);
    }
  }
}
