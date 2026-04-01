import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../l10n/app_localizations.dart';
import '../services/auto_sync_service.dart';
import '../services/import_export_service.dart';

class ImportExportPage extends StatelessWidget {
  const ImportExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsImportExport),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _Section(title: AppLocalizations.of(context)!.settingsExportSection, children: [
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: Text(AppLocalizations.of(context)!.settingsExportJSON),
              subtitle: Text(AppLocalizations.of(context)!.settingsExportJSONPlaintext),
              onTap: () => _exportJSON(context),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: Text(AppLocalizations.of(context)!.csvExportFinance),
              subtitle: Text(AppLocalizations.of(context)!.csvExportFinanceDesc),
              onTap: () => _exportCSV(context, _CSVType.finance),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: Text(AppLocalizations.of(context)!.csvExportIntimacy),
              subtitle: Text(AppLocalizations.of(context)!.csvExportIntimacyDesc),
              onTap: () => _exportCSV(context, _CSVType.intimacy),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: Text(AppLocalizations.of(context)!.csvExportWeight),
              subtitle: Text(AppLocalizations.of(context)!.csvExportWeightDesc),
              onTap: () => _exportCSV(context, _CSVType.weight),
            ),
          ]),
          _Section(title: AppLocalizations.of(context)!.settingsImportSection, children: [
            ListTile(
              leading: const Icon(Icons.file_upload_outlined),
              title: Text(AppLocalizations.of(context)!.settingsImport),
              subtitle: Text(AppLocalizations.of(context)!.settingsImportRestore),
              onTap: () => _importJSON(context),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: Text(AppLocalizations.of(context)!.csvImportFinance),
              subtitle: Text(AppLocalizations.of(context)!.csvImportFinanceDesc),
              onTap: () => _importCSV(context, _CSVType.finance),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: Text(AppLocalizations.of(context)!.csvImportIntimacy),
              subtitle: Text(AppLocalizations.of(context)!.csvImportIntimacyDesc),
              onTap: () => _importCSV(context, _CSVType.intimacy),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: Text(AppLocalizations.of(context)!.csvImportWeight),
              subtitle: Text(AppLocalizations.of(context)!.csvImportWeightDesc),
              onTap: () => _importCSV(context, _CSVType.weight),
            ),
          ]),
          _Section(title: AppLocalizations.of(context)!.csvTemplate, children: [
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(AppLocalizations.of(context)!.csvTemplateFinance),
              trailing: const Icon(Icons.download),
              onTap: () => _saveTemplate(context, 'template_finance.csv'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(AppLocalizations.of(context)!.csvTemplateIntimacy),
              trailing: const Icon(Icons.download),
              onTap: () => _saveTemplate(context, 'template_intimacy.csv'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(AppLocalizations.of(context)!.csvTemplateWeight),
              trailing: const Icon(Icons.download),
              onTap: () => _saveTemplate(context, 'template_weight.csv'),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _exportJSON(BuildContext context) async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose export location',
    );
    if (dir == null) return;
    final path = await ImportExportService.exportZIP(dir);
    if (!context.mounted) return;
    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.settingsExportSuccess)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.settingsExportFailed)),
      );
    }
  }

  Future<void> _exportCSV(BuildContext context, _CSVType type) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(switch (type) {
            _CSVType.finance => l10n.csvExportFinance,
            _CSVType.intimacy => l10n.csvExportIntimacy,
            _CSVType.weight => l10n.csvExportWeight,
          }),
        content: Text(l10n.settingsExportCSVWarning),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.settingsExportSection)),
        ],
      ),
    );
    if (confirm != true) return;

    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose export location',
    );
    if (dir == null) return;
    final path = switch (type) {
      _CSVType.finance => await ImportExportService.exportCSV(dir),
      _CSVType.intimacy => await ImportExportService.exportIntimacyCSV(dir),
      _CSVType.weight => await ImportExportService.exportWeightCSV(dir),
    };
    if (!context.mounted) return;
    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsExportSuccess)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsExportFailed)),
      );
    }
  }

  Future<void> _importJSON(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.settingsImportData),
        content: Text(
            AppLocalizations.of(context)!.settingsImportConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(context)!.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLocalizations.of(context)!.settingsImportSection)),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choose backup file',
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    final ok = await ImportExportService.importZIP(filePath);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? AppLocalizations.of(context)!.settingsImportSuccess : AppLocalizations.of(context)!.settingsImportFailed),
      ),
    );
  }

  Future<void> _importCSV(BuildContext context, _CSVType type) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(switch (type) {
            _CSVType.finance => l10n.csvImportFinance,
            _CSVType.intimacy => l10n.csvImportIntimacy,
            _CSVType.weight => l10n.csvImportWeight,
          }),
        content: Text(l10n.csvImportConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.settingsImportSection)),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choose CSV file',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    final (ok, count) = switch (type) {
      _CSVType.finance => await ImportExportService.importFinanceCSV(filePath),
      _CSVType.intimacy => await ImportExportService.importIntimacyCSV(filePath),
      _CSVType.weight => await ImportExportService.importWeightCSV(filePath),
    };

    if (ok && count > 0) {
      AutoSyncService.instance.notifySaved();
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !ok
              ? l10n.csvImportFailed
              : count == 0
                  ? l10n.csvImportEmpty
                  : l10n.csvImportSuccess(count),
        ),
      ),
    );
  }

  Future<void> _saveTemplate(BuildContext context, String assetName) async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Save template to',
    );
    if (dir == null) return;

    final bytes = await rootBundle.load('assets/$assetName');
    final outFile = File(p.join(dir, assetName));
    await outFile.writeAsBytes(bytes.buffer.asUint8List());

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.csvTemplateSaved),
      ),
    );
  }
}

enum _CSVType { finance, intimacy, weight }

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  )),
        ),
        ...children,
      ],
    );
  }
}
