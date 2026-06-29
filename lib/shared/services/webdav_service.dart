import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

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

/// A WebDAV upload lock stored in the remote `.lock` file.
class WebDAVUploadLock {
  final String clientId;
  final String token;
  final DateTime startedAt;
  final DateTime updatedAt;
  final int ttlSeconds;

  /// Purpose: Create a WebDAV upload lock value.
  /// Inputs: `clientId`, `token`, `startedAt`, `updatedAt`, `ttlSeconds`.
  /// Returns: A new `WebDAVUploadLock` instance.
  /// Side effects: None.
  /// Notes: Times are stored in UTC and compared against [ttlSeconds].
  const WebDAVUploadLock({
    required this.clientId,
    required this.token,
    required this.startedAt,
    required this.updatedAt,
    required this.ttlSeconds,
  });

  /// Purpose: Parse a WebDAV upload lock from JSON.
  /// Inputs: `json`.
  /// Returns: A parsed `WebDAVUploadLock`.
  /// Side effects: None.
  /// Notes: Throws when required fields are missing or malformed.
  factory WebDAVUploadLock.fromJson(Map<String, dynamic> json) {
    return WebDAVUploadLock(
      clientId: json['clientId'] as String,
      token: json['token'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
      ttlSeconds: json['ttlSeconds'] as int? ?? 150,
    );
  }

  /// Purpose: Serialize this lock to the remote `.lock` JSON format.
  /// Inputs: None.
  /// Returns: JSON-compatible map.
  /// Side effects: None.
  /// Notes: None.
  Map<String, dynamic> toJson() => {
    'clientId': clientId,
    'token': token,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'ttlSeconds': ttlSeconds,
  };

  /// Purpose: Return whether this lock is expired at [now].
  /// Inputs: `now`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Expired locks are treated as failed uploads and may be replaced.
  bool isExpired(DateTime now) =>
      now.toUtc().difference(updatedAt.toUtc()).inSeconds >= ttlSeconds;

  /// Purpose: Return whether this lock belongs to the given session.
  /// Inputs: `clientId`, `token`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Used before refreshing or deleting remote locks.
  bool matches(String clientId, String token) =>
      this.clientId == clientId && this.token == token;

  /// Purpose: Create a refreshed copy of this lock.
  /// Inputs: `updatedAt`.
  /// Returns: `WebDAVUploadLock`.
  /// Side effects: None.
  /// Notes: Keeps the original token and started time.
  WebDAVUploadLock refreshed(DateTime updatedAt) => WebDAVUploadLock(
    clientId: clientId,
    token: token,
    startedAt: startedAt,
    updatedAt: updatedAt.toUtc(),
    ttlSeconds: ttlSeconds,
  );
}

/// Local state for the upload lock currently held by this process.
class _UploadSession {
  final String clientId;
  final String token;

  /// Purpose: Create an upload session marker.
  /// Inputs: `clientId`, `token`.
  /// Returns: A new `_UploadSession` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _UploadSession({required this.clientId, required this.token});
}

/// Outcome status of a remote file download attempt.
enum RemoteFileStatus { found, notFound, error }

/// Discriminated result of a remote file download.
///
/// Distinguishes "the file does not exist on the remote" (HTTP 404) from
/// transport/server failures, because only a true 404 may trigger the
/// upload-local-as-new sync path. Treating errors as "missing" can overwrite
/// remote data and cascade into cross-device record deletion.
class RemoteFile {
  final RemoteFileStatus status;
  final String? content;
  final String? etag;
  final String? error;

  /// Purpose: Create a found result with downloaded content.
  /// Inputs: `content`, optional `etag` response header value.
  /// Returns: A new `RemoteFile` instance with `RemoteFileStatus.found`.
  /// Side effects: None.
  /// Notes: None.
  const RemoteFile.found(String this.content, {this.etag})
    : status = RemoteFileStatus.found,
      error = null;

  /// Purpose: Create a not-found result for HTTP 404.
  /// Inputs: None.
  /// Returns: A new `RemoteFile` instance with `RemoteFileStatus.notFound`.
  /// Side effects: None.
  /// Notes: None.
  const RemoteFile.notFound()
    : status = RemoteFileStatus.notFound,
      content = null,
      etag = null,
      error = null;

