import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../services/auto_sync_service.dart';
import '../services/sync_progress.dart';
import '../services/sync_wake_lock.dart';
import '../services/webdav_service.dart';
import '../widgets/sync_conflict_dialog.dart';

class WebDAVConfigPage extends StatefulWidget {
  /// Purpose: Create a webdav config page instance.
  /// Inputs: None.
  /// Returns: A new `WebDAVConfigPage` instance.
  /// Side effects: None.
  /// Notes: None.
  const WebDAVConfigPage({super.key});

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  State<WebDAVConfigPage> createState() => _WebDAVConfigPageState();
}

class _WebDAVConfigPageState extends State<WebDAVConfigPage> {
  final _urlController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _pathController = TextEditingController(text: '/MyDay');
  bool _loading = true;
  bool _testing = false;
  bool _syncing = false;
  bool _isConfigured = false;
  bool _autoSync = false;

  /// Purpose: Initialize listeners, controllers, and first-load work for this state object.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Registers listeners and may kick off asynchronous loading.
  /// Notes: Guard any post-await UI updates with `mounted` when needed.
  @override
  void initState() {
    super.initState();
    AutoSyncService.instance.addOnStatusChanged(_refreshSyncStatus);
    _loadConfig();
  }

  /// Purpose: Refresh this page when background sync status changes.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Triggers a rebuild.
  /// Notes: Internal helper used within this file only.
  void _refreshSyncStatus() {
    if (mounted) setState(() {});
  }

