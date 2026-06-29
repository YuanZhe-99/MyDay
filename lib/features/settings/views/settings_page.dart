import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_settings.dart';
import '../../../shared/providers/intimacy_visibility.dart';
import '../../../shared/services/auto_sync_service.dart';
import '../../../shared/services/import_export_service.dart';
import '../../../shared/services/local_api_server.dart';
import '../../../shared/services/tray_service.dart';
import '../../../shared/services/webdav_service.dart';
import '../../../shared/utils/week_grouping.dart';
import '../../../shared/widgets/app_date_picker.dart';
import '../../../shared/widgets/unsaved_changes_guard.dart';
import '../../../shared/views/backup_page.dart';
import '../../../shared/views/webdav_config_page.dart';
import '../../finance/services/subscription_processor.dart';
import '../../todo/services/todo_storage.dart';
import 'license_page.dart' as app_license;
import 'privacy_policy_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  /// Purpose: Create a settings page instance.
  /// Inputs: None.
  /// Returns: A new `SettingsPage` instance.
  /// Side effects: None.
  /// Notes: None.
  const SettingsPage({super.key});

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _storagePath = '';
  String _appVersion = '';
  bool _minimizeToTray = false;
  bool _closeToTray = false;
  bool _autoStart = false;
  bool _webdavConfigured = false;
  // API server settings
  bool _apiEnabled = false;
  int _apiPort = 7790;
  String _apiListenAddress = 'localhost';
  String _apiUsername = '';
  String _apiPassword = '';

  /// Purpose: Return is desktop.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  /// Purpose: Initialize listeners, controllers, and first-load work for this state object.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Registers listeners and may kick off asynchronous loading.
  /// Notes: Guard any post-await UI updates with `mounted` when needed.
  @override
  void initState() {
    super.initState();
    _loadStoragePath();
    _loadVersion();
    _loadWebDAVStatus();
    AutoSyncService.instance.addOnStatusChanged(_refreshSyncStatus);
    if (_isDesktop) {
      _loadTraySettings();
      _loadAutoStartStatus();
      _loadApiSettings();
    }
  }

  /// Purpose: Release listeners, controllers, and other owned resources.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Releases the WebDAV status listener.
  /// Notes: Call the superclass implementation in the expected lifecycle order.
  @override
  void dispose() {
    AutoSyncService.instance.removeOnStatusChanged(_refreshSyncStatus);
    super.dispose();
  }

  /// Purpose: Refresh settings when sync status changes.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Triggers a rebuild.
  /// Notes: Internal helper used within this file only.
  void _refreshSyncStatus() {
    if (mounted) setState(() {});
  }

  /// Purpose: Provide the internal load tray settings helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _loadTraySettings() async {
    final tray = TrayService.instance;
    if (mounted) {
      setState(() {
        _minimizeToTray = tray.minimizeToTray;
        _closeToTray = tray.closeToTray;
      });
    }
  }

  /// Purpose: Provide the internal load storage path helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _loadStoragePath() async {
    final path = await TodoStorage.getStoragePath();
    if (mounted) setState(() => _storagePath = path);
  }

  /// Purpose: Provide the internal open data folder helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _openDataFolder() async {
    final appDir = await TodoStorage.getAppDir();
    if (Platform.isWindows) {
      await Process.run('explorer', [appDir.path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [appDir.path]);
    } else if (Platform.isLinux) {
      final uri = Uri.directory(appDir.path);
      await Process.run('xdg-open', [uri.toFilePath()]);
    }
  }

  /// Purpose: Provide the internal load version helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = 'v${info.version}');
  }

  /// Purpose: Provide the internal load web dav status helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _loadWebDAVStatus() async {
    final config = await WebDAVService.loadConfig();
    if (mounted) {
      setState(() => _webdavConfigured = config?.isConfigured ?? false);
    }
  }

  /// Purpose: Provide the internal load auto start status helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _loadAutoStartStatus() async {
    final enabled = await launchAtStartup.isEnabled();
    if (mounted) setState(() => _autoStart = enabled);
  }

  /// Purpose: Provide the internal load api settings helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _loadApiSettings() async {
    final config = await TodoStorage.readConfig();
    if (!mounted) return;
    setState(() {
      _apiEnabled = config['apiEnabled'] as bool? ?? false;
      _apiPort = config['apiPort'] as int? ?? 7790;
      _apiListenAddress = config['apiListenAddress'] as String? ?? 'localhost';
      _apiUsername = config['apiUsername'] as String? ?? '';
      _apiPassword = config['apiPassword'] as String? ?? '';
    });
  }

  /// Purpose: Export all app data as a ZIP file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: Opens a directory picker, writes a ZIP, and shows a snackbar.
  /// Notes: Settings import/export intentionally supports ZIP only.
  Future<void> _exportData() async {
    final l10n = AppLocalizations.of(context)!;
    final dir = await FilePicker.platform.getDirectoryPath();
    if (dir == null || !mounted) return;

    final path = await ImportExportService.exportZIP(dir);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          path != null ? l10n.settingsExportSuccess : l10n.settingsExportFailed,
        ),
      ),
    );
  }

  /// Purpose: Import all app data from a ZIP file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: Opens a file picker, may overwrite app data, and shows a snackbar.
  /// Notes: Settings import/export intentionally supports ZIP only.
  Future<void> _importData() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (result == null || result.files.single.path == null || !mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsImportData),
        content: Text(l10n.settingsImportConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.settingsImportData),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final success = await ImportExportService.importZIP(
      result.files.single.path!,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? l10n.settingsImportSuccess : l10n.settingsImportFailed,
        ),
      ),
    );
  }

  /// Purpose: Provide the internal show api settings dialog helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _showApiSettingsDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final portCtrl = TextEditingController(text: _apiPort.toString());
    final addrCtrl = TextEditingController(text: _apiListenAddress);
    final userCtrl = TextEditingController(text: _apiUsername);
    final passCtrl = TextEditingController(text: _apiPassword);

    /// Purpose: Return the current API settings form signature.
    /// Inputs: None.
    /// Returns: `String`.
    /// Side effects: None.
    /// Notes: Internal helper used within this function only.
    String signature() => formSignature([
      addrCtrl.text.trim(),
      portCtrl.text.trim(),
      userCtrl.text.trim(),
      passCtrl.text.trim(),
    ]);
    final initialSignature = signature();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => UnsavedChangesGuard(
        hasUnsavedChanges: () => signature() != initialSignature,
        builder: (ctx, guard) => AlertDialog(
          title: Text(l10n.settingsApiServer),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: addrCtrl,
                decoration: InputDecoration(
                  labelText: l10n.settingsApiListenAddress,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: portCtrl,
                decoration: InputDecoration(labelText: l10n.settingsApiPort),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: userCtrl,
                decoration: InputDecoration(
                  labelText: l10n.settingsApiUsername,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passCtrl,
                decoration: InputDecoration(
                  labelText: l10n.settingsApiPassword,
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => guard.maybeDiscardAndPop<bool>(),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => guard.pop(true),
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !mounted) return;

    final newPort = int.tryParse(portCtrl.text.trim()) ?? 7790;
    final newAddr = addrCtrl.text.trim().isEmpty
        ? 'localhost'
        : addrCtrl.text.trim();
    final newUser = userCtrl.text.trim();
    final newPass = passCtrl.text.trim();
    await TodoStorage.writeConfig({
      'apiPort': newPort,
      'apiListenAddress': newAddr,
      'apiUsername': newUser.isEmpty ? null : newUser,
      'apiPassword': newPass.isEmpty ? null : newPass,
    });
    setState(() {
      _apiPort = newPort;
      _apiListenAddress = newAddr;
      _apiUsername = newUser;
      _apiPassword = newPass;
    });
    await LocalApiServer.restart();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsApiRestarted(LocalApiServer.port))),
      );
    }
  }

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final visibility = ref.watch(intimacyVisibilityProvider);
    final settings = ref.watch(appSettingsProvider);
    final l10n = AppLocalizations.of(context)!;

    final themeModeLabel = switch (settings.themeMode) {
      ThemeMode.system => l10n.settingsThemeSystem,
      ThemeMode.light => l10n.settingsThemeLight,
      ThemeMode.dark => l10n.settingsThemeDark,
    };

    final localeTag = settings.locale != null
        ? '${settings.locale!.languageCode}${settings.locale!.countryCode != null ? '_${settings.locale!.countryCode}' : ''}'
        : null;
    final localeLabel = switch (localeTag) {
      'en' => 'English',
      'zh' => '简体中文',
      'zh_TW' => '繁體中文',
      'ja' => '日本語',
      _ => l10n.settingsThemeSystem,
    };
    final weekStartLabel = localizedWeekdayLabel(
      settings.weekStartDay,
      l10n.localeName,
      width: WeekdayLabelWidth.long,
    );
    final syncError = AutoSyncService.instance.lastError;
    final syncSubtitle = syncError != null
        ? AutoSyncService.instance.hasPendingConflicts
              ? '${l10n.settingsWebDAVAutoSyncConflict}: $syncError'
              : '${l10n.settingsWebDAVAutoSyncFailed}: $syncError'
        : _webdavConfigured
        ? l10n.settingsWebDAVConfigured
        : l10n.settingsWebDAVNotConfigured;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _buildSection(context, l10n.settingsGeneral, [
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.settingsLanguage),
              subtitle: Text(localeLabel),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguagePicker(context, settings),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_view_week_outlined),
              title: Text(l10n.settingsWeekStartDay),
              subtitle: Text(weekStartLabel),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showWeekStartPicker(context, settings),
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: Text(l10n.settingsTheme),
              subtitle: Text(themeModeLabel),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showThemePicker(context, settings),
            ),
          ]),

          _buildSection(context, l10n.settingsPrivacy, [
            SwitchListTile(
              secondary: const Icon(Icons.favorite_border),
              title: Text(l10n.settingsIntimacyModule),
              subtitle: Text(
                visibility.visible
                    ? l10n.intimacyModuleVisible
                    : l10n.intimacyModuleHidden,
              ),
              value: visibility.visible,
              onChanged: (value) async {
                if (!value) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.settingsIntimacyModule),
                      content: Text(l10n.intimacyHideConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(l10n.commonCancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(l10n.commonConfirm),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                }
                ref.read(intimacyVisibilityProvider.notifier).setVisible(value);
              },
            ),
          ]),

          // Desktop-only section: tray settings + storage location + API
          if (_isDesktop)
            _buildSection(context, l10n.settingsDesktop, [
              SwitchListTile(
                secondary: const Icon(Icons.minimize),
                title: Text(l10n.settingsMinimizeToTray),
                value: _minimizeToTray,
                onChanged: (value) async {
                  await TrayService.instance.setMinimizeToTray(value);
                  setState(() => _minimizeToTray = value);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.close),
                title: Text(l10n.settingsCloseToTray),
                value: _closeToTray,
                onChanged: (value) async {
                  await TrayService.instance.setCloseToTray(value);
                  setState(() => _closeToTray = value);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.login_outlined),
                title: Text(l10n.settingsAutoStart),
                value: _autoStart,
                onChanged: (v) async {
                  if (v) {
                    await launchAtStartup.enable();
                  } else {
                    await launchAtStartup.disable();
                  }
                  setState(() => _autoStart = v);
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                secondary: const Icon(Icons.dns_outlined),
                title: Text(l10n.settingsApiEnabled),
                subtitle: Text(
                  LocalApiServer.isRunning
                      ? l10n.settingsApiRunning(LocalApiServer.port)
                      : LocalApiServer.lastError == 'credentials_required'
                      ? l10n.settingsApiNeedCredentials
                      : LocalApiServer.lastError != null
                      ? '${l10n.settingsApiStopped} (${LocalApiServer.lastError})'
                      : l10n.settingsApiStopped,
                  style:
                      !LocalApiServer.isRunning &&
                          LocalApiServer.lastError != null
                      ? TextStyle(color: Theme.of(context).colorScheme.error)
                      : null,
                ),
                value: _apiEnabled,
                onChanged: (v) async {
                  await TodoStorage.writeConfig({'apiEnabled': v});
                  setState(() => _apiEnabled = v);
                  if (v) {
                    await LocalApiServer.start();
                  } else {
                    await LocalApiServer.stop();
                  }
                  if (mounted) setState(() {});
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text(l10n.settingsApiServer),
                trailing: const Icon(Icons.chevron_right),
                enabled: _apiEnabled,
                onTap: _apiEnabled ? _showApiSettingsDialog : null,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(l10n.settingsStorageLocation),
                subtitle: Text(
                  _storagePath,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showStoragePathDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.folder_open_outlined),
                title: Text(l10n.settingsOpenDataFolder),
                subtitle: Text(l10n.settingsOpenDataFolderDesc),
                onTap: _openDataFolder,
              ),
            ]),

          _buildSection(context, l10n.settingsData, [
            ListTile(
              leading: const Icon(Icons.sync),
              title: Text(l10n.settingsWebDAVSync),
              subtitle: Text(syncSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WebDAVConfigPage()),
                );
                _loadWebDAVStatus();
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: Text(l10n.settingsExportJSON),
              onTap: _exportData,
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: Text(l10n.settingsImportData),
              onTap: _importData,
            ),
            ListTile(
              leading: const Icon(Icons.backup),
              title: Text(l10n.backupTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BackupPage()),
              ),
            ),
          ]),

          _buildSection(context, l10n.settingsAbout, [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.settingsAboutTitle),
            ),
            ListTile(
              leading: const Icon(Icons.tag),
              title: Text(_appVersion.isNotEmpty ? _appVersion : '...'),
            ),
            ListTile(
              leading: const Icon(Icons.gavel_outlined),
              title: Text(l10n.settingsLicense),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const app_license.LicensePage(),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.settingsLicenses),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'MyDay',
                applicationVersion: _appVersion,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(l10n.settingsPrivacyPolicy),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              ),
            ),
          ]),

          if (kDebugMode)
            _buildSection(context, 'Debug', [
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Date Override'),
                subtitle: Text(
                  SubscriptionProcessor.debugNowOverride != null
                      ? DateFormat(
                          'yyyy-MM-dd',
                        ).format(SubscriptionProcessor.debugNowOverride!)
                      : 'Using system date',
                ),
                trailing: SubscriptionProcessor.debugNowOverride != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          SubscriptionProcessor.debugNowOverride = null;
                        }),
                      )
                    : null,
                onTap: () async {
                  final picked = await showAppDatePicker(
                    context: context,
                    initialDate:
                        SubscriptionProcessor.debugNowOverride ??
                        DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    title: 'Date Override',
                  );
                  if (picked != null) {
                    setState(() {
                      SubscriptionProcessor.debugNowOverride = picked;
                    });
                  }
                },
              ),
            ]),
        ],
      ),
    );
  }

  /// Purpose: Provide the internal build section helper for this file.
  /// Inputs: `context`, `title`, `children`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
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

  /// Purpose: Provide the internal show storage path dialog helper for this file.
  /// Inputs: `context`.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _showStoragePathDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _storagePath);
    final initialPath = controller.text.trim();

    final newPath = await showDialog<String?>(
      context: context,
      builder: (ctx) => UnsavedChangesGuard(
        hasUnsavedChanges: () => controller.text.trim() != initialPath,
        builder: (ctx, guard) => AlertDialog(
          title: Text(l10n.settingsStorageLocation),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.settingsStoragePathHint),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.settingsDirectoryPath,
                  hintText: 'C:\\Users\\...\\MyDay',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => guard.maybeDiscardAndPop<String?>(),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => guard.pop(''),
              child: Text(l10n.settingsResetDefault),
            ),
            FilledButton(
              onPressed: () => guard.pop(controller.text.trim()),
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );

    if (newPath == null) return; // cancelled
    final pathToSet = newPath.isEmpty ? null : newPath;
    final ok = await TodoStorage.setStoragePath(pathToSet);
    if (ok) {
      await _loadStoragePath();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pathToSet == null
                  ? l10n.settingsResetDefaultLocation
                  : l10n.settingsStoragePathUpdated,
            ),
          ),
        );
      }
    }
  }

  /// Purpose: Provide the internal show theme picker helper for this file.
  /// Inputs: `context`, `settings`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _showThemePicker(BuildContext context, AppSettings settings) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: RadioGroup<ThemeMode>(
          groupValue: settings.themeMode,
          onChanged: (mode) {
            if (mode != null) {
              ref.read(appSettingsProvider.notifier).setThemeMode(mode);
            }
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in {
                ThemeMode.system: (
                  l10n.settingsThemeSystem,
                  Icons.brightness_auto,
                ),
                ThemeMode.light: (l10n.settingsThemeLight, Icons.light_mode),
                ThemeMode.dark: (l10n.settingsThemeDark, Icons.dark_mode),
              }.entries)
                ListTile(
                  leading: Icon(entry.value.$2),
                  title: Text(entry.value.$1),
                  trailing: Radio<ThemeMode>(value: entry.key),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Purpose: Show the global week-start picker.
  /// Inputs: `context`, `settings`.
  /// Returns: None.
  /// Side effects: Updates app settings and persists the selected weekday.
  /// Notes: Weekday values use Dart's Monday=1 through Sunday=7 numbering.
  void _showWeekStartPicker(BuildContext context, AppSettings settings) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: RadioGroup<int>(
          groupValue: settings.weekStartDay,
          onChanged: (weekday) {
            if (weekday != null) {
              ref.read(appSettingsProvider.notifier).setWeekStartDay(weekday);
            }
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_view_week_outlined),
                title: Text(l10n.settingsWeekStartDay),
              ),
              const Divider(height: 1),
              for (final weekday in weekdaySequence(DateTime.monday))
                ListTile(
                  title: Text(
                    localizedWeekdayLabel(
                      weekday,
                      l10n.localeName,
                      width: WeekdayLabelWidth.long,
                    ),
                  ),
                  trailing: Radio<int>(value: weekday),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Purpose: Provide the internal show language picker helper for this file.
  /// Inputs: `context`, `settings`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _showLanguagePicker(BuildContext context, AppSettings settings) {
    final l10n = AppLocalizations.of(context)!;
    final currentTag = settings.locale != null
        ? '${settings.locale!.languageCode}${settings.locale!.countryCode != null ? '_${settings.locale!.countryCode}' : ''}'
        : 'system';
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: RadioGroup<String>(
          groupValue: currentTag,
          onChanged: (code) {
            Locale? locale;
            if (code == 'zh_TW') {
              locale = const Locale('zh', 'TW');
            } else if (code != null && code != 'system') {
              locale = Locale(code);
            }
            ref.read(appSettingsProvider.notifier).setLocale(locale);
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.settingsThemeSystem),
                trailing: Radio<String>(value: 'system'),
              ),
              ListTile(
                title: const Text('English'),
                trailing: Radio<String>(value: 'en'),
              ),
              ListTile(
                title: const Text('简体中文'),
                trailing: Radio<String>(value: 'zh'),
              ),
              ListTile(
                title: const Text('繁體中文'),
                trailing: Radio<String>(value: 'zh_TW'),
              ),
              ListTile(
                title: const Text('日本語'),
                trailing: Radio<String>(value: 'ja'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
