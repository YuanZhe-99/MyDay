import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../features/finance/services/balance_util.dart';
import '../../features/finance/services/exchange_rate_storage.dart';
import '../../features/finance/services/finance_storage.dart';
import '../../features/todo/services/todo_storage.dart';
import '../utils/json_preservation.dart';
import 'sync_merge.dart';

/// Persisted WebDAV configuration.
class WebDAVConfig {
  final String serverUrl;
  final String username;
  final String password;
  final String remotePath;
  final bool autoSync;

  /// Purpose: Create a web dav config instance.
  /// Inputs: `remotePath`.
  /// Returns: A new `WebDAVConfig` instance.
  /// Side effects: None.
  /// Notes: None.
  const WebDAVConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.remotePath = '/MyDay',
    this.autoSync = false,
  });

  /// Purpose: Return whether configured is true.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: None.
  bool get isConfigured =>
      serverUrl.isNotEmpty && username.isNotEmpty && password.isNotEmpty;

  /// Purpose: Create a copy of this value with selected fields replaced.
  /// Inputs: `autoSync`.
  /// Returns: `WebDAVConfig`.
  /// Side effects: None.
  /// Notes: None.
  WebDAVConfig copyWith({bool? autoSync}) => WebDAVConfig(
    serverUrl: serverUrl,
    username: username,
    password: password,
    remotePath: remotePath,
    autoSync: autoSync ?? this.autoSync,
  );

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    'serverUrl': serverUrl,
    'username': username,
    'password': password,
    'remotePath': remotePath,
    'autoSync': autoSync,
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `WebDAVConfig.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading the persisted or transferred data format for this type.
  factory WebDAVConfig.fromJson(Map<String, dynamic> json) => WebDAVConfig(
    serverUrl: json['serverUrl'] as String? ?? '',
    username: json['username'] as String? ?? '',
    password: json['password'] as String? ?? '',
    remotePath: json['remotePath'] as String? ?? '/MyDay',
    autoSync: json['autoSync'] as bool? ?? false,
  );

  /// Nextcloud preset fills server URL pattern.
  /// Purpose: Create a web dav config instance.
  /// Inputs: `host`, `username`, `password`.
  /// Returns: A new `WebDAVConfig.nextcloud` instance.
  /// Side effects: None.
  /// Notes: None.
  factory WebDAVConfig.nextcloud(
    String host,
    String username,
    String password,
  ) => WebDAVConfig(
    serverUrl: 'https://$host/remote.php/dav/files/$username',
    username: username,
    password: password,
  );
}

// ─── Sync result types ──────────────────────────────────────────────

/// Overall sync result.
class SyncResult {
  final bool success;
  final String? error;

  /// Non-null when there are per-record conflicts needing user resolution.
  final PendingSync? pending;

  /// Non-fatal warnings (e.g. individual image transfer failures).
  final List<String> warnings;

  /// Purpose: Create a sync result instance.
  /// Inputs: `warnings`.
  /// Returns: A new `SyncResult` instance.
  /// Side effects: None.
  /// Notes: None.
  const SyncResult({
    required this.success,
    this.error,
    this.pending,
    this.warnings = const [],
  });

  /// Purpose: Return whether conflicts is available.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: None.
  bool get hasConflicts => pending != null;
}

/// Holds pending merge results that contain per-record conflicts.
class PendingSync {
  final TodoMergeResult? todoMerge;
  final FinanceMergeResult? financeMerge;
  final IntimacyMergeResult? intimacyMerge;
  final WeightMergeResult? weightMerge;

  /// Purpose: Create a pending sync instance.
  /// Inputs: None.
  /// Returns: A new `PendingSync` instance.
  /// Side effects: None.
  /// Notes: None.
  const PendingSync({
    this.todoMerge,
    this.financeMerge,
    this.intimacyMerge,
    this.weightMerge,
  });

  /// Purpose: Return all conflicts.
  /// Inputs: None.
  /// Returns: `List<RecordConflict>`.
  /// Side effects: None.
  /// Notes: None.
  List<RecordConflict> get allConflicts => [
    ...?todoMerge?.dailyConflicts,
    ...?todoMerge?.onceConflicts,
    ...?financeMerge?.accountConflicts,
    ...?financeMerge?.categoryConflicts,
    ...?financeMerge?.transactionConflicts,
    ...?financeMerge?.subscriptionConflicts,
    ...?intimacyMerge?.partnerConflicts,
    ...?intimacyMerge?.toyConflicts,
    ...?intimacyMerge?.positionConflicts,
    ...?intimacyMerge?.recordConflicts,
    ...?weightMerge?.recordConflicts,
  ];
}

// ─── WebDAV Service ─────────────────────────────────────────────────

class WebDAVService {
  static const _configFileName = 'webdav_config.json';
  static const _syncBaseDirName = '.sync_base';
  static const _dataFileNames = [
    'todo_data.json',
    'finance_data.json',
    'exchange_rates.json',
    'intimacy_data.json',
    'weight_data.json',
  ];

  /// Global lock to prevent concurrent syncs (auto + manual).
  static bool _syncing = false;

  /// Set to true when sync writes merged data to local files.
  static bool _localDataChanged = false;

  /// Whether the last sync wrote local data files (reset after read).
  /// Purpose: Implement the consume local data changed behavior for this file.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: Resets the local-data-changed flag after reading it.
  /// Notes: None.
  static bool consumeLocalDataChanged() {
    final v = _localDataChanged;
    _localDataChanged = false;
    return v;
  }

  /// Purpose: Provide the internal migrate finance forced balances helper for this file.
  /// Inputs: `data`.
  /// Returns: `Future<FinanceData>`.
  /// Side effects: May read exchange-rate data needed to convert legacy transactions.
  /// Notes: Internal helper used within this file only.
  static Future<FinanceData> _migrateFinanceForcedBalances(
    FinanceData data,
  ) async {
    final rateData = await ExchangeRateStorage.load();
    final migration = migrateForcedBalances(
      accounts: data.accounts,
      transactions: data.transactions,
      rateData: rateData,
    );
    if (!migration.changed) return data;

    return FinanceData(
      accounts: migration.accounts,
      categories: data.categories,
      transactions: migration.transactions,
      subscriptions: data.subscriptions,
      defaultCurrency: data.defaultCurrency,
      settingsModifiedAt: data.settingsModifiedAt,
      subscriptionReminderHour: data.subscriptionReminderHour,
      subscriptionReminderMinute: data.subscriptionReminderMinute,
      subscriptionSortMode: data.subscriptionSortMode,
      subscriptionCustomOrder: data.subscriptionCustomOrder,
      accountSortModes: data.accountSortModes,
      accountCustomOrders: data.accountCustomOrders,
      accountPickerSettings: data.accountPickerSettings,
    );
  }

  // ── Config persistence ──

  /// Purpose: Load config into the current workflow or state.
  /// Inputs: None.
  /// Returns: `Future<WebDAVConfig?>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<WebDAVConfig?> loadConfig() async {
    try {
      final dir = await TodoStorage.getAppDir();
      final file = File('${dir.path}/$_configFileName');
      if (!await file.exists()) return null;
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return WebDAVConfig.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Purpose: Save config to the relevant storage or service layer.
  /// Inputs: `config`.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<void> saveConfig(WebDAVConfig config) async {
    final dir = await TodoStorage.getAppDir();
    final file = File('${dir.path}/$_configFileName');
    await file.writeAsString(jsonEncode(config.toJson()));
  }

  /// Purpose: Implement the delete config behavior for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<void> deleteConfig() async {
    final dir = await TodoStorage.getAppDir();
    final file = File('${dir.path}/$_configFileName');
    if (await file.exists()) await file.delete();
  }

  // ── Base (last-synced) file management ──

  /// Purpose: Provide the internal get base dir helper for this file.
  /// Inputs: None.
  /// Returns: `Future<Directory>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static Future<Directory> _getBaseDir() async {
    final appDir = await TodoStorage.getAppDir();
    final dir = Directory('${appDir.path}/$_syncBaseDirName');
    if (!await dir.exists()) await dir.create();
    return dir;
  }

  /// Purpose: Provide the internal read base helper for this file.
  /// Inputs: `fileName`.
  /// Returns: `Future<String?>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static Future<String?> _readBase(String fileName) async {
    try {
      final dir = await _getBaseDir();
      final file = File('${dir.path}/$fileName');
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  /// Purpose: Provide the internal save base helper for this file.
  /// Inputs: `fileName`, `jsonContent`.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static Future<void> _saveBase(String fileName, String jsonContent) async {
    final dir = await _getBaseDir();
    final file = File('${dir.path}/$fileName');
    await _atomicWrite(file, jsonContent);
  }

  // ── Atomic file write ──

  /// Write content to a temp file then atomically rename over the target.
  /// Prevents data corruption if the app is killed during write.
  /// Purpose: Provide the internal atomic write helper for this file.
  /// Inputs: `file`, `content`.
  /// Returns: `Future<void>`.
  /// Side effects: Writes a temp file and renames it over the target path.
  /// Notes: Internal helper used within this file only.
  static Future<void> _atomicWrite(File file, String content) async {
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(content);
    await tmp.rename(file.path);
  }

  // ── Encoding helpers ──

  /// Return raw file content as plain JSON.
  /// Purpose: Provide the internal to json helper for this file.
  /// Inputs: `raw`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  static String _toJson(String raw) {
    return raw;
  }

  /// Return plain JSON for storage.
  /// Purpose: Provide the internal to raw helper for this file.
  /// Inputs: `json`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  static String _toRaw(String json) {
    return json;
  }

  /// Purpose: Provide the internal preserve unknown json helper for this file.
  /// Inputs: `fileName`, `mergedJson`.
  /// Returns: `String`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static String _preserveUnknownJson(
    String fileName,
    String mergedJson, {
    String? baseJson,
    String? localJson,
    String? remoteJson,
  }) {
    final schema = dataFilePreservationSchemas[fileName];
    if (schema == null) return mergedJson;
    return JsonPreservation.preserveJsonString(
      nextJson: mergedJson,
      sourceJsons: [baseJson, localJson, remoteJson],
      schema: schema,
    );
  }

  /// Purpose: Provide the internal preserve unknown json from current sources helper for this file.
  /// Inputs: `config`, `fileName`, `localFile`, `mergedJson`.
  /// Returns: `Future<String>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static Future<String> _preserveUnknownJsonFromCurrentSources(
    WebDAVConfig config,
    String fileName,
    File localFile,
    String mergedJson,
  ) async {
    final schema = dataFilePreservationSchemas[fileName];
    if (schema == null) return mergedJson;
    String? localJson;
    if (await localFile.exists()) {
      localJson = _toJson(await localFile.readAsString());
    }
    final remoteRaw = await _download(config, fileName);
    return _preserveUnknownJson(
      fileName,
      mergedJson,
      localJson: localJson,
      remoteJson: remoteRaw != null ? _toJson(remoteRaw) : null,
    );
  }

  // ── HTTP helpers ──

  /// Purpose: Provide the internal auth headers helper for this file.
  /// Inputs: `config`.
  /// Returns: `Map<String, String>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static Map<String, String> _authHeaders(WebDAVConfig config) {
    final creds = base64Encode(
      utf8.encode('${config.username}:${config.password}'),
    );
    return {'Authorization': 'Basic $creds'};
  }

  /// Purpose: Provide the internal remote file url helper for this file.
  /// Inputs: `config`, `fileName`.
  /// Returns: `String`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static String _remoteFileUrl(WebDAVConfig config, String fileName) {
    final base = config.serverUrl.endsWith('/')
        ? config.serverUrl.substring(0, config.serverUrl.length - 1)
        : config.serverUrl;
    final path = config.remotePath.endsWith('/')
        ? config.remotePath
        : '${config.remotePath}/';
    return '$base$path$fileName';
  }

  /// Purpose: Implement the test connection behavior for this file.
  /// Inputs: `config`.
  /// Returns: `Future<bool>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<bool> testConnection(WebDAVConfig config) async {
    try {
      final base = config.serverUrl.endsWith('/')
          ? config.serverUrl.substring(0, config.serverUrl.length - 1)
          : config.serverUrl;
      final url = Uri.parse('$base${config.remotePath}/');
      final request = http.Request('PROPFIND', url);
      request.headers.addAll(_authHeaders(config));
      request.headers['Depth'] = '0';
      request.headers['Content-Type'] = 'application/xml';
      request.body =
          '<?xml version="1.0"?><d:propfind xmlns:d="DAV:"><d:prop><d:resourcetype/></d:prop></d:propfind>';

      final streamed = await http.Client()
          .send(request)
          .timeout(const Duration(seconds: 10));
      return streamed.statusCode == 207 || streamed.statusCode == 404;
    } catch (_) {
      return false;
    }
  }

  /// Purpose: Provide the internal ensure remote dir helper for this file.
  /// Inputs: `config`.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static Future<void> _ensureRemoteDir(WebDAVConfig config) async {
    try {
      final base = config.serverUrl.endsWith('/')
          ? config.serverUrl.substring(0, config.serverUrl.length - 1)
          : config.serverUrl;
      final url = Uri.parse('$base${config.remotePath}/');
      final request = http.Request('MKCOL', url);
      request.headers.addAll(_authHeaders(config));
      await http.Client().send(request).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  /// Purpose: Provide the internal upload helper for this file.
  /// Inputs: `config`, `fileName`, `content`.
  /// Returns: `Future<bool>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static Future<bool> _upload(
    WebDAVConfig config,
    String fileName,
    String content,
  ) async {
    try {
      final url = Uri.parse(_remoteFileUrl(config, fileName));
      final response = await http
          .put(
            url,
            headers: {
              ..._authHeaders(config),
              'Content-Type': 'application/octet-stream',
            },
            body: utf8.encode(content),
          )
          .timeout(const Duration(seconds: 30));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Throws [Exception] on HTTP error or network failure.
  /// Purpose: Provide the internal upload bytes helper for this file.
  /// Inputs: `config`, `fileName`, `bytes`.
  /// Returns: `Future<void>`.
  /// Side effects: Uploads binary content to the remote WebDAV path.
  /// Notes: Internal helper used within this file only.
  static Future<void> _uploadBytes(
    WebDAVConfig config,
    String fileName,
    Uint8List bytes,
  ) async {
    final url = Uri.parse(_remoteFileUrl(config, fileName));
    final response = await http
        .put(
          url,
          headers: {
            ..._authHeaders(config),
            'Content-Type': 'application/octet-stream',
          },
          body: bytes,
        )
        .timeout(const Duration(seconds: 120));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }
  }

  /// Purpose: Provide the internal download helper for this file.
  /// Inputs: `config`, `fileName`.
  /// Returns: `Future<String?>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static Future<String?> _download(WebDAVConfig config, String fileName) async {
    try {
      final url = Uri.parse(_remoteFileUrl(config, fileName));
      final response = await http
          .get(url, headers: _authHeaders(config))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) return response.body;
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Image sync ──

  /// Purpose: Provide the internal ensure remote sub dir helper for this file.
  /// Inputs: `config`, `subPath`.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static Future<void> _ensureRemoteSubDir(
    WebDAVConfig config,
    String subPath,
  ) async {
    try {
      final base = config.serverUrl.endsWith('/')
          ? config.serverUrl.substring(0, config.serverUrl.length - 1)
          : config.serverUrl;
      final remotePath = config.remotePath.endsWith('/')
          ? config.remotePath
          : '${config.remotePath}/';
      final url = Uri.parse('$base$remotePath$subPath/');
      final request = http.Request('MKCOL', url);
      request.headers.addAll(_authHeaders(config));
      await http.Client().send(request).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  /// List file names in a remote sub-directory via PROPFIND.
  /// Purpose: Provide the internal list remote dir helper for this file.
  /// Inputs: `config`, `subPath`.
  /// Returns: `Future<Set<String>>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static Future<Set<String>> _listRemoteDir(
    WebDAVConfig config,
    String subPath,
  ) async {
    try {
      final base = config.serverUrl.endsWith('/')
          ? config.serverUrl.substring(0, config.serverUrl.length - 1)
          : config.serverUrl;
      final remotePath = config.remotePath.endsWith('/')
          ? config.remotePath
          : '${config.remotePath}/';
      final dirUrl = '$base$remotePath$subPath/';
      final url = Uri.parse(dirUrl);
      final request = http.Request('PROPFIND', url);
      request.headers.addAll(_authHeaders(config));
      request.headers['Depth'] = '1';
      request.headers['Content-Type'] = 'application/xml';
      request.body =
          '<?xml version="1.0"?><d:propfind xmlns:d="DAV:"><d:prop><d:resourcetype/></d:prop></d:propfind>';

      final streamed = await http.Client()
          .send(request)
          .timeout(const Duration(seconds: 30));
      if (streamed.statusCode != 207) return {};
      final body = await streamed.stream.bytesToString();

      // Parse href entries — each <d:href> or <D:href> contains a path.
      // We extract file names that are children of the directory.
      final hrefPattern = RegExp(r'<[dD]:href>([^<]+)</[dD]:href>');
      final names = <String>{};
      for (final match in hrefPattern.allMatches(body)) {
        final href = Uri.decodeFull(match.group(1)!);
        // Skip the directory itself (ends with subPath/)
        if (href.endsWith('$subPath/') || href.endsWith(subPath)) continue;
        final fileName = href.split('/').where((s) => s.isNotEmpty).last;
        if (fileName.isNotEmpty) names.add(fileName);
      }
      return names;
    } catch (_) {
      return {};
    }
  }

  /// Throws [Exception] on HTTP error or network failure.
  /// Purpose: Provide the internal download bytes helper for this file.
  /// Inputs: `config`, `fileName`.
  /// Returns: `Future<Uint8List>`.
  /// Side effects: Downloads binary content from the remote WebDAV path.
  /// Notes: Internal helper used within this file only.
  static Future<Uint8List> _downloadBytes(
    WebDAVConfig config,
    String fileName,
  ) async {
    final url = Uri.parse(_remoteFileUrl(config, fileName));
    final response = await http
        .get(url, headers: _authHeaders(config))
        .timeout(const Duration(seconds: 120));
    if (response.statusCode == 200) return response.bodyBytes;
    throw Exception('HTTP ${response.statusCode}');
  }

  /// Extract basenames of images referenced by actual records in the given JSON.
  ///
  /// [dataFile] is the file name, used to determine which fields to inspect.
  /// Supports `finance_data.json` (accounts + subscriptions) and
  /// `intimacy_data.json` (partners + toys).
  /// Purpose: Provide the internal get referenced image names helper for this file.
  /// Inputs: `json`, `dataFile`.
  /// Returns: `Set<String>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  static Set<String> _getReferencedImageNames(String? json, String dataFile) {
    if (json == null) return {};
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final names = <String>{};
      List<String> sections;
      switch (dataFile) {
        case 'finance_data.json':
          sections = ['accounts', 'subscriptions'];
        case 'intimacy_data.json':
          sections = ['partners', 'toys'];
        default:
          return {};
      }
      for (final section in sections) {
        final items = decoded[section];
        if (items is List) {
          for (final item in items) {
            if (item is Map) {
              final path = item['imagePath'] as String?;
              if (path != null && path.isNotEmpty) {
                names.add(p.basename(path));
              }
            }
          }
        }
      }
      return names;
    } catch (_) {
      return {};
    }
  }

  /// Sync only images that are referenced by actual records (local ∪ remote),
  /// skipping orphaned images to avoid transferring stale/unused data.
  ///
  /// Returns a list of non-fatal error strings for individual transfer failures.
  /// Purpose: Provide the internal sync images helper for this file.
  /// Inputs: `config`, `appDir`, `referencedImages`.
  /// Returns: `Future<List<String>>`.
  /// Side effects: Uploads and downloads referenced image files between local storage and WebDAV.
  /// Notes: Internal helper used within this file only.
  static Future<List<String>> _syncImages(
    WebDAVConfig config,
    Directory appDir,
    Set<String> referencedImages,
  ) async {
    final errors = <String>[];
    if (referencedImages.isEmpty) return errors;

    final imgDir = Directory(p.join(appDir.path, 'images'));
    if (!await imgDir.exists()) await imgDir.create(recursive: true);

    await _ensureRemoteSubDir(config, 'images');

    // Collect local referenced images (skip orphans)
    final localNames = <String>{};
    await for (final entity in imgDir.list()) {
      if (entity is File) {
        final name = p.basename(entity.path);
        if (referencedImages.contains(name)) localNames.add(name);
      }
    }

    // List all remote files (needed to avoid re-uploading existing ones)
    final remoteNames = await _listRemoteDir(config, 'images');

    // Upload local referenced images that are missing on remote
    for (final name in localNames) {
      if (!remoteNames.contains(name)) {
        try {
          final bytes = await File(p.join(imgDir.path, name)).readAsBytes();
          await _uploadBytes(config, 'images/$name', bytes);
        } on TimeoutException {
          errors.add('Upload timed out: $name');
        } catch (e) {
          errors.add('Upload failed for $name: $e');
        }
      }
    }

    // Download referenced remote images that are missing locally
    for (final name in referencedImages) {
      if (!localNames.contains(name) && remoteNames.contains(name)) {
        try {
          final bytes = await _downloadBytes(config, 'images/$name');
          await File(p.join(imgDir.path, name)).writeAsBytes(bytes);
        } on TimeoutException {
          errors.add('Download timed out: $name');
        } catch (e) {
          errors.add('Download failed for $name: $e');
        }
      }
    }

    return errors;
  }

  // ── Per-record merge sync ──

  /// Sync data files with the remote server using per-record three-way merge.
  ///
  /// For each data file:
  /// - Reads local, remote, and base (last-synced) versions
  /// - Merges per-record using `modifiedAt` timestamps
  /// - Auto-resolves when only one side changed
  /// - Returns conflicts when both sides modified the same record
  ///
  /// When [autoResolve] is true, conflicts are resolved automatically using
  /// last-writer-wins (newer `modifiedAt`). Used by auto-sync to prevent
  /// one conflict from blocking all other records in the same file.
  ///
  /// Returns [SyncResult]. If `hasConflicts` is true, call
  /// [finalizePendingSync] after user resolves each conflict.
  /// Purpose: Implement the sync behavior for this file.
  /// Inputs: `config`, `autoResolve`.
  /// Returns: `Future<SyncResult>`.
  /// Side effects: Reads and writes local data files, base snapshots, remote WebDAV files, and sync state.
  /// Notes: None.
  static Future<SyncResult> sync(
    WebDAVConfig config, {
    bool autoResolve = false,
  }) async {
    if (_syncing) {
      return const SyncResult(
        success: false,
        error: 'Sync already in progress',
      );
    }
    _syncing = true;
    try {
      await _ensureRemoteDir(config);
      final appDir = await TodoStorage.getAppDir();

      TodoMergeResult? pendingTodo;
      FinanceMergeResult? pendingFinance;
      IntimacyMergeResult? pendingIntimacy;
      WeightMergeResult? pendingWeight;
      final perFileErrors = <String>[];

      // Track JSON for referenced-image computation (local ∪ remote).
      String? localFinanceJson;
      String? remoteFinanceJson;
      String? localIntimacyJson;
      String? remoteIntimacyJson;

      for (final name in _dataFileNames) {
        final localFile = File('${appDir.path}/$name');
        final localExists = await localFile.exists();
        final remoteRaw = await _download(config, name);
        final isRates = name == 'exchange_rates.json';

        if (!localExists && remoteRaw == null) continue;

        if (!localExists && remoteRaw != null) {
          // Only on remote → download
          await _atomicWrite(localFile, remoteRaw);
          await _saveBase(name, _toJson(remoteRaw));
          _localDataChanged = true;
          if (name == 'finance_data.json') remoteFinanceJson = remoteRaw;
          if (name == 'intimacy_data.json') remoteIntimacyJson = remoteRaw;
          continue;
        }

        final localRaw = await localFile.readAsString();
        if (name == 'finance_data.json') localFinanceJson = localRaw;
        if (name == 'intimacy_data.json') localIntimacyJson = localRaw;

        if (localExists && remoteRaw == null) {
          // Only on local → upload
          final uploaded = await _upload(config, name, localRaw);
          if (uploaded) await _saveBase(name, _toJson(localRaw));
          continue;
        }

        if (name == 'finance_data.json') remoteFinanceJson = remoteRaw;
        if (name == 'intimacy_data.json') remoteIntimacyJson = remoteRaw;

        // Both exist → per-record merge
        final localJson = _toJson(localRaw);
        final remoteJson = _toJson(remoteRaw!);
        final baseJson = await _readBase(name);

        if (localJson == remoteJson) {
          // Identical content — already in sync
          await _saveBase(name, localJson);
          continue;
        }

        // Per-file try-catch: if one file fails to merge, others still sync.
        // Exceptions propagate from merge functions (no silent empty fallback).
        try {
          if (isRates) {
            // Exchange rates: union merge, no per-record conflicts
            final mergedJson = _preserveUnknownJson(
              name,
              mergeExchangeRateJson(localJson, remoteJson),
              baseJson: baseJson,
              localJson: localJson,
              remoteJson: remoteJson,
            );
            final mergedRaw = mergedJson;
            await _atomicWrite(localFile, mergedRaw);
            final uploaded = await _upload(config, name, mergedRaw);
            if (uploaded) await _saveBase(name, mergedJson);
            _localDataChanged = true;
            continue;
          }

          // Structured data files — per-record merge
          switch (name) {
            case 'todo_data.json':
              var sourceLocalJson = localJson;
              var result = mergeTodoData(
                localJson,
                remoteJson,
                baseJson,
                autoResolve: autoResolve,
              );
              if (!result.hasConflicts) {
                // Re-read local to detect concurrent saves during network I/O
                final freshLocalRaw = await localFile.readAsString();
                final freshLocalJson = _toJson(freshLocalRaw);
                if (freshLocalJson != localJson) {
                  sourceLocalJson = freshLocalJson;
                  result = mergeTodoData(
                    freshLocalJson,
                    remoteJson,
                    baseJson,
                    autoResolve: autoResolve,
                  );
                }
              }
              if (result.hasConflicts) {
                pendingTodo = result;
              } else {
                final mergedData = result.buildResolved({});
                final mergedJson = _preserveUnknownJson(
                  name,
                  jsonEncode(mergedData.toJson()),
                  baseJson: baseJson,
                  localJson: sourceLocalJson,
                  remoteJson: remoteJson,
                );
                final mergedRaw = _toRaw(mergedJson);
                await _atomicWrite(localFile, mergedRaw);
                final uploaded = await _upload(config, name, mergedRaw);
                if (uploaded) await _saveBase(name, mergedJson);
                _localDataChanged = true;
              }

            case 'finance_data.json':
              var sourceLocalJson = localJson;
              var result = mergeFinanceData(
                localJson,
                remoteJson,
                baseJson,
                autoResolve: autoResolve,
              );
              if (!result.hasConflicts) {
                final freshLocalRaw = await localFile.readAsString();
                final freshLocalJson = _toJson(freshLocalRaw);
                if (freshLocalJson != localJson) {
                  sourceLocalJson = freshLocalJson;
                  result = mergeFinanceData(
                    freshLocalJson,
                    remoteJson,
                    baseJson,
                    autoResolve: autoResolve,
                  );
                }
              }
              if (result.hasConflicts) {
                pendingFinance = result;
              } else {
                final mergedData = await _migrateFinanceForcedBalances(
                  result.buildResolved({}),
                );
                final mergedJson = _preserveUnknownJson(
                  name,
                  jsonEncode(mergedData.toJson()),
                  baseJson: baseJson,
                  localJson: sourceLocalJson,
                  remoteJson: remoteJson,
                );
                final mergedRaw = _toRaw(mergedJson);
                await _atomicWrite(localFile, mergedRaw);
                final uploaded = await _upload(config, name, mergedRaw);
                if (uploaded) await _saveBase(name, mergedJson);
                // Use merged result for image reference computation.
                localFinanceJson = mergedJson;
                _localDataChanged = true;
              }

            case 'intimacy_data.json':
              var sourceLocalJson = localJson;
              var result = mergeIntimacyData(
                localJson,
                remoteJson,
                baseJson,
                autoResolve: autoResolve,
              );
              if (!result.hasConflicts) {
                final freshLocalRaw = await localFile.readAsString();
                final freshLocalJson = _toJson(freshLocalRaw);
                if (freshLocalJson != localJson) {
                  sourceLocalJson = freshLocalJson;
                  result = mergeIntimacyData(
                    freshLocalJson,
                    remoteJson,
                    baseJson,
                    autoResolve: autoResolve,
                  );
                }
              }
              if (result.hasConflicts) {
                pendingIntimacy = result;
              } else {
                final mergedData = result.buildResolved({});
                final mergedJson = _preserveUnknownJson(
                  name,
                  jsonEncode(mergedData.toJson()),
                  baseJson: baseJson,
                  localJson: sourceLocalJson,
                  remoteJson: remoteJson,
                );
                final mergedRaw = _toRaw(mergedJson);
                await _atomicWrite(localFile, mergedRaw);
                final uploaded = await _upload(config, name, mergedRaw);
                if (uploaded) await _saveBase(name, mergedJson);
                // Use merged result for image reference computation.
                localIntimacyJson = mergedJson;
                _localDataChanged = true;
              }

            case 'weight_data.json':
              var sourceLocalJson = localJson;
              var result = mergeWeightData(
                localJson,
                remoteJson,
                baseJson,
                autoResolve: autoResolve,
              );
              if (!result.hasConflicts) {
                final freshLocalRaw = await localFile.readAsString();
                final freshLocalJson = _toJson(freshLocalRaw);
                if (freshLocalJson != localJson) {
                  sourceLocalJson = freshLocalJson;
                  result = mergeWeightData(
                    freshLocalJson,
                    remoteJson,
                    baseJson,
                    autoResolve: autoResolve,
                  );
                }
              }
              if (result.hasConflicts) {
                pendingWeight = result;
              } else {
                final mergedData = result.buildResolved({});
                final mergedJson = _preserveUnknownJson(
                  name,
                  jsonEncode(mergedData.toJson()),
                  baseJson: baseJson,
                  localJson: sourceLocalJson,
                  remoteJson: remoteJson,
                );
                final mergedRaw = _toRaw(mergedJson);
                await _atomicWrite(localFile, mergedRaw);
                final uploaded = await _upload(config, name, mergedRaw);
                if (uploaded) await _saveBase(name, mergedJson);
                _localDataChanged = true;
              }
          }
        } catch (e) {
          // Per-file merge error: skip this file, continue syncing others.
          // Local file is unchanged (merge exception fires before write).
          perFileErrors.add('$name: $e');
        }
      }

      // Sync only images referenced by actual records (local ∪ remote),
      // skipping orphaned images to avoid transferring stale/unused data.
      final referencedImages = {
        ..._getReferencedImageNames(localFinanceJson, 'finance_data.json'),
        ..._getReferencedImageNames(remoteFinanceJson, 'finance_data.json'),
        ..._getReferencedImageNames(localIntimacyJson, 'intimacy_data.json'),
        ..._getReferencedImageNames(remoteIntimacyJson, 'intimacy_data.json'),
      };
      final imageErrors = await _syncImages(config, appDir, referencedImages);

      final hasConflicts =
          pendingTodo != null ||
          pendingFinance != null ||
          pendingIntimacy != null ||
          pendingWeight != null;

      if (hasConflicts) {
        return SyncResult(
          success: perFileErrors.isEmpty,
          error: perFileErrors.isNotEmpty ? perFileErrors.join('; ') : null,
          pending: PendingSync(
            todoMerge: pendingTodo,
            financeMerge: pendingFinance,
            intimacyMerge: pendingIntimacy,
            weightMerge: pendingWeight,
          ),
          warnings: imageErrors,
        );
      }

      return SyncResult(
        success: perFileErrors.isEmpty,
        error: perFileErrors.isNotEmpty ? perFileErrors.join('; ') : null,
        warnings: imageErrors,
      );
    } catch (e) {
      return SyncResult(success: false, error: e.toString());
    } finally {
      _syncing = false;
    }
  }

  /// Purpose: Implement the finalize pending sync behavior for this file.
  /// Finalize sync by applying user's conflict resolutions.
  ///
  /// [resolutions] maps record ID → the chosen record object (local or remote).
  /// Purpose: Implement the finalize pending sync behavior for this file.
  /// Inputs: `config`, `pending`, `resolutions`.
  /// Returns: `Future<bool>`.
  /// Side effects: Writes resolved merge results to local files, remote WebDAV files, and base snapshots.
  /// Notes: None.
  static Future<bool> finalizePendingSync(
    WebDAVConfig config,
    PendingSync pending,
    Map<String, dynamic> resolutions,
  ) async {
    try {
      final appDir = await TodoStorage.getAppDir();

      if (pending.todoMerge != null) {
        final mergedData = pending.todoMerge!.buildResolved(
          resolutions.cast<String, dynamic>().map((k, v) => MapEntry(k, v)),
        );
        final localFile = File('${appDir.path}/todo_data.json');
        final mergedJson = await _preserveUnknownJsonFromCurrentSources(
          config,
          'todo_data.json',
          localFile,
          jsonEncode(mergedData.toJson()),
        );
        final mergedRaw = _toRaw(mergedJson);
        await _atomicWrite(localFile, mergedRaw);
        final uploaded = await _upload(config, 'todo_data.json', mergedRaw);
        if (uploaded) await _saveBase('todo_data.json', mergedJson);
      }

      if (pending.financeMerge != null) {
        final mergedData = await _migrateFinanceForcedBalances(
          pending.financeMerge!.buildResolved(resolutions),
        );
        final localFile = File('${appDir.path}/finance_data.json');
        final mergedJson = await _preserveUnknownJsonFromCurrentSources(
          config,
          'finance_data.json',
          localFile,
          jsonEncode(mergedData.toJson()),
        );
        final mergedRaw = _toRaw(mergedJson);
        await _atomicWrite(localFile, mergedRaw);
        final uploaded = await _upload(config, 'finance_data.json', mergedRaw);
        if (uploaded) await _saveBase('finance_data.json', mergedJson);
      }

      if (pending.intimacyMerge != null) {
        final mergedData = pending.intimacyMerge!.buildResolved(resolutions);
        final localFile = File('${appDir.path}/intimacy_data.json');
        final mergedJson = await _preserveUnknownJsonFromCurrentSources(
          config,
          'intimacy_data.json',
          localFile,
          jsonEncode(mergedData.toJson()),
        );
        final mergedRaw = _toRaw(mergedJson);
        await _atomicWrite(localFile, mergedRaw);
        final uploaded = await _upload(config, 'intimacy_data.json', mergedRaw);
        if (uploaded) await _saveBase('intimacy_data.json', mergedJson);
      }

      if (pending.weightMerge != null) {
        final mergedData = pending.weightMerge!.buildResolved(resolutions);
        final localFile = File('${appDir.path}/weight_data.json');
        final mergedJson = await _preserveUnknownJsonFromCurrentSources(
          config,
          'weight_data.json',
          localFile,
          jsonEncode(mergedData.toJson()),
        );
        final mergedRaw = _toRaw(mergedJson);
        await _atomicWrite(localFile, mergedRaw);
        final uploaded = await _upload(config, 'weight_data.json', mergedRaw);
        if (uploaded) await _saveBase('weight_data.json', mergedJson);
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}
