import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../features/todo/services/todo_storage.dart';
import 'sync_merge.dart';

/// Persisted WebDAV configuration.
class WebDAVConfig {
  final String serverUrl;
  final String username;
  final String password;
  final String remotePath;
  final bool autoSync;

  const WebDAVConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.remotePath = '/MyDay',
    this.autoSync = false,
  });

  bool get isConfigured =>
      serverUrl.isNotEmpty && username.isNotEmpty && password.isNotEmpty;

  WebDAVConfig copyWith({bool? autoSync}) => WebDAVConfig(
    serverUrl: serverUrl,
    username: username,
    password: password,
    remotePath: remotePath,
    autoSync: autoSync ?? this.autoSync,
  );

  Map<String, dynamic> toJson() => {
    'serverUrl': serverUrl,
    'username': username,
    'password': password,
    'remotePath': remotePath,
    'autoSync': autoSync,
  };

  factory WebDAVConfig.fromJson(Map<String, dynamic> json) => WebDAVConfig(
    serverUrl: json['serverUrl'] as String? ?? '',
    username: json['username'] as String? ?? '',
    password: json['password'] as String? ?? '',
    remotePath: json['remotePath'] as String? ?? '/MyDay',
    autoSync: json['autoSync'] as bool? ?? false,
  );

  /// Nextcloud preset fills server URL pattern.
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

  const SyncResult({required this.success, this.error, this.pending});

  bool get hasConflicts => pending != null;
}

/// Holds pending merge results that contain per-record conflicts.
class PendingSync {
  final TodoMergeResult? todoMerge;
  final FinanceMergeResult? financeMerge;
  final IntimacyMergeResult? intimacyMerge;
  final WeightMergeResult? weightMerge;

  const PendingSync({
    this.todoMerge,
    this.financeMerge,
    this.intimacyMerge,
    this.weightMerge,
  });

