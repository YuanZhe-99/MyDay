import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../l10n/app_localizations.dart';
import '../services/auto_sync_service.dart';
import '../services/import_export_service.dart';

class ImportExportPage extends StatelessWidget {
  /// Purpose: Create an import export page instance.
  /// Inputs: None.
  /// Returns: A new `ImportExportPage` instance.
  /// Side effects: None.
  /// Notes: None.
  const ImportExportPage({super.key});

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsImportExport),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _Section(
            title: AppLocalizations.of(context)!.settingsExportSection,
            children: [
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: Text(AppLocalizations.of(context)!.settingsExportJSON),
                subtitle: Text(
                  AppLocalizations.of(context)!.settingsExportJSONPlaintext,
                ),
                onTap: () => _exportJSON(context),
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: Text(AppLocalizations.of(context)!.csvExportFinance),
                subtitle: Text(
                  AppLocalizations.of(context)!.csvExportFinanceDesc,
                ),
                onTap: () => _exportCSV(context, _CSVType.finance),
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: Text(AppLocalizations.of(context)!.csvExportIntimacy),
                subtitle: Text(
                  AppLocalizations.of(context)!.csvExportIntimacyDesc,
                ),
                onTap: () => _exportCSV(context, _CSVType.intimacy),
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: Text(AppLocalizations.of(context)!.csvExportWeight),
                subtitle: Text(
                  AppLocalizations.of(context)!.csvExportWeightDesc,
                ),
                onTap: () => _exportCSV(context, _CSVType.weight),
              ),
            ],
          ),
          _Section(
            title: AppLocalizations.of(context)!.settingsImportSection,
            children: [
              ListTile(
                leading: const Icon(Icons.file_upload_outlined),
                title: Text(AppLocalizations.of(context)!.settingsImport),
                subtitle: Text(
                  AppLocalizations.of(context)!.settingsImportRestore,
                ),
                onTap: () => _importJSON(context),
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: Text(AppLocalizations.of(context)!.csvImportFinance),
                subtitle: Text(
                  AppLocalizations.of(context)!.csvImportFinanceDesc,
                ),
                onTap: () => _importCSV(context, _CSVType.finance),
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: Text(AppLocalizations.of(context)!.csvImportIntimacy),
                subtitle: Text(
                  AppLocalizations.of(context)!.csvImportIntimacyDesc,
                ),
                onTap: () => _importCSV(context, _CSVType.intimacy),
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: Text(AppLocalizations.of(context)!.csvImportWeight),
                subtitle: Text(
                  AppLocalizations.of(context)!.csvImportWeightDesc,
                ),
                onTap: () => _importCSV(context, _CSVType.weight),
              ),
            ],
          ),
          _Section(
            title: AppLocalizations.of(context)!.csvTemplate,
            children: [
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
            ],
          ),
        ],
      ),
    );
  }

  /// Purpose: Provide the internal export json helper for this file.
  /// Inputs: `context`.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _exportJSON(BuildContext context) async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: AppLocalizations.of(context)!.filePickerExportLocation,
    );
    if (dir == null) return;
    final path = await ImportExportService.exportZIP(dir);
    if (!context.mounted) return;
    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.settingsExportSuccess),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.settingsExportFailed),
        ),
      );
    }
  }

  /// Purpose: Provide the internal export csv helper for this file.
  /// Inputs: `context`, `type`.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _exportCSV(BuildContext context, _CSVType type) async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
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
            onPressed: () => navigator.pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => navigator.pop(true),
            child: Text(l10n.settingsExportSection),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: l10n.filePickerExportLocation,
    );
    if (dir == null) return;
    final path = switch (type) {
      _CSVType.finance => await ImportExportService.exportCSV(dir),
      _CSVType.intimacy => await ImportExportService.exportIntimacyCSV(dir),
      _CSVType.weight => await ImportExportService.exportWeightCSV(dir),
    };
    if (!context.mounted) return;
    if (path != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsExportSuccess)),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsExportFailed)),
      );
    }
  }

  /// Purpose: Provide the internal import json helper for this file.
  /// Inputs: `context`.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Accepts ZIP archives, single known data JSON files, and JSON backup bundles.
  Future<void> _importJSON(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsImportData),
        content: Text(l10n.settingsImportConfirm),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => navigator.pop(true),
            child: Text(l10n.settingsImportSection),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await FilePicker.platform.pickFiles(
      dialogTitle: l10n.filePickerBackupFile,
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    final ext = p.extension(filePath).toLowerCase();
    if (ext != '.zip' && ext != '.json') {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsImportUnsupportedType)),
      );
      return;
    }

    final importResult = await ImportExportService.importFile(filePath);
    if (!context.mounted) return;
    if (!importResult.success) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.settingsImportFailed),
          content: SingleChildScrollView(
            child: SelectableText(importResult.error ?? '-'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.commonOk),
            ),
          ],
        ),
      );
      return;
    }

    AutoSyncService.instance.notifySaved();
    messenger.showSnackBar(SnackBar(content: Text(l10n.settingsImportSuccess)));
  }

  /// Purpose: Provide the internal import csv helper for this file.
  /// Inputs: `context`, `type`.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _importCSV(BuildContext context, _CSVType type) async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
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
            onPressed: () => navigator.pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => navigator.pop(true),
            child: Text(l10n.settingsImportSection),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await FilePicker.platform.pickFiles(
      dialogTitle: l10n.filePickerCsvFile,
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    final ext = p.extension(filePath).toLowerCase();
    if (ext != '.csv') {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsImportUnsupportedType)),
      );
      return;
    }

    final (ok, count) = switch (type) {
      _CSVType.finance => await ImportExportService.importFinanceCSV(filePath),
      _CSVType.intimacy => await ImportExportService.importIntimacyCSV(
        filePath,
      ),
      _CSVType.weight => await ImportExportService.importWeightCSV(filePath),
    };

    if (ok && count > 0) {
      AutoSyncService.instance.notifySaved();
    }

    if (!context.mounted) return;
    messenger.showSnackBar(
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

  /// Purpose: Provide the internal save template helper for this file.
  /// Inputs: `context`, `assetName`.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _saveTemplate(BuildContext context, String assetName) async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: AppLocalizations.of(context)!.filePickerSaveTemplate,
    );
    if (dir == null) return;

    final bytes = await rootBundle.load('assets/$assetName');
    final outFile = File(p.join(dir, assetName));
    await outFile.writeAsBytes(bytes.buffer.asUint8List());

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.csvTemplateSaved)),
    );
  }
}

enum _CSVType { finance, intimacy, weight }

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  /// Purpose: Create a section instance.
  /// Inputs: `children`.
  /// Returns: A new `_Section` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _Section({required this.title, required this.children});

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}