  /// Purpose: Provide the internal load config helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _loadConfig() async {
    final config = await WebDAVService.loadConfig();
    if (config != null) {
      _urlController.text = config.serverUrl;
      _userController.text = config.username;
      _passController.text = config.password;
      _pathController.text = config.remotePath;
      _isConfigured = config.isConfigured;
      _autoSync = config.autoSync;
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Purpose: Release listeners, controllers, and other owned resources.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Releases owned resources and unregisters listeners.
  /// Notes: Call the superclass implementation in the expected lifecycle order.
  @override
  void dispose() {
    AutoSyncService.instance.removeOnStatusChanged(_refreshSyncStatus);
    _urlController.dispose();
    _userController.dispose();
    _passController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  /// Purpose: Return current config.
  /// Inputs: None.
  /// Returns: `WebDAVConfig`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  WebDAVConfig get _currentConfig => WebDAVConfig(
    serverUrl: _urlController.text.trim(),
    username: _userController.text.trim(),
    password: _passController.text.trim(),
    remotePath: _pathController.text.trim(),
    autoSync: _autoSync,
  );

  /// Purpose: Provide the internal save config helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only. Saving a fully
  /// configured auto-sync setup triggers an immediate background sync
  /// (aligned with MyAnime) so the first sync does not wait for a trigger.
  Future<void> _saveConfig() async {
    final config = _currentConfig;
    await WebDAVService.saveConfig(config);
    setState(() => _isConfigured = config.isConfigured);
    if (config.isConfigured && config.autoSync) {
      AutoSyncService.instance.requestSyncNow();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.settingsWebDAVConfigSaved,
          ),
        ),
      );
    }
  }

  /// Purpose: Provide the internal test connection helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _testConnection() async {
    setState(() => _testing = true);
    final ok = await WebDAVService.testConnection(_currentConfig);
    if (mounted) {
      setState(() => _testing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? AppLocalizations.of(context)!.settingsWebDAVConnectionSuccess
                : AppLocalizations.of(context)!.settingsWebDAVConnectionFailed,
          ),
        ),
      );
    }
  }

  /// Purpose: Provide the internal sync now helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows. Holds
  /// the sync wake lock while the sync request and any conflict finalize
  /// upload run.
  /// Notes: Internal helper used within this file only. The wake lock and
  /// the `_syncing` busy flag are both reset in `finally` around each network
  /// operation, and the lock is never held across the conflict dialog.
  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    await SyncWakeLock.acquire();
    SyncResult result;
    try {
      result = await WebDAVService.sync(_currentConfig);
    } finally {
      await SyncWakeLock.release();
      if (mounted) setState(() => _syncing = false);
    }
    if (!mounted) return;
    AutoSyncService.instance.recordSyncResult(result);
    AutoSyncService.instance.notifyLocalDataChangedIfNeeded();

    if (result.hasConflicts) {
      final resolutions = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            SyncConflictDialog(conflicts: result.pending!.allConflicts),
      );
      if (resolutions != null && mounted) {
        setState(() => _syncing = true);
        await SyncWakeLock.acquire();
        bool ok;
        try {
          ok = await WebDAVService.finalizePendingSync(
            _currentConfig,
            result.pending!,
            resolutions,
          );
        } finally {
          await SyncWakeLock.release();
          if (mounted) setState(() => _syncing = false);
        }
        AutoSyncService.instance.recordFinalizeResult(ok);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ok
                    ? AppLocalizations.of(context)!.settingsWebDAVSyncSuccess
                    : AppLocalizations.of(context)!.settingsWebDAVSyncFailed,
              ),
            ),
          );
        }
      } else {
        AutoSyncService.instance.recordSyncResult(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.settingsWebDAVSyncFailed,
              ),
            ),
          );
        }
      }
    } else {
      await _showSyncResult(result);
    }
  }

  /// Purpose: Present a non-conflict sync/force result to the user.
  /// Inputs: `result`.
  /// Returns: `Future<void>`.
  /// Side effects: Shows a dialog for failures/warnings or a snackbar on success.
  /// Notes: Internal helper used within this file only.
  Future<void> _showSyncResult(SyncResult result) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (!result.success) {
      await _showSyncDialog(l10n.settingsWebDAVSyncFailed, result.error ?? '-');
      return;
    }
    if (result.warnings.isNotEmpty) {
      await _showSyncDialog(
        l10n.settingsWebDAVSyncSuccess,
        '${l10n.settingsWebDAVSyncImageWarnings(result.warnings.length)}\n'
        '${result.warnings.join('\n')}',
      );
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.settingsWebDAVSyncSuccess)));
  }

  /// Purpose: Confirm and run a force upload (local overwrites remote).
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: Overwrites remote data after user confirmation. Holds the
  /// sync wake lock while the upload runs.
  /// Notes: Internal helper used within this file only. The wake lock is
  /// acquired only after the user confirms; it and the `_syncing` busy flag
  /// are both reset in `finally`.
  Future<void> _forceUpload() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirmForceAction(
      title: l10n.settingsWebDAVForceUploadConfirmTitle,
      body: l10n.settingsWebDAVForceUploadConfirmBody,
      confirmLabel: l10n.settingsWebDAVForceUpload,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _syncing = true);
    await SyncWakeLock.acquire();
    SyncResult result;
    try {
      result = await WebDAVService.forceUpload(_currentConfig);
    } finally {
      await SyncWakeLock.release();
      if (mounted) setState(() => _syncing = false);
    }
    if (!mounted) return;
    AutoSyncService.instance.recordSyncResult(result);
    AutoSyncService.instance.notifyLocalDataChangedIfNeeded();
    await _showSyncResult(result);
  }

  /// Purpose: Confirm and run a force download (remote overwrites local).
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: Overwrites local data after user confirmation. Holds the
  /// sync wake lock while the download runs.
  /// Notes: Internal helper used within this file only. The wake lock is
  /// acquired only after the user confirms; it and the `_syncing` busy flag
  /// are both reset in `finally`.
  Future<void> _forceDownload() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirmForceAction(
      title: l10n.settingsWebDAVForceDownloadConfirmTitle,
      body: l10n.settingsWebDAVForceDownloadConfirmBody,
      confirmLabel: l10n.settingsWebDAVForceDownload,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _syncing = true);
    await SyncWakeLock.acquire();
    SyncResult result;
    try {
      result = await WebDAVService.forceDownload(_currentConfig);
    } finally {
      await SyncWakeLock.release();
      if (mounted) setState(() => _syncing = false);
    }
    if (!mounted) return;
    AutoSyncService.instance.recordSyncResult(result);
    AutoSyncService.instance.notifyLocalDataChangedIfNeeded();
    await _showSyncResult(result);
  }

  /// Purpose: Ask the user to confirm a destructive force upload/download.
  /// Inputs: `title`, `body`, `confirmLabel`.
  /// Returns: `Future<bool?>` — true when confirmed.
  /// Side effects: Opens a modal dialog.
  /// Notes: Internal helper used within this file only.
  Future<bool?> _confirmForceAction({
    required String title,
    required String body,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(ctx)!.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  /// Purpose: Map a sync progress snapshot to a localized status line.
  /// Inputs: `l10n`, `progress`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  String _progressText(AppLocalizations l10n, SyncProgress progress) {
    switch (progress.phase) {
      case SyncPhase.connecting:
        return l10n.syncPhaseConnecting;
      case SyncPhase.downloadingData:
        return l10n.syncPhaseDownloadingData(
          progress.detail ?? '',
          progress.current,
          progress.total,
        );
      case SyncPhase.merging:
        return l10n.syncPhaseMerging(progress.detail ?? '');
      case SyncPhase.uploadingData:
        return l10n.syncPhaseUploadingData(progress.detail ?? '');
      case SyncPhase.uploadingImages:
        return l10n.syncPhaseUploadingImages(progress.current, progress.total);
      case SyncPhase.downloadingImages:
        return l10n.syncPhaseDownloadingImages(
          progress.current,
          progress.total,
        );
      case SyncPhase.idle:
      case SyncPhase.done:
      case SyncPhase.error:
        return '';
    }
  }

  /// Purpose: Show a detailed sync result dialog.
  /// Inputs: `title`, `message`.
  /// Returns: `Future<void>`.
  /// Side effects: Opens a modal dialog.
  /// Notes: Used for long sync errors that do not fit in snackbars.
  Future<void> _showSyncDialog(String title, String message) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: SelectableText(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.commonOk),
          ),
        ],
      ),
    );
  }

  /// Purpose: Build a short sync health summary for display.
  /// Inputs: None.
  /// Returns: `String?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  String? _syncStatusText() {
    final service = AutoSyncService.instance;
    if (service.lastError != null) {
      return service.hasPendingConflicts
          ? '${AppLocalizations.of(context)!.settingsWebDAVAutoSyncConflict}: ${service.lastError}'
          : '${AppLocalizations.of(context)!.settingsWebDAVAutoSyncFailed}: ${service.lastError}';
    }
    if (service.lastSuccessAt != null) {
      return '${AppLocalizations.of(context)!.settingsWebDAVLastSuccess}: ${service.lastSuccessAt!.toLocal()}';
    }
    return null;
  }

  /// Purpose: Provide the internal disconnect helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _disconnect() async {
    await WebDAVService.deleteConfig();
    _urlController.clear();
    _userController.clear();
    _passController.clear();
    _pathController.text = '/MyDay';
    setState(() {
      _isConfigured = false;
      _autoSync = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.settingsWebDAVConfigRemoved,
          ),
        ),
      );
    }
  }

  /// Purpose: Provide the internal fill nextcloud helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _fillNextcloud() {
    _urlController.text =
        'https://your-nextcloud-host/remote.php/dav/files/USERNAME';
    _pathController.text = '/MyDay';
    setState(() {});
  }

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsWebDAVSync),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Presets
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _fillNextcloud,
                      icon: const Icon(Icons.cloud, size: 18),
                      label: Text(
                        AppLocalizations.of(context)!.settingsWebDAVNextcloud,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Server URL
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    )!.settingsWebDAVServerURL,
                    hintText: 'https://example.com/remote.php/dav/files/user',
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),

                // Username
                TextField(
                  controller: _userController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    )!.settingsWebDAVUsername,
                  ),
                ),
                const SizedBox(height: 12),

                // Password
                TextField(
                  controller: _passController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    )!.settingsWebDAVPassword,
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),

                // Remote path
                TextField(
                  controller: _pathController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    )!.settingsWebDAVRemotePath,
                    hintText: '/MyDay',
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _saveConfig,
                        child: Text(AppLocalizations.of(context)!.commonSave),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _testing ? null : _testConnection,
                        child: _testing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                AppLocalizations.of(
                                  context,
                                )!.settingsWebDAVTestConnection,
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_isConfigured) ...[
                  if (_syncStatusText() != null) ...[
                    Card(
                      color: AutoSyncService.instance.lastError == null
                          ? theme.colorScheme.surfaceContainerHighest
                          : theme.colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _syncStatusText()!,
                          style: TextStyle(
                            color: AutoSyncService.instance.lastError == null
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ValueListenableBuilder<SyncProgress>(
                    valueListenable: WebDAVService.progress,
                    builder: (context, progress, _) {
                      if (!progress.isRunning) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(value: progress.fraction),
                          const SizedBox(height: 8),
                          Text(
                            _progressText(
                              AppLocalizations.of(context)!,
                              progress,
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
                  FilledButton.icon(
                    onPressed: _syncing ? null : _syncNow,
                    icon: _syncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: Text(
                      _syncing
                          ? AppLocalizations.of(context)!.settingsWebDAVSyncing
                          : AppLocalizations.of(context)!.settingsWebDAVSyncNow,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _syncing ? null : _forceUpload,
                          icon: const Icon(Icons.upload, size: 18),
                          label: Text(
                            AppLocalizations.of(
                              context,
                            )!.settingsWebDAVForceUpload,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _syncing ? null : _forceDownload,
                          icon: const Icon(Icons.download, size: 18),
                          label: Text(
                            AppLocalizations.of(
                              context,
                            )!.settingsWebDAVForceDownload,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      AppLocalizations.of(context)!.settingsWebDAVAutoSync,
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.settingsWebDAVAutoSyncDesc,
                    ),
                    value: _autoSync,
                    onChanged: (v) async {
                      setState(() => _autoSync = v);
                      final config = _currentConfig;
                      await WebDAVService.saveConfig(config);
                      if (v && config.isConfigured) {
                        AutoSyncService.instance.requestSyncNow();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _disconnect,
                    icon: const Icon(Icons.link_off),
                    label: Text(
                      AppLocalizations.of(context)!.settingsWebDAVDisconnect,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
