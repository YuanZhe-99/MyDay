import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_settings.dart';
import '../../../shared/providers/intimacy_visibility.dart';
import '../../../shared/services/tray_service.dart';
import '../../../shared/services/webdav_service.dart';
import '../../../shared/views/backup_page.dart';
import '../../../shared/views/import_export_page.dart';
import '../../../shared/views/webdav_config_page.dart';
import '../../finance/services/subscription_processor.dart';
import '../../todo/services/todo_storage.dart';
import 'license_page.dart' as app_license;
import 'privacy_policy_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _storagePath = '';
  String _appVersion = '';
  bool _minimizeToTray = false;
  bool _closeToTray = false;
  bool _webdavConfigured = false;

  bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  void initState() {
    super.initState();
    _loadStoragePath();
    _loadVersion();
    _loadWebDAVStatus();
    if (_isDesktop) _loadTraySettings();
  }

  Future<void> _loadTraySettings() async {
    final tray = TrayService.instance;
    if (mounted) {
      setState(() {
        _minimizeToTray = tray.minimizeToTray;
        _closeToTray = tray.closeToTray;
      });
    }
  }

  Future<void> _loadStoragePath() async {
    final path = await TodoStorage.getStoragePath();
    if (mounted) setState(() => _storagePath = path);
  }

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

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = 'v${info.version}');
  }

  Future<void> _loadWebDAVStatus() async {
    final config = await WebDAVService.loadConfig();
    if (mounted) {
      setState(() => _webdavConfigured = config?.isConfigured ?? false);
    }
  }

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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
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
              subtitle: Text(visibility.visible ? l10n.intimacyModuleVisible : l10n.intimacyModuleHidden),
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
                ref
                    .read(intimacyVisibilityProvider.notifier)
                    .setVisible(value);
              },
            ),
          ]),

          // Desktop-only section: tray settings + storage location
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
              subtitle: Text(_webdavConfigured ? l10n.settingsWebDAVConfigured : l10n.settingsWebDAVNotConfigured),
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
              leading: const Icon(Icons.import_export),
              title: Text(l10n.settingsImportExport),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImportExportPage()),
              ),
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
                    builder: (_) => const app_license.LicensePage()),
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
                      ? DateFormat('yyyy-MM-dd').format(SubscriptionProcessor.debugNowOverride!)
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
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: SubscriptionProcessor.debugNowOverride ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
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

  Widget _buildSection(
      BuildContext context, String title, List<Widget> children) {
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

  Future<void> _showStoragePathDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _storagePath);

    final newPath = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
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
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ''),
            child: Text(l10n.settingsResetDefault),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );

    if (newPath == null) return; // cancelled
    final pathToSet = newPath.isEmpty ? null : newPath;
    final ok = await TodoStorage.setStoragePath(pathToSet);
    if (ok) {
      await _loadStoragePath();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pathToSet == null ? l10n.settingsResetDefaultLocation : l10n.settingsStoragePathUpdated)),
        );
      }
    }
  }

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
                ThemeMode.system: (l10n.settingsThemeSystem, Icons.brightness_auto),
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