  /// Purpose: Create an error result for any non-404 failure.
  /// Inputs: `error` message.
  /// Returns: A new `RemoteFile` instance with `RemoteFileStatus.error`.
  /// Side effects: None.
  /// Notes: None.
  const RemoteFile.failure(String this.error)
    : status = RemoteFileStatus.error,
      content = null,
      etag = null;
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
  static const _lockFileName = '.lock';
  static const _clientIdFileName = 'client_id.txt';
  static const _localLockFileName = 'upload_lock.json';
  static const _lockTtlSeconds = 60;

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

  /// Purpose: Load or create the stable local WebDAV client ID.
  /// Inputs: None.
  /// Returns: `Future<String>`.
  /// Side effects: May create `.sync_base/client_id.txt`.
  /// Notes: The client ID is local-only and is never synced or exported.
  static Future<String> _loadClientId() async {
    final dir = await _getBaseDir();
    final file = File('${dir.path}/$_clientIdFileName');
    if (await file.exists()) {
      final existing = (await file.readAsString()).trim();
      if (existing.isNotEmpty) return existing;
    }
    final id = const Uuid().v4();
    await file.writeAsString(id);
    return id;
  }

  /// Purpose: Read the local upload lock left by an interrupted upload.
  /// Inputs: None.
  /// Returns: `Future<WebDAVUploadLock?>`.
  /// Side effects: None.
  /// Notes: Invalid local locks are ignored and overwritten on the next upload.
  static Future<WebDAVUploadLock?> _readLocalUploadLock() async {
    try {
      final dir = await _getBaseDir();
      final file = File('${dir.path}/$_localLockFileName');
      if (!await file.exists()) return null;
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return WebDAVUploadLock.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Purpose: Persist the local upload lock before remote uploads start.
  /// Inputs: `lock`.
  /// Returns: None.
  /// Side effects: Writes `.sync_base/upload_lock.json`.
  /// Notes: The local lock lets the next app start detect interrupted uploads.
  static Future<void> _saveLocalUploadLock(WebDAVUploadLock lock) async {
    final dir = await _getBaseDir();
    final file = File('${dir.path}/$_localLockFileName');
    await _atomicWrite(file, jsonEncode(lock.toJson()));
  }

  /// Purpose: Remove the local upload lock after upload completion or recovery.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Deletes `.sync_base/upload_lock.json` when present.
  /// Notes: Missing files are ignored.
  static Future<void> _clearLocalUploadLock() async {
    final dir = await _getBaseDir();
    final file = File('${dir.path}/$_localLockFileName');
    if (await file.exists()) await file.delete();
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

  /// Purpose: Write a resolved/merged data file locally, upload it, and save the base.
  /// Inputs: `config`, `fileName`, `mergedJson` (serialized resolved data).
  /// Returns: `Future<bool>` — false when the remote read or upload fails.
  /// Side effects: Downloads the current remote file for unknown-field preservation
  /// context, writes the local file, uploads, saves the base snapshot.
  /// Notes: Internal helper used within this file only. Resolved data is
  /// force-uploaded under the held remote `.lock`; a remote download error aborts
  /// the file so resolutions are never uploaded over an unreadable remote.
  static Future<bool> _finalizeFile(
    WebDAVConfig config,
    String fileName,
    String mergedJson,
    _UploadSession uploadSession,
  ) async {
    final appDir = await TodoStorage.getAppDir();
    final localFile = File('${appDir.path}/$fileName');

    String? localJson;
    if (await localFile.exists()) {
      localJson = await localFile.readAsString();
    }
    final remote = await _download(config, fileName);
    if (remote.status == RemoteFileStatus.error) return false;
    final preservedJson = _preserveUnknownJson(
      fileName,
      mergedJson,
      localJson: localJson,
      remoteJson: remote.content,
    );
    await _atomicWrite(localFile, preservedJson);
    _localDataChanged = true;
    final result = await _uploadWithSession(
      config,
      fileName,
      preservedJson,
      uploadSession,
    );
    if (result.error != null) return false;
    await _saveBase(fileName, preservedJson);
    return true;
  }

  /// Purpose: Force-upload merged JSON under the held remote `.lock`.
  /// Inputs: `config`, `fileName`, `mergedJson`, `localFile`, `baseJson`,
  ///   `sourceLocalJson`, `remoteJson` (for unknown-field preservation).
  /// Returns: `String?` — `null` on success, otherwise an error message.
  /// Side effects: Writes the local file, uploads to remote, saves the base snapshot.
  /// Notes: Internal helper used within this file only. Data-file ETags are not
  /// used here because the remote `.lock` is the upload concurrency guard.
  static Future<String?> _uploadMergedJson(
    WebDAVConfig config,
    String fileName,
    String mergedJson, {
    required Future<_UploadSession?> Function() ensureUploadSession,
    required File localFile,
    String? baseJson,
    String? sourceLocalJson,
    String? remoteJson,
  }) async {
    final preservedJson = _preserveUnknownJson(
      fileName,
      mergedJson,
      baseJson: baseJson,
      localJson: sourceLocalJson,
      remoteJson: remoteJson,
    );
    await _atomicWrite(localFile, preservedJson);
    _localDataChanged = true;
    final uploadSession = await ensureUploadSession();
    if (uploadSession == null) return 'upload lock was not acquired';
    final result = await _uploadWithSession(
      config,
      fileName,
      preservedJson,
      uploadSession,
    );
    if (result.error == null) {
      await _saveBase(fileName, preservedJson);
      return null;
    }
    return result.error;
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

  /// Purpose: Upload content to a remote WebDAV path.
  /// Inputs: `config`, `fileName`, `content`, optional lock-file preconditions.
  /// Returns: `Future<({bool is412, String? error})>` — `error` is `null` on success.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Conditional headers are used for `.lock` writes only. Data JSON
  /// writes go through `_uploadWithSession()` and do not pass data-file
  /// preconditions.
  static Future<({bool is412, String? error})> _upload(
    WebDAVConfig config,
    String fileName,
    String content, {
    String? ifMatchEtag,
    bool ifNoneMatchAll = false,
  }) async {
    try {
      final url = Uri.parse(_remoteFileUrl(config, fileName));
      final response = await http
          .put(
            url,
            headers: {
              ..._authHeaders(config),
              'Content-Type': 'application/octet-stream',
              'If-Match': ?ifMatchEtag,
              if (ifNoneMatchAll) 'If-None-Match': '*',
            },
            body: utf8.encode(content),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 412) {
        return (is412: true, error: 'conditional WebDAV PUT failed (HTTP 412)');
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return (is412: false, error: null);
      }
      return (is412: false, error: 'HTTP ${response.statusCode}');
    } catch (e) {
      return (is412: false, error: '$e');
    }
  }

  /// Purpose: Return [etag] only when it is a strong ETag usable for lock preconditions.
  /// Inputs: `etag` from a download response, possibly null or weak (`W/...`).
  /// Returns: `String?` — the strong ETag, or null when absent/weak.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Weak ETags must not be
  /// used in `.lock` `If-Match` preconditions (RFC 9110 strong comparison).
  static String? _strongEtag(String? etag) {
    if (etag == null || etag.startsWith('W/')) return null;
    return etag;
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

  /// Purpose: Download a remote data file with a discriminated outcome.
  /// Inputs: `config`, `fileName`.
  /// Returns: `Future<RemoteFile>` — found with content/ETag, notFound for HTTP 404,
  /// or error for any other failure.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only. Callers must treat only
  /// `notFound` as "file missing on remote"; an `error` outcome (auth/server/network
  /// failure) must abort that file's sync so local data is never uploaded over an
  /// unreadable remote file.
  static Future<RemoteFile> _download(
    WebDAVConfig config,
    String fileName,
  ) async {
    try {
      final url = Uri.parse(_remoteFileUrl(config, fileName));
      final response = await http
          .get(url, headers: _authHeaders(config))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return RemoteFile.found(response.body, etag: response.headers['etag']);
      }
      if (response.statusCode == 404) return const RemoteFile.notFound();
      return RemoteFile.failure('HTTP ${response.statusCode}');
    } catch (e) {
      return RemoteFile.failure('$e');
    }
  }

  /// Purpose: Read and parse the remote WebDAV upload lock.
  /// Inputs: `config`.
  /// Returns: Remote lock, ETag, and optional error.
  /// Side effects: Performs network I/O.
  /// Notes: Missing or malformed locks are treated as replaceable stale locks.
  static Future<({WebDAVUploadLock? lock, String? etag, String? error})>
  _readRemoteUploadLock(WebDAVConfig config) async {
    final remote = await _download(config, _lockFileName);
    if (remote.status == RemoteFileStatus.error) {
      return (lock: null, etag: null, error: remote.error);
    }
    if (remote.status == RemoteFileStatus.notFound || remote.content == null) {
      return (lock: null, etag: null, error: null);
    }
    try {
      final json = jsonDecode(remote.content!) as Map<String, dynamic>;
      return (
        lock: WebDAVUploadLock.fromJson(json),
        etag: _strongEtag(remote.etag),
        error: null,
      );
    } catch (_) {
      return (lock: null, etag: _strongEtag(remote.etag), error: null);
    }
  }

  /// Purpose: Write the remote WebDAV upload lock with optional preconditions.
  /// Inputs: `config`, `lock`, optional ETag or create-only flag.
  /// Returns: Upload result.
  /// Side effects: Performs network I/O and may replace `.lock`.
  /// Notes: Uses the same conditional PUT helper as data uploads.
  static Future<({bool is412, String? error})> _writeRemoteUploadLock(
    WebDAVConfig config,
    WebDAVUploadLock lock, {
    String? ifMatchEtag,
    bool ifNoneMatchAll = false,
  }) {
    return _upload(
      config,
      _lockFileName,
      jsonEncode(lock.toJson()),
      ifMatchEtag: ifMatchEtag,
      ifNoneMatchAll: ifNoneMatchAll,
    );
  }

  /// Purpose: Remove the remote WebDAV upload lock if it still belongs to us.
  /// Inputs: `config`, `etag`.
  /// Returns: None.
  /// Side effects: Performs network I/O.
  /// Notes: Errors are ignored because stale locks expire after the TTL.
  static Future<void> _deleteRemoteUploadLock(
    WebDAVConfig config, {
    String? etag,
  }) async {
    try {
      await http
          .delete(
            Uri.parse(_remoteFileUrl(config, _lockFileName)),
            headers: {..._authHeaders(config), 'If-Match': ?etag},
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  /// Purpose: Inspect a leftover local upload lock from a previous app run.
  /// Inputs: `config`, `clientId`.
  /// Returns: Optional token to resume and optional blocking error.
  /// Side effects: May clear stale local lock state.
  /// Notes: Normal sync after this step re-downloads, merges, and uploads.
  static Future<({String? resumeToken, String? error})>
  _prepareInterruptedUpload(WebDAVConfig config, String clientId) async {
    final localLock = await _readLocalUploadLock();
    if (localLock == null) return (resumeToken: null, error: null);

    final remote = await _readRemoteUploadLock(config);
    if (remote.error != null) return (resumeToken: null, error: remote.error);

    final remoteLock = remote.lock;
    if (remoteLock == null) {
      await _clearLocalUploadLock();
      return (resumeToken: null, error: null);
    }

    final now = DateTime.now().toUtc();
    if (remoteLock.matches(localLock.clientId, localLock.token) &&
        localLock.clientId == clientId) {
      return (resumeToken: localLock.token, error: null);
    }
    if (remoteLock.clientId != clientId && !remoteLock.isExpired(now)) {
      return (
        resumeToken: null,
        error: 'Another device is uploading; retry after the lock expires.',
      );
    }

    await _clearLocalUploadLock();
    return (resumeToken: null, error: null);
  }

  /// Purpose: Acquire the remote WebDAV upload lock before uploading.
  /// Inputs: `config`, `clientId`, optional `resumeToken`.
  /// Returns: Upload session or a visible error.
  /// Side effects: Writes local and remote lock files.
  /// Notes: Active locks owned by other clients block uploads until expiry.
  static Future<({_UploadSession? session, String? error})>
  _acquireUploadSession(
    WebDAVConfig config,
    String clientId, {
    String? resumeToken,
  }) async {
    final now = DateTime.now().toUtc();
    final remote = await _readRemoteUploadLock(config);
    if (remote.error != null) return (session: null, error: remote.error);

    final remoteLock = remote.lock;
    if (remoteLock != null &&
        remoteLock.clientId != clientId &&
        !remoteLock.isExpired(now)) {
      return (
        session: null,
        error: 'Another device is uploading; retry after the lock expires.',
      );
    }

    final lock = WebDAVUploadLock(
      clientId: clientId,
      token: resumeToken ?? const Uuid().v4(),
      startedAt: now,
      updatedAt: now,
      ttlSeconds: _lockTtlSeconds,
    );
    final write = await _writeRemoteUploadLock(
      config,
      lock,
      ifMatchEtag: remote.etag,
      ifNoneMatchAll: remoteLock == null && remote.etag == null,
    );
    if (write.error != null) {
      return (
        session: null,
        error: write.is412
            ? 'Another device started uploading; retry after the lock expires.'
            : write.error,
      );
    }
    await _saveLocalUploadLock(lock);
    return (
      session: _UploadSession(clientId: clientId, token: lock.token),
      error: null,
    );
  }

  /// Purpose: Refresh the remote upload lock before a PUT.
  /// Inputs: `config`, `session`.
  /// Returns: Optional error string.
  /// Side effects: Updates local and remote lock timestamps.
  /// Notes: If another active client owns the lock, uploading is blocked.
  static Future<String?> _refreshUploadLock(
    WebDAVConfig config,
    _UploadSession session,
  ) async {
    final remote = await _readRemoteUploadLock(config);
    if (remote.error != null) return remote.error;
    final now = DateTime.now().toUtc();
    final remoteLock = remote.lock;
    if (remoteLock != null &&
        !remoteLock.matches(session.clientId, session.token) &&
        remoteLock.clientId != session.clientId &&
        !remoteLock.isExpired(now)) {
      return 'Another device is uploading; retry after the lock expires.';
    }

    final lock =
        (remoteLock != null &&
            remoteLock.matches(session.clientId, session.token))
        ? remoteLock.refreshed(now)
        : WebDAVUploadLock(
            clientId: session.clientId,
            token: session.token,
            startedAt: now,
            updatedAt: now,
            ttlSeconds: _lockTtlSeconds,
          );
    final write = await _writeRemoteUploadLock(
      config,
      lock,
      ifMatchEtag: remote.etag,
      ifNoneMatchAll: remoteLock == null && remote.etag == null,
    );
    if (write.error != null) {
      return write.is412
          ? 'Another device started uploading; retry after the lock expires.'
          : write.error;
    }
    await _saveLocalUploadLock(lock);
    return null;
  }

  /// Purpose: Force-upload content after refreshing the held upload lock.
  /// Inputs: `config`, `fileName`, `content`, `session`.
  /// Returns: Upload result.
  /// Side effects: Performs network I/O.
  /// Notes: Data JSON writes are protected by `.lock`, so they intentionally do
  /// not send data-file `If-Match`/`If-None-Match` preconditions.
  static Future<({bool is412, String? error})> _uploadWithSession(
    WebDAVConfig config,
    String fileName,
    String content,
    _UploadSession session,
  ) async {
    final lockError = await _refreshUploadLock(config, session);
    if (lockError != null) return (is412: false, error: lockError);
    return _upload(config, fileName, content);
  }

  /// Purpose: Upload bytes after refreshing the held upload lock.
  /// Inputs: `config`, `fileName`, `bytes`, `session`.
  /// Returns: None.
  /// Side effects: Performs network I/O.
  /// Notes: Used for referenced image uploads under the same remote lock.
  static Future<void> _uploadBytesWithSession(
    WebDAVConfig config,
    String fileName,
    Uint8List bytes,
    _UploadSession session,
  ) async {
    final lockError = await _refreshUploadLock(config, session);
    if (lockError != null) throw Exception(lockError);
    return _uploadBytes(config, fileName, bytes);
  }

  /// Purpose: Release the held WebDAV upload lock.
  /// Inputs: `config`, `session`.
  /// Returns: None.
  /// Side effects: Deletes matching local and remote lock files.
  /// Notes: Remote delete only runs if the lock still has our client ID and token.
  static Future<void> _releaseUploadSession(
    WebDAVConfig config,
    _UploadSession? session,
  ) async {
    if (session == null) return;
    final remote = await _readRemoteUploadLock(config);
    if (remote.lock?.matches(session.clientId, session.token) ?? false) {
      await _deleteRemoteUploadLock(config, etag: remote.etag);
    }
    await _clearLocalUploadLock();
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
        // Skip sub-directories — collection hrefs end with a trailing slash.
        if (href.endsWith('/')) continue;
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
    Future<_UploadSession?> Function() ensureUploadSession,
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
        final uploadSession = await ensureUploadSession();
        if (uploadSession == null) {
          errors.add('Upload skipped for $name: upload lock was not acquired');
          continue;
        }
        try {
          final bytes = await File(p.join(imgDir.path, name)).readAsBytes();
          await _uploadBytesWithSession(
            config,
            'images/$name',
            bytes,
            uploadSession,
          );
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
    _UploadSession? uploadSession;
    try {
      await _ensureRemoteDir(config);
      final appDir = await TodoStorage.getAppDir();
      final clientId = await _loadClientId();
      final interrupted = await _prepareInterruptedUpload(config, clientId);
      if (interrupted.error != null) {
        return SyncResult(success: false, error: interrupted.error);
      }
      final acquired = await _acquireUploadSession(
        config,
        clientId,
        resumeToken: interrupted.resumeToken,
      );
      uploadSession = acquired.session;
      if (uploadSession == null) {
        return SyncResult(
          success: false,
          error: acquired.error ?? 'Upload lock was not acquired',
        );
      }

      /// Purpose: Return the upload lock acquired before data downloads.
      /// Inputs: None.
      /// Returns: The active upload session, or null if acquisition failed.
      /// Side effects: May write local and remote lock files.
      /// Notes: Internal helper used only within this sync attempt.
      Future<_UploadSession?> ensureUploadSession() async {
        return uploadSession;
      }

      /// Purpose: Force-upload JSON while holding the remote upload lock.
      /// Inputs: `fileName`, `content`.
      /// Returns: Upload result.
      /// Side effects: Performs network I/O.
      /// Notes: Internal helper used only within this sync attempt.
      Future<({bool is412, String? error})> uploadJson(
        String fileName,
        String content,
      ) async {
        final session = await ensureUploadSession();
        if (session == null) {
          return (is412: false, error: 'Upload lock was not acquired');
        }
        return _uploadWithSession(config, fileName, content, session);
      }

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
        final remote = await _download(config, name);
        final isRates = name == 'exchange_rates.json';

        // Any non-404 download failure aborts this file's sync; treating it
        // as "missing on remote" would overwrite remote data and can cascade
        // into cross-device record deletion on the next merge.
        if (remote.status == RemoteFileStatus.error) {
          perFileErrors.add('$name: download failed: ${remote.error}');
          continue;
        }
        var remoteRaw = remote.content;

        if (!localExists && remoteRaw == null) continue;

        if (!localExists && remoteRaw != null) {
          // Only on remote → download
          await _atomicWrite(localFile, remoteRaw);
          await _saveBase(name, remoteRaw);
          _localDataChanged = true;
          if (name == 'finance_data.json') remoteFinanceJson = remoteRaw;
          if (name == 'intimacy_data.json') remoteIntimacyJson = remoteRaw;
          continue;
        }

        final localRaw = await localFile.readAsString();
        if (name == 'finance_data.json') localFinanceJson = localRaw;
        if (name == 'intimacy_data.json') localIntimacyJson = localRaw;

        if (localExists && remoteRaw == null) {
          // Only on local → force-upload as new under the remote lock.
          final result = await uploadJson(name, localRaw);
          if (result.error == null) {
            await _saveBase(name, localRaw);
            continue;
          }
          perFileErrors.add('$name: force-upload failed: ${result.error}');
          continue;
        }

        if (name == 'finance_data.json') remoteFinanceJson = remoteRaw;
        if (name == 'intimacy_data.json') remoteIntimacyJson = remoteRaw;

        // Both exist → per-record merge
        final localJson = localRaw;
        final remoteJson = remoteRaw!;
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
            await _atomicWrite(localFile, mergedJson);
            _localDataChanged = true;
            final result = await uploadJson(name, mergedJson);
            if (result.error == null) {
              await _saveBase(name, mergedJson);
            } else {
              perFileErrors.add('$name: upload failed: ${result.error}');
            }
            continue;
          }

          // Structured data files — per-record merge
          switch (name) {
            case 'todo_data.json':
              var currentLocalJson = localJson;
              final currentRemoteJson = remoteJson;
              var result = mergeTodoData(
                currentLocalJson,
                currentRemoteJson,
                baseJson,
                autoResolve: autoResolve,
              );
              if (!result.hasConflicts) {
                final freshLocalJson = await localFile.readAsString();
                if (freshLocalJson != currentLocalJson) {
                  currentLocalJson = freshLocalJson;
                  result = mergeTodoData(
                    currentLocalJson,
                    currentRemoteJson,
                    baseJson,
                    autoResolve: autoResolve,
                  );
                }
              }
              if (result.hasConflicts) {
                pendingTodo = result;
              } else {
                final mergedData = result.buildResolved(const {});
                final mergedJson = jsonEncode(mergedData.toJson());
                final uploadError = await _uploadMergedJson(
                  config,
                  name,
                  mergedJson,
                  ensureUploadSession: ensureUploadSession,
                  localFile: localFile,
                  baseJson: baseJson,
                  sourceLocalJson: currentLocalJson,
                  remoteJson: currentRemoteJson,
                );
                if (uploadError != null) {
                  perFileErrors.add('$name: force-upload failed: $uploadError');
                }
              }

            case 'finance_data.json':
              var currentLocalJson = localJson;
              final currentRemoteJson = remoteJson;
              var result = mergeFinanceData(
                currentLocalJson,
                currentRemoteJson,
                baseJson,
                autoResolve: autoResolve,
              );
              if (!result.hasConflicts) {
                final freshLocalJson = await localFile.readAsString();
                if (freshLocalJson != currentLocalJson) {
                  currentLocalJson = freshLocalJson;
                  localFinanceJson = freshLocalJson;
                  result = mergeFinanceData(
                    currentLocalJson,
                    currentRemoteJson,
                    baseJson,
                    autoResolve: autoResolve,
                  );
                }
              }
              if (result.hasConflicts) {
                pendingFinance = result;
                remoteFinanceJson = currentRemoteJson;
              } else {
                final mergedData = await _migrateFinanceForcedBalances(
                  result.buildResolved(const {}),
                );
                final mergedJson = jsonEncode(mergedData.toJson());
                final uploadError = await _uploadMergedJson(
                  config,
                  name,
                  mergedJson,
                  ensureUploadSession: ensureUploadSession,
                  localFile: localFile,
                  baseJson: baseJson,
                  sourceLocalJson: currentLocalJson,
                  remoteJson: currentRemoteJson,
                );
                if (uploadError == null) {
                  localFinanceJson = mergedJson;
                } else {
                  perFileErrors.add('$name: force-upload failed: $uploadError');
                }
              }

            case 'intimacy_data.json':
              var currentLocalJson = localJson;
              final currentRemoteJson = remoteJson;
              var result = mergeIntimacyData(
                currentLocalJson,
                currentRemoteJson,
                baseJson,
                autoResolve: autoResolve,
              );
              if (!result.hasConflicts) {
                final freshLocalJson = await localFile.readAsString();
                if (freshLocalJson != currentLocalJson) {
                  currentLocalJson = freshLocalJson;
                  localIntimacyJson = freshLocalJson;
                  result = mergeIntimacyData(
                    currentLocalJson,
                    currentRemoteJson,
                    baseJson,
                    autoResolve: autoResolve,
                  );
                }
              }
              if (result.hasConflicts) {
                pendingIntimacy = result;
                remoteIntimacyJson = currentRemoteJson;
              } else {
                final mergedData = result.buildResolved(const {});
                final mergedJson = jsonEncode(mergedData.toJson());
                final uploadError = await _uploadMergedJson(
                  config,
                  name,
                  mergedJson,
                  ensureUploadSession: ensureUploadSession,
                  localFile: localFile,
                  baseJson: baseJson,
                  sourceLocalJson: currentLocalJson,
                  remoteJson: currentRemoteJson,
                );
                if (uploadError == null) {
                  localIntimacyJson = mergedJson;
                } else {
                  perFileErrors.add('$name: force-upload failed: $uploadError');
                }
              }

            case 'weight_data.json':
              var currentLocalJson = localJson;
              final currentRemoteJson = remoteJson;
              var result = mergeWeightData(
                currentLocalJson,
                currentRemoteJson,
                baseJson,
                autoResolve: autoResolve,
              );
              if (!result.hasConflicts) {
                final freshLocalJson = await localFile.readAsString();
                if (freshLocalJson != currentLocalJson) {
                  currentLocalJson = freshLocalJson;
                  result = mergeWeightData(
                    currentLocalJson,
                    currentRemoteJson,
                    baseJson,
                    autoResolve: autoResolve,
                  );
                }
              }
              if (result.hasConflicts) {
                pendingWeight = result;
              } else {
                final mergedData = result.buildResolved(const {});
                final mergedJson = jsonEncode(mergedData.toJson());
                final uploadError = await _uploadMergedJson(
                  config,
                  name,
                  mergedJson,
                  ensureUploadSession: ensureUploadSession,
                  localFile: localFile,
                  baseJson: baseJson,
                  sourceLocalJson: currentLocalJson,
                  remoteJson: currentRemoteJson,
                );
                if (uploadError != null) {
                  perFileErrors.add('$name: force-upload failed: $uploadError');
                }
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
      final imageErrors = await _syncImages(
        config,
        appDir,
        referencedImages,
        ensureUploadSession,
      );

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
      await _releaseUploadSession(config, uploadSession);
      _syncing = false;
    }
  }

  /// Purpose: Finalize sync by applying user's conflict resolutions.
  /// Inputs: `config`, `pending`, `resolutions` mapping record ID → chosen record.
  /// Returns: `Future<bool>` — false when any file's remote read or upload fails.
  /// Side effects: Writes resolved merge results to local files, remote WebDAV files, and base snapshots.
  /// Notes: The mixed-type resolutions map is passed as-is; each merge result
  /// picks out its own record types per conflict ID (never bulk-cast, which
  /// previously crashed on cross-module conflicts). Failed files keep their
  /// base snapshots untouched so the next sync re-merges them.
  static Future<bool> finalizePendingSync(
    WebDAVConfig config,
    PendingSync pending,
    Map<String, dynamic> resolutions,
  ) async {
    _UploadSession? uploadSession;
    try {
      final clientId = await _loadClientId();
      final interrupted = await _prepareInterruptedUpload(config, clientId);
      if (interrupted.error != null) return false;
      final acquired = await _acquireUploadSession(
        config,
        clientId,
        resumeToken: interrupted.resumeToken,
      );
      uploadSession = acquired.session;
      if (uploadSession == null) return false;

      var allOk = true;

      if (pending.todoMerge != null) {
        final mergedData = pending.todoMerge!.buildResolved(resolutions);
        final ok = await _finalizeFile(
          config,
          'todo_data.json',
          jsonEncode(mergedData.toJson()),
          uploadSession,
        );
        allOk = allOk && ok;
      }

      if (pending.financeMerge != null) {
        final mergedData = await _migrateFinanceForcedBalances(
          pending.financeMerge!.buildResolved(resolutions),
        );
        final ok = await _finalizeFile(
          config,
          'finance_data.json',
          jsonEncode(mergedData.toJson()),
          uploadSession,
        );
        allOk = allOk && ok;
      }

      if (pending.intimacyMerge != null) {
        final mergedData = pending.intimacyMerge!.buildResolved(resolutions);
        final ok = await _finalizeFile(
          config,
          'intimacy_data.json',
          jsonEncode(mergedData.toJson()),
          uploadSession,
        );
        allOk = allOk && ok;
      }

      if (pending.weightMerge != null) {
        final mergedData = pending.weightMerge!.buildResolved(resolutions);
        final ok = await _finalizeFile(
          config,
          'weight_data.json',
          jsonEncode(mergedData.toJson()),
          uploadSession,
        );
        allOk = allOk && ok;
      }

      return allOk;
    } catch (_) {
      return false;
    } finally {
      await _releaseUploadSession(config, uploadSession);
    }
  }
}