  List<RecordConflict> get allConflicts => [
    ...?todoMerge?.dailyConflicts,
    ...?todoMerge?.onceConflicts,
    ...?financeMerge?.accountConflicts,
    ...?financeMerge?.categoryConflicts,
    ...?financeMerge?.transactionConflicts,
    ...?financeMerge?.subscriptionConflicts,
    ...?intimacyMerge?.partnerConflicts,
    ...?intimacyMerge?.toyConflicts,
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
  static bool consumeLocalDataChanged() {
    final v = _localDataChanged;
    _localDataChanged = false;
    return v;
  }

  // ── Config persistence ──

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

  static Future<void> saveConfig(WebDAVConfig config) async {
    final dir = await TodoStorage.getAppDir();
    final file = File('${dir.path}/$_configFileName');
    await file.writeAsString(jsonEncode(config.toJson()));
  }

  static Future<void> deleteConfig() async {
    final dir = await TodoStorage.getAppDir();
    final file = File('${dir.path}/$_configFileName');
    if (await file.exists()) await file.delete();
  }

  // ── Base (last-synced) file management ──

  static Future<Directory> _getBaseDir() async {
    final appDir = await TodoStorage.getAppDir();
    final dir = Directory('${appDir.path}/$_syncBaseDirName');
    if (!await dir.exists()) await dir.create();
    return dir;
  }

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

  static Future<void> _saveBase(String fileName, String jsonContent) async {
    final dir = await _getBaseDir();
    final file = File('${dir.path}/$fileName');
    await _atomicWrite(file, jsonContent);
  }

  // ── Atomic file write ──

  /// Write content to a temp file then atomically rename over the target.
  /// Prevents data corruption if the app is killed during write.
  static Future<void> _atomicWrite(File file, String content) async {
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(content);
    await tmp.rename(file.path);
  }

  // ── Encoding helpers ──

  /// Return raw file content as plain JSON.
  static String _toJson(String raw) {
    return raw;
  }

  /// Return plain JSON for storage.
  static String _toRaw(String json) {
    return json;
  }

  // ── HTTP helpers ──

  static Map<String, String> _authHeaders(WebDAVConfig config) {
    final creds = base64Encode(
      utf8.encode('${config.username}:${config.password}'),
    );
    return {'Authorization': 'Basic $creds'};
  }

  static String _remoteFileUrl(WebDAVConfig config, String fileName) {
    final base = config.serverUrl.endsWith('/')
        ? config.serverUrl.substring(0, config.serverUrl.length - 1)
        : config.serverUrl;
    final path = config.remotePath.endsWith('/')
        ? config.remotePath
        : '${config.remotePath}/';
    return '$base$path$fileName';
  }

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

  static Future<bool> _uploadBytes(
    WebDAVConfig config,
    String fileName,
    Uint8List bytes,
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
            body: bytes,
          )
          .timeout(const Duration(seconds: 60));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

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
        if (href.endsWith('$subPath/') || href.endsWith('$subPath')) continue;
        final fileName = href.split('/').where((s) => s.isNotEmpty).last;
        if (fileName.isNotEmpty) names.add(fileName);
      }
      return names;
    } catch (_) {
      return {};
    }
  }

  static Future<Uint8List?> _downloadBytes(
    WebDAVConfig config,
    String fileName,
  ) async {
    try {
      final url = Uri.parse(_remoteFileUrl(config, fileName));
      final response = await http
          .get(url, headers: _authHeaders(config))
          .timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) return response.bodyBytes;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _syncImages(WebDAVConfig config, Directory appDir) async {
    final imgDir = Directory(p.join(appDir.path, 'images'));

    await _ensureRemoteSubDir(config, 'images');

    // Collect local image names
    final localNames = <String>{};
    if (await imgDir.exists()) {
      await for (final entity in imgDir.list()) {
        if (entity is File) {
          localNames.add(p.basename(entity.path));
        }
      }
    }

    // List remote images
    final remoteNames = await _listRemoteDir(config, 'images');

    // Download remote images not present locally
    if (!await imgDir.exists()) await imgDir.create(recursive: true);
    for (final name in remoteNames) {
      if (!localNames.contains(name)) {
        final bytes = await _downloadBytes(config, 'images/$name');
        if (bytes != null) {
          await File(p.join(imgDir.path, name)).writeAsBytes(bytes);
        }
      }
    }

    // Upload local images not present on remote
    for (final name in localNames) {
      if (!remoteNames.contains(name)) {
        final bytes = await File(p.join(imgDir.path, name)).readAsBytes();
        await _uploadBytes(config, 'images/$name', bytes);
      }
    }
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
          continue;
        }

        final localRaw = await localFile.readAsString();

        if (localExists && remoteRaw == null) {
          // Only on local → upload
          final uploaded = await _upload(config, name, localRaw);
          if (uploaded) await _saveBase(name, _toJson(localRaw));
          continue;
        }

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
            final mergedJson = mergeExchangeRateJson(localJson, remoteJson);
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
                final mergedJson = jsonEncode(mergedData.toJson());
                final mergedRaw = _toRaw(mergedJson);
                await _atomicWrite(localFile, mergedRaw);
                final uploaded = await _upload(config, name, mergedRaw);
                if (uploaded) await _saveBase(name, mergedJson);
                _localDataChanged = true;
              }

            case 'finance_data.json':
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
                final mergedData = result.buildResolved({});
                final mergedJson = jsonEncode(mergedData.toJson());
                final mergedRaw = _toRaw(mergedJson);
                await _atomicWrite(localFile, mergedRaw);
                final uploaded = await _upload(config, name, mergedRaw);
                if (uploaded) await _saveBase(name, mergedJson);
                _localDataChanged = true;
              }

            case 'intimacy_data.json':
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
                final mergedJson = jsonEncode(mergedData.toJson());
                final mergedRaw = _toRaw(mergedJson);
                await _atomicWrite(localFile, mergedRaw);
                final uploaded = await _upload(config, name, mergedRaw);
                if (uploaded) await _saveBase(name, mergedJson);
                _localDataChanged = true;
              }

            case 'weight_data.json':
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
                final mergedJson = jsonEncode(mergedData.toJson());
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

      // Sync images (additive, no conflict)
      await _syncImages(config, appDir);

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
        );
      }

      return SyncResult(
        success: perFileErrors.isEmpty,
        error: perFileErrors.isNotEmpty ? perFileErrors.join('; ') : null,
      );
    } catch (e) {
      return SyncResult(success: false, error: e.toString());
    } finally {
      _syncing = false;
    }
  }

  /// Finalize sync by applying user's conflict resolutions.
  ///
  /// [resolutions] maps record ID → the chosen record object (local or remote).
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
        final mergedJson = jsonEncode(mergedData.toJson());
        final mergedRaw = _toRaw(mergedJson);
        await _atomicWrite(File('${appDir.path}/todo_data.json'), mergedRaw);
        final uploaded = await _upload(config, 'todo_data.json', mergedRaw);
        if (uploaded) await _saveBase('todo_data.json', mergedJson);
      }

      if (pending.financeMerge != null) {
        final mergedData = pending.financeMerge!.buildResolved(resolutions);
        final mergedJson = jsonEncode(mergedData.toJson());
        final mergedRaw = _toRaw(mergedJson);
        await _atomicWrite(File('${appDir.path}/finance_data.json'), mergedRaw);
        final uploaded = await _upload(config, 'finance_data.json', mergedRaw);
        if (uploaded) await _saveBase('finance_data.json', mergedJson);
      }

      if (pending.intimacyMerge != null) {
        final mergedData = pending.intimacyMerge!.buildResolved(resolutions);
        final mergedJson = jsonEncode(mergedData.toJson());
        final mergedRaw = _toRaw(mergedJson);
        await _atomicWrite(
          File('${appDir.path}/intimacy_data.json'),
          mergedRaw,
        );
        final uploaded = await _upload(config, 'intimacy_data.json', mergedRaw);
        if (uploaded) await _saveBase('intimacy_data.json', mergedJson);
      }

      if (pending.weightMerge != null) {
        final mergedData = pending.weightMerge!.buildResolved(resolutions);
        final mergedJson = jsonEncode(mergedData.toJson());
        final mergedRaw = _toRaw(mergedJson);
        await _atomicWrite(File('${appDir.path}/weight_data.json'), mergedRaw);
        final uploaded = await _upload(config, 'weight_data.json', mergedRaw);
        if (uploaded) await _saveBase('weight_data.json', mergedJson);
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}
